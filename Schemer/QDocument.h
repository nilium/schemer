//
//  QDocument.h
//  Schemer
//
//  Created by Noel Cower on 01/26/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class QScheme;
@class QRulesTableDelegate;

@interface QDocument : NSDocument <NSTokenFieldDelegate>

@property (strong, readonly) QScheme *scheme;
@property (strong, readonly) QRulesTableDelegate *rulesTableDelegate;

@end
