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

/* QSchemeRule.m - Noel Cower */

#import "QSchemeRule.h"
#import "NSFilters.h"
#import "NSColor+QHexColor.h"
#import "aux.h"


static
uint32_t
schemeFlagsForString(NSString *string)
{
  uint32_t result = QNoFlags;
  if (string != nil && [string length] > 0) {
    NSRange range;

    range = [string rangeOfString:@"bold"];
    if (range.location != NSNotFound && range.length != 0) {
      result |= QBoldFlag;
    }

    range = [string rangeOfString:@"italic"];
    if (range.location != NSNotFound && range.length != 0) {
      result |= QItalicFlag;
    }

    range = [string rangeOfString:@"underline"];
    if (range.location != NSNotFound && range.length != 0) {
      result |= QUnderlineFlag;
    }
  }
  return result;
}


static
NSString *
schemeFlagStringForFlags(uint32_t flags)
{
  NSMutableArray *flagNames = [NSMutableArray arrayWithCapacity:3];

  if (flags & QBoldFlag) {
    [flagNames addObject:@"bold"];
  }


  if (flags & QItalicFlag) {
    [flagNames addObject:@"italic"];
  }


  if (flags & QUnderlineFlag) {
    [flagNames addObject:@"underline"];
  }

  return [flagNames componentsJoinedByString:@" "];
}


@implementation QSchemeRule

- (id)init {
  if ((self = [super init])) {
    self.name       = @"Unnamed Rule";
    self.selectors  = @[];
    self.foreground = [NSColor colorWithWhite:0.0f alpha:0.0f];
    self.background = [NSColor colorWithWhite:1.0f alpha:0.0f];
    self.flags      = @(QNoFlags);
  }
  return self;
}


- (id)initWithRule:(QSchemeRule *)rule
{
  if ((self = [self init]) && rule) {
    self.name       = rule.name;
    self.selectors  = rule.selectors;
    self.foreground = rule.foreground;
    self.background = rule.background;
    self.flags      = rule.flags;
  }
  return self;
}


- (id)copyWithZone:(NSZone *)zone
{
  return [[self.class alloc] initWithRule:self];
}


- (id)initWithPropertyList:(NSDictionary *)plist
{
  if ((self = [self init])) {
    self.name = plist[@"name"];
    NSString *scope = (NSString *)plist[@"scope"];
    NSCharacterSet *charset = NSCharacterSet.whitespaceAndNewlineCharacterSet;

    if (scope) {
      self.selectors =
        [[[scope componentsSeparatedByString:@","]
          mappedTo:^id(id obj) {
            return [obj stringByTrimmingCharactersInSet:charset];
          }] selectedBy:^BOOL(id obj) {
            return [obj length] > 0;
          }];
    }

    NSDictionary *settings = plist[@"settings"];

    if (settings) {
      self.foreground = colorSetting(settings, @"foreground", self.foreground);
      self.background = colorSetting(settings, @"background", self.background);
      self.flags      = @(schemeFlagsForString(settings[@"fontStyle"]));
    }
  }
  return self;
}


- (NSDictionary *)toPropertyList
{
  NSMutableDictionary *plist = [NSMutableDictionary new];
  plist[@"name"]  = self.name;
  plist[@"scope"] = [self.selectors componentsJoinedByString:@", "];

  NSMutableDictionary *settings = [NSMutableDictionary new];
  putColorIfVisible(settings, @"foreground", self.foreground);
  putColorIfVisible(settings, @"background", self.background);

  if (self.flags.unsignedIntValue != QNoFlags) {
    uint32_t flagsMask = self.flags.unsignedIntValue;
    settings[@"fontStyle"] = schemeFlagStringForFlags(flagsMask);
  }

  plist[@"settings"] = settings;

  return plist;
}

@end
