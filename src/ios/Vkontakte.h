//
//  Vkontakte.h

#import <Cordova/CDV.h>
#import <VKSdk/VKSdk.h>

@interface Vkontakte : CDVPlugin <VKSdkDelegate>
{
    NSString*     clientId;
}

@property (nonatomic, retain) NSString*     clientId;

- (void)initWithApp:(CDVInvokedUrlCommand*)command;
- (void)login:(CDVInvokedUrlCommand*)command;

@end
