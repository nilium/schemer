//
//  QRulesTableData.h
//  Schemer
//
//  Created by Noel Cower on 01/27/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QScheme;

@interface QRulesTableData : NSObject <NSTableViewDataSource>

- (id)initWithScheme:(QScheme *)scheme;

@end
