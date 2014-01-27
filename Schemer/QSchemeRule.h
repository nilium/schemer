//
//  QSchemeRule.h
//  Schemer
//
//  Created by Noel Cower on 01/26/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(uint32_t, QSchemeRuleFlags) {
  QNoFlags = 0,
  QBoldFlag = 1,
  QItalicFlag = 2,
  QUnderlineFlag = 4
};

@interface QSchemeRule : NSObject <NSCopying>

@property (copy) NSString *name;
@property (copy) NSArray *selectors; // <NSString>
@property (copy) NSColor *foreground;
@property (copy) NSColor *background;
@property NSNumber *flags;

- (id)initWithDocument:(NSDocument *)document;
- (id)initWithPropertyList:(NSDictionary *)plist document:(NSDocument *)document;

- (NSDictionary *)toPropertyList;

@end
