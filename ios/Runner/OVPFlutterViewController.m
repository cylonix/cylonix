//
//  OVPFlutterViewController.m
//  Runner
//
//  Created by Sinan Yasargil on 16.11.21.
//

#import "OVPFlutterViewController.h"

@interface OVPFlutterViewController ()

@end

@implementation OVPFlutterViewController


//https://github.com/flutter/flutter/issues/14720
- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    //NSLog(@"OVPFlutterViewController: touchesBegan %@ --- %d",event, self.presentedViewController != nil);
    if (self.presentedViewController != nil) {
        return;
    }
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    //NSLog(@"OVPFlutterViewController: touchesMoved %@ --- %d",event, self.presentedViewController != nil);
    if (self.presentedViewController != nil) {
        return;
    }
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    //NSLog(@"OVPFlutterViewController: touchesEnded %@ --- %d",event, self.presentedViewController != nil);
    if (self.presentedViewController != nil) {
        return;
    }
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
    //NSLog(@"OVPFlutterViewController: touchesCancelled %@ --- %d",event, self.presentedViewController != nil);
    if (self.presentedViewController != nil) {
        return;
    }
    [super touchesCancelled:touches withEvent:event];
}

@end
