//
//  QSchemeRule.m
//  Schemer
//
//  Created by Noel Cower on 01/26/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

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
    NSCharacterSet *charset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    self.selectors =
    [[[scope componentsSeparatedByString:@","] mappedArrayUsingBlock:^id(id obj) {
      return [obj stringByTrimmingCharactersInSet:charset];
    }] selectedArrayUsingBlock:^BOOL(id obj) {
      return [obj length] > 0;
    }];

    NSDictionary *settings = plist[@"settings"];
    self.foreground = colorSetting(settings, @"foreground", self.foreground);
    self.background = colorSetting(settings, @"background", self.background);
    self.flags = @(schemeFlagsForString(settings[@"fontStyle"]));
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
    settings[@"fontStyle"] = schemeFlagStringForFlags(self.flags.unsignedIntValue);
  }

  plist[@"settings"] = settings;

  return plist;
}

@end
