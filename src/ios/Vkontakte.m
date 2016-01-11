//
//  Vkontakte.m

#import "Vkontakte.h"
#import <VKSdk/VKBundle.h>
#import "NSData+Base64.h"

@implementation Vkontakte {
    void (^vkLoginCallback)(VKAccessToken *, NSString *);
    BOOL inited;
}

@synthesize clientId;


#pragma mark - Exported Cordova Functions

-(void) initWithApp:(CDVInvokedUrlCommand*)command
{
    if (!inited) {
        NSString *appId = [[NSString alloc] initWithString: [command.arguments objectAtIndex:0]];
        [VKSdk initializeWithDelegate:self andAppId:appId];
        if(![VKSdk wakeUpSession]) {
            NSLog(@"VK init error!");
        }
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
        [self returnToken:token forCommand:command];
    } else {
        [self doLogin: permissions
             andBlock: ^(VKAccessToken *token, NSString *error) {
                 if (token) {
                     NSLog(@"Loged in to VKontakte");
                     [self returnToken:token forCommand:command];
                 } else {
                     NSLog(@"Can't login to VKontakte");
                     [self returnError:error forCommand:command];
                 }
             }
         ];
    }
}


#pragma mark - Internal

-(void)returnError:(NSString *)errorMsg forCommand:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult* pluginResult = [CDVPluginResult
                                     resultWithStatus: CDVCommandStatus_ERROR
                                     messageAsString: errorMsg
                                     ];
    [self.commandDelegate sendPluginResult: pluginResult callbackId: command.callbackId];
}

-(void)returnToken:(VKAccessToken *)token forCommand:(CDVInvokedUrlCommand *)command
{
    NSMutableDictionary *loginDetails = [NSMutableDictionary new];
    loginDetails[@"accessToken"] = token.accessToken;
    loginDetails[@"expiresIn"] = token.expiresIn;

    CDVPluginResult* pluginResult = [CDVPluginResult
                                     resultWithStatus: CDVCommandStatus_OK
                                     messageAsDictionary: loginDetails
                                     ];
    [self.commandDelegate
     sendPluginResult: pluginResult
     callbackId: command.callbackId
     ];
}

-(void)doLogin:(NSArray*)permissions andBlock:(void (^)(VKAccessToken *, NSString *))callback
{
    vkLoginCallback = [callback copy];

    if (!permissions || permissions.count < 1) {
        permissions = @[VK_PER_WALL, VK_PER_OFFLINE];
    }

    [VKSdk
     authorize: permissions
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


#pragma mark - VKSdkDelegate

-(void) vkSdkReceivedNewToken:(VKAccessToken*) newToken
{
    NSLog(@"VK Token %@", newToken.accessToken);
    if (vkLoginCallback) {
        vkLoginCallback(newToken, nil);
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
