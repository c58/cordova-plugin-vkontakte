//
//  Vkontakte.m

#import "Vkontakte.h"
#import <VKSdk/VKBundle.h>
#import "NSData+Base64.h"

@implementation Vkontakte {
  void (^vkLoginCallback)(NSString *, NSString *);
  BOOL inited;
}

@synthesize clientId;


#pragma mark - Exported Cordova Functions

- (void) initWithApp:(CDVInvokedUrlCommand*)command
{
  if (!inited) {
    NSString *appId = [[NSString alloc] initWithString: [command.arguments objectAtIndex:0]];
    [VKSdk initializeWithDelegate:self andAppId: appId];
    [[NSNotificationCenter defaultCenter]
      addObserver: self
      selector: @selector(myOpenUrl:)
      name: CDVPluginHandleOpenURLNotification object:nil
    ];
    inited = YES;
  }

  CDVPluginResult* pluginResult = [CDVPluginResult
    resultWithStatus: CDVCommandStatus_OK
  ];
  [self.commandDelegate
    sendPluginResult: pluginResult
    callbackId: command.callbackId
  ];
}

-(void) login:(CDVInvokedUrlCommand *)command
{
  NSArray *permissions = [command.arguments objectAtIndex:0];

  if ([VKSdk isLoggedIn]) {
    NSLog(@"Reuse existing VKontakte token");
    VKAccessToken *token = [VKSdk getAccessToken];

    CDVPluginResult* pluginResult = [CDVPluginResult
      resultWithStatus: CDVCommandStatus_OK
      messageAsString: token.accessToken
    ];
    [self.commandDelegate sendPluginResult: pluginResult
      callbackId: command.callbackId
    ];
  } else {
    [self vkLoginWithPermissions: permissions
      andBlock: ^(NSString *token, NSString *error) {
        if (token) {
          NSLog(@"Loged in to VKontakte");

          CDVPluginResult* pluginResult = [CDVPluginResult
            resultWithStatus: CDVCommandStatus_OK
            messageAsString: token
          ];
          [self.commandDelegate
            sendPluginResult: pluginResult
            callbackId: command.callbackId
          ];
        } else {
          NSLog(@"Can't login to VKontakte");

          CDVPluginResult* pluginResult = [CDVPluginResult
            resultWithStatus: CDVCommandStatus_ERROR
            messageAsString: error
          ];
          [self.commandDelegate
            sendPluginResult: pluginResult
            callbackId: command.callbackId
          ];
        }
      }
    ];
  }
}


#pragma mark - Internal

-(void)vkLoginWithPermissions:(NSArray*)permissions andBlock:(void (^)(NSString *, NSString *))callback
{
    vkLoginCallback = [callback copy];

    if (!permissions || permissions.count < 1) {
      permissions = @[VK_PER_WALL, VK_PER_OFFLINE];
    }

    [VKSdk authorize: permissions
      revokeAccess: NO
      forceOAuth: YES
      inApp: YES
      display: VK_DISPLAY_IOS
    ];
}

-(UIViewController*)findViewController
{
  id vc = self.webView;
  do {
    vc = [vc nextResponder];
  } while ([vc isKindOfClass:UIView.class]);
  return vc;
}

-(void)myOpenUrl:(NSNotification*)notification
{
  NSURL *url = notification.object;
  if ([url isKindOfClass:NSURL.class]) {
    BOOL wasHandled = [VKSdk processOpenURL:url fromApplication:nil];
  }
}


#pragma mark - VKSdkDelegate

-(void) vkSdkReceivedNewToken:(VKAccessToken*) newToken
{
    NSLog(@"VK Token %@", newToken.accessToken);
    if (vkLoginCallback) {
        vkLoginCallback(newToken.accessToken, nil);
    }
}

- (void)vkSdkAcceptedUserToken:(VKAccessToken *)token
{
    NSLog(@"VK Token %@", token.accessToken);
}

- (void)vkSdkRenewedToken:(VKAccessToken *)newToken
{
    NSLog(@"VK Token %@", newToken.accessToken);
}

-(void) vkSdkUserDeniedAccess:(VKError*) authorizationError
{
    NSLog(@"VK Error %@", authorizationError);
    if (vkLoginCallback) {
        vkLoginCallback(nil, authorizationError.description);
    }
}

-(void) vkSdkShouldPresentViewController:(UIViewController *)controller
{
    [[self findViewController]
        presentViewController: controller
        animated: YES
        completion: nil
    ];
}

-(void) vkSdkTokenHasExpired:(VKAccessToken *)expiredToken
{

}

-(void) vkSdkNeedCaptchaEnter:(VKError *)captchaError
{
    NSLog(@"Need captcha %@", captchaError);
}

-(BOOL)vkSdkAuthorizationAllowFallbackToSafari
{
    return NO;
}

-(BOOL)vkSdkIsBasicAuthorization
{
    return YES;
}

@end
