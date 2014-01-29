//
//  NSColor+QHexColor.m
//  Schemer
//
//  Created by Noel Cower on 01/26/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import "NSColor+QHexColor.h"
#import "aux.h"


#define Q_UBFMT "%0.2hhx"


static
uint8_t
q_ftoub(CGFloat f)
{
  uint32_t ui = (uint32_t)(f * 255.0);
  return (ui > 255 ? 255 : ui) & 0xFF;
}


@implementation NSColor (QHexColor)

- (NSColor *)forScheme
{
  return [self colorUsingColorSpaceName:NSDeviceRGBColorSpace];
}

+ (NSColor *)colorFromHexString:(NSString *)hex
{
  NSScanner *scanner = [NSScanner scannerWithString:hex];

  unsigned int color = 0;
  if (!([scanner scanString:@"#" intoString:NULL] && [scanner scanHexInt:&color])) {
    NSLog(@"Invalid color read from string %@, returning opaque white", hex);
    return [NSColor colorWithWhite:1.0 alpha:1.0];
  }

  float alpha = 1.0f;

  if ([hex length] > 7) {
    alpha = ((float)(color & 0xFF)) / 255.0f;
    color = color >> 8;
  }

  CGFloat red = ((float)((color >> 16) & 0xFF)) / 255.0;
  CGFloat green = ((float)((color >> 8) & 0xFF)) / 255.0;
  CGFloat blue = ((float)(color & 0xFF)) / 255.0;

  return [NSColor colorWithRed:red green:green blue:blue alpha:alpha];
}


- (NSString *)toHexColorString
{
  NSColor *valid = [self forScheme];

  CGFloat red = 0.0f;
  CGFloat green = 0.0f;
  CGFloat blue = 0.0f;
  CGFloat alpha = 0.0f;

  [valid getRed:&red green:&green blue:&blue alpha:&alpha];

  if (alpha < ONE_EPSILON) {
    return [NSString stringWithFormat:@"#" Q_UBFMT Q_UBFMT Q_UBFMT Q_UBFMT,
            q_ftoub(red),
            q_ftoub(green),
            q_ftoub(blue),
            q_ftoub(alpha)
            ];
  } else {
    // Skip alpha if it's essentially 0xFF
    return [NSString stringWithFormat:@"#" Q_UBFMT Q_UBFMT Q_UBFMT,
            q_ftoub(red),
            q_ftoub(green),
            q_ftoub(blue)
            ];
  }

  return nil;
}

@end
