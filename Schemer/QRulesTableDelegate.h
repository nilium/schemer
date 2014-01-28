//
//  QRulesTableDelegate.h
//  Schemer
//
//  Created by Noel Cower on 01/27/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class QScheme;
@class QSchemeRule;


extern NSString *const QRuleSelectedNotification; /* { 'rule' => QSchemeRule } */
extern NSString *const QSelectedRules;


@interface QRulesTableDelegate : NSObject <NSTableViewDelegate, NSTextFieldDelegate>

@property (readonly, weak) QSchemeRule *selectedRule;

- (id)initWithScheme:(QScheme *)scheme tableView:(NSTableView *)view;
- (void)doubleClickedTableView:(NSTableView *)tableView;
- (void)clickedTableView:(NSTableView *)tableView;
- (void)updateSelectedRuleSelectors:(NSArray *)selectors;

@end
