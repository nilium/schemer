/*===========================================================================
  Copyright (c) 2014, Noel Cower.
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
===========================================================================*/

/* NSColor+QHexColor.m - Noel Cower */

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
  if (!(   [scanner scanString:@"#" intoString:NULL]
        && [scanner scanHexInt:&color])) {
    NSLog(@"Invalid color read from string %@, returning opaque white", hex);
    return [NSColor colorWithWhite:1.0 alpha:1.0];
  }

  CGFloat alpha = 1.0f;

  if ([hex length] > 7) {
    alpha = ((CGFloat)(color & 0xFF)) / 255.0;
    color = color >> 8;
  }

  CGFloat red = ((CGFloat)((color >> 16) & 0xFF)) / 255.0;
  CGFloat green = ((CGFloat)((color >> 8) & 0xFF)) / 255.0;
  CGFloat blue = ((CGFloat)(color & 0xFF)) / 255.0;

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
