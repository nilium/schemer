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

/* aux.m - Noel Cower */

#import <Cocoa/Cocoa.h>

#import "aux.h"
#import "NSColor+QHexColor.h"


BOOL
colorIsDefined(NSColor *color)
{
  return color.alphaComponent > ZERO_EPSILON;
}


NSColor *
blendColors(NSColor *bottom, NSColor *top)
{
  bottom = [bottom forScheme];
  top = [top forScheme];

  CGFloat lr, lg, lb;
  CGFloat rr, rg, rb, a, ia;
  lr = lg = lb = rr = rg = rb = a = 0.0;

  [bottom getRed:&lr green:&lg blue:&lb alpha:&a];
  [top getRed:&rr green:&rg blue:&rb alpha:&a];

  ia = 1.0 - a;

  lr = lr * ia + rr * a;
  lg = lg * ia + rg * a;
  lb = lb * ia + rb * a;

  return [NSColor colorWithRed:lr green:lg blue:lb alpha:1.0];
}


NSColor *
colorSetting(NSDictionary *info, NSString *key, NSColor *defaultColor)
{
  id colorString = info[key];
  if (colorString && [colorString isKindOfClass:[NSString class]]) {
    NSColor *color = [NSColor colorFromHexString:colorString];
    if (color) {
      return color;
    }
  }
  return defaultColor;
}


void
putColorIfVisible(NSMutableDictionary *plist, NSString *key, NSColor *color)
{
  if (color.alphaComponent > ZERO_EPSILON) {
    plist[key] = [color toHexColorString];
  }
}
