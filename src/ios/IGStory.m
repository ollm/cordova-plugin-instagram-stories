#import "IGStory.h"

@implementation IGStory

@synthesize callbackId;

- (void)pluginInitialize {
}

- (void)shareToStory:(CDVInvokedUrlCommand *)command {
  self.callbackId = command.callbackId;

  NSString *appID = [command.arguments objectAtIndex:0];
  NSString *backgroundImage = [command.arguments objectAtIndex:1];
  NSString *stickerImage = [command.arguments objectAtIndex:2];
  NSString *attributionURL = [command.arguments objectAtIndex:3];
  NSString *backgroundTopColor = [command.arguments objectAtIndex:4];
  NSString *backgroundBottomColor = [command.arguments objectAtIndex:5];

  NSLog(@"This is backgroundURL: %@", backgroundImage);
  NSLog(@"This is stickerURL: %@", stickerImage);

  if ([backgroundTopColor length] != 0 && [backgroundBottomColor length] != 0) {
    NSURL *stickerImageURL = [NSURL URLWithString:stickerImage];

    NSError *stickerImageError;
    NSData *stickerData = [NSData dataWithContentsOfURL:stickerImageURL
                                                options:NSDataReadingUncached
                                                  error:&stickerImageError];

    if (stickerData && !stickerImageError) {
      [self shareColorAndStickerImage:appID
                   backgroundTopColor:backgroundTopColor
                backgroundBottomColor:backgroundBottomColor
                         stickerImage:stickerData
                       attributionURL:attributionURL
                            commandId:command.callbackId];
    } else {
      CDVPluginResult *result =
          [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                            messageAsString:@"Missing Sticker background"];
      dispatch_async(dispatch_get_main_queue(), ^{
        [self finishCommandWithResult:result commandId:command.callbackId];
      });
    }

  } else {
    NSURL *stickerImageURL = [NSURL URLWithString:stickerImage];
    NSURL *backgroundImageURL = [NSURL URLWithString:backgroundImage];

    NSError *backgroundImageError;
    NSData *imageDataBackground =
        [NSData dataWithContentsOfURL:backgroundImageURL
                              options:NSDataReadingUncached
                                error:&backgroundImageError];

    if (imageDataBackground && !backgroundImageError) {
      NSError *stickerImageError;
      NSData *stickerData = [NSData dataWithContentsOfURL:stickerImageURL
                                                  options:NSDataReadingUncached
                                                    error:&stickerImageError];

      if (stickerData && !stickerImageError) {
        [self shareBackgroundAndStickerImage:appID
                             backgroundImage:imageDataBackground
                                stickerImage:stickerData
                              attributionURL:attributionURL
                                   commandId:command.callbackId];
      } else {
        CDVPluginResult *result =
            [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                              messageAsString:@"Missing Sticker background"];
        dispatch_async(dispatch_get_main_queue(), ^{
          [self finishCommandWithResult:result commandId:command.callbackId];
        });
      }
    } else {
      CDVPluginResult *result =
          [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                            messageAsString:@"Missing Image background"];
      dispatch_async(dispatch_get_main_queue(), ^{
        [self finishCommandWithResult:result commandId:command.callbackId];
      });
    }
  }
}

- (void)shareImageToStory:(CDVInvokedUrlCommand *)command {

  self.callbackId = command.callbackId;

  NSString *appID = [command.arguments objectAtIndex:0];
  NSString *backgroundImage = [command.arguments objectAtIndex:1];

  NSData *imageData = [self getImageData:backgroundImage];
  if (!imageData) {
    CDVPluginResult *result =
        [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                          messageAsString:@"Missing Image background"];
    dispatch_async(dispatch_get_main_queue(), ^{
      [self finishCommandWithResult:result commandId:command.callbackId];
    });
    return;
  }

  [self shareBackgroundAndStickerImage:appID
                       backgroundImage:imageData
                          stickerImage:nil
                        attributionURL:nil
                             commandId:command.callbackId];
}

- (void)shareBackgroundAndStickerImage:(NSString *)appID
                       backgroundImage:(NSData *)backgroundImage
                          stickerImage:(NSData *)stickerImage
                        attributionURL:(NSString *)attributionURL
                             commandId:(NSString *)command {

  // Verify app can open custom URL scheme. If able,
  // assign assets to pasteboard, open scheme.
  NSURL *urlScheme = [NSURL URLWithString:[NSString stringWithFormat:@"instagram-stories://share?source_application=%@", appID]];
  if ([[UIApplication sharedApplication] canOpenURL:urlScheme]) {

    NSLog(@"IG IS AVAIALBLE");

    // Assign background and sticker image assets and
    // attribution link URL to pasteboard
    NSMutableDictionary *pasteboardItemsDictionary =
        [@{@"com.instagram.sharedSticker.backgroundImage" : backgroundImage}
            mutableCopy];
    pasteboardItemsDictionary
        [@"com.instagram.sharedSticker.sourceApplication"] = appID;
    if (stickerImage) {
      pasteboardItemsDictionary[@"com.instagram.sharedSticker.stickerImage"] =
          stickerImage;
    }
    if (attributionURL) {
      pasteboardItemsDictionary[@"com.instagram.sharedSticker.contentURL"] =
          attributionURL;
    }

    NSArray *pasteboardItems = @[ pasteboardItemsDictionary ];
    NSDictionary *pasteboardOptions = @{
      UIPasteboardOptionExpirationDate :
          [[NSDate date] dateByAddingTimeInterval:60 * 5]
    };
    // This call is iOS 10+, can use 'setItems' depending on what versions you
    // support
    [[UIPasteboard generalPasteboard] setItems:pasteboardItems
                                       options:pasteboardOptions];

    [[UIApplication sharedApplication] openURL:urlScheme
                                       options:@{}
                             completionHandler:nil];

    NSDictionary *payload =
        [NSDictionary dictionaryWithObjectsAndKeys:attributionURL, @"url", nil];
    CDVPluginResult *result =
        [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                      messageAsDictionary:payload];

    dispatch_async(dispatch_get_main_queue(), ^{
      [self finishCommandWithResult:result commandId:command];
    });

  } else {
    // Handle older app versions or app not installed case

    NSLog(@"IG IS NOT AVAILABLE");

    CDVPluginResult *result =
        [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                          messageAsString:@"Not installed"];

    dispatch_async(dispatch_get_main_queue(), ^{
      [self finishCommandWithResult:result commandId:command];
    });
  }
}

- (void)shareColorAndStickerImage:(NSString *)appID
               backgroundTopColor:(NSString *)backgroundTopColor
            backgroundBottomColor:(NSString *)backgroundBottomColor
                     stickerImage:(NSData *)stickerImage
                   attributionURL:(NSString *)attributionURL
                        commandId:(NSString *)command {

  // Verify app can open custom URL scheme. If able,
  // assign assets to pasteboard, open scheme.
  NSURL *urlScheme = [NSURL URLWithString:[NSString stringWithFormat:@"instagram-stories://share?source_application=%@", appID]];
  if ([[UIApplication sharedApplication] canOpenURL:urlScheme]) {

    NSLog(@"IG IS AVAIALBLE");

    // Assign background and sticker image assets and
    // attribution link URL to pasteboard
    NSArray *pasteboardItems = @[ @{
      @"com.instagram.sharedSticker.sourceApplication" : appID,
      @"com.instagram.sharedSticker.stickerImage" : stickerImage,
      @"com.instagram.sharedSticker.backgroundTopColor" : backgroundTopColor,
      @"com.instagram.sharedSticker.backgroundBottomColor" :
          backgroundBottomColor,
      @"com.instagram.sharedSticker.contentURL" : attributionURL
    } ];

    NSDictionary *pasteboardOptions = @{
      UIPasteboardOptionExpirationDate :
          [[NSDate date] dateByAddingTimeInterval:60 * 5]
    };
    // This call is iOS 10+, can use 'setItems' depending on what versions you
    // support
    [[UIPasteboard generalPasteboard] setItems:pasteboardItems
                                       options:pasteboardOptions];

    [[UIApplication sharedApplication] openURL:urlScheme
                                       options:@{}
                             completionHandler:nil];

    NSDictionary *payload =
        [NSDictionary dictionaryWithObjectsAndKeys:attributionURL, @"url", nil];
    CDVPluginResult *result =
        [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                      messageAsDictionary:payload];

    dispatch_async(dispatch_get_main_queue(), ^{
      [self finishCommandWithResult:result commandId:command];
    });
  } else {
    // Handle older app versions or app not installed case

    NSLog(@"IG IS NOT AVAILABLE");

    CDVPluginResult *result =
        [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                          messageAsString:@"Not installed"];

    dispatch_async(dispatch_get_main_queue(), ^{
      [self finishCommandWithResult:result commandId:command];
    });
  }
}

// Pulled from https://github.com/EddyVerbruggen/SocialSharing-PhoneGap-Plugin
// and slightly modified
- (NSData *)getImageData:(NSString *)imageName {
  NSData *imageData = nil;
  if (imageName != (id)[NSNull null]) {
    if ([imageName hasPrefix:@"http"]) {
      imageData =
          [NSData dataWithContentsOfURL:[NSURL URLWithString:imageName]];
    } else if ([imageName hasPrefix:@"file://"]) {
      imageData = [NSData
          dataWithContentsOfFile:[[NSURL URLWithString:imageName] path]];
    } else if ([imageName hasPrefix:@"data:"]) {
      // using a base64 encoded string
      NSURL *imageURL = [NSURL URLWithString:imageName];
      imageData = [NSData dataWithContentsOfURL:imageURL];
    } else if ([imageName hasPrefix:@"assets-library://"]) {
      // use assets-library
      NSURL *imageURL = [NSURL URLWithString:imageName];
      imageData = [NSData dataWithContentsOfURL:imageURL];
    } else {
      // assume anywhere else, on the local filesystem
      imageData = [NSData dataWithContentsOfFile:imageName];
    }
  }
  return imageData;
}

- (void)finishCommandWithResult:(CDVPluginResult *)result
                      commandId:(NSString *)command {
  NSLog(@"This is callbackurl: %@", command);
  if (command != nil) {
    [self.commandDelegate sendPluginResult:result callbackId:command];
  }
}

@end
