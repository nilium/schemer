//
//  aux.m
//  Schemer
//
//  Created by Noel Cower on 01/26/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

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
