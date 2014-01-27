//
//  QFlexTokenField.m
//  Schemer
//
//  Created by Noel Cower on 01/27/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import "QFlexTokenField.h"

@implementation QFlexTokenField

- (NSSize)intrinsicContentSize
{
  NSCell *cell = self.cell;
  if (!cell.wraps) {
    return [super intrinsicContentSize];
  }

  NSRect frame = self.frame;
  frame.size.height = CGFLOAT_MAX;
  frame.size.height = [cell cellSizeForBounds:frame].height;

  return frame.size;
}

@end
