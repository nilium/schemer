//
//  QStringArraySource.h
//  Schemer
//
//  Created by Noel Cower on 01/27/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import <Foundation/Foundation.h>


@class QSchemeRule;


@interface QSelectorTableSource : NSObject <NSTableViewDataSource>

@property (weak, readwrite) QSchemeRule *rule;

@end
