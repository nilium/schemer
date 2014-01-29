//
//  NSColor+QHexColor.h
//  Schemer
//
//  Created by Noel Cower on 01/26/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSColor (QHexColor)

+ (NSColor *)colorFromHexString:(NSString *)hex;
- (NSString *)toHexColorString;
- (NSColor *)forScheme;

@end
