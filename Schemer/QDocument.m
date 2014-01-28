//
//  QDocument.m
//  Schemer
//
//  Created by Noel Cower on 01/26/14.
//  Copyright (c) 2014 Spifftastic. All rights reserved.
//

#import "QDocument.h"
#import "QScheme.h"
#import "QSchemeRule.h"
#import "QRulesTableData.h"
#import "QRulesTableDelegate.h"
#import "NSFilters.h"
#import "NSObject+QNull.h"
#import "QSelectorTableSource.h"


static
NSArray *
cleanedRuleSelectorArray(NSString *selectors)
{
  static NSCharacterSet *trimset = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    trimset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  });

  return
    [[selectors componentsSeparatedByString:@","]
     mappedArrayUsingBlock:^(id obj) { return [obj stringByTrimmingCharactersInSet:trimset]; }];
}


static
NSArray *
observedSchemePaths()
{
  static NSArray *paths = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    paths =
    @[
      @"name",
      @"foregroundColor",
      @"backgroundColor",
      @"lineHighlightColor",
      @"selectionColor",
      @"selectionBorderColor",
      @"inactiveSelectionColor",
      @"invisiblesColor",
      @"caretColor",
      @"uuid"
    ];
  });
  return paths;
}


static NSArray *observedSchemeRulePaths()
{
  static NSArray *paths = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    paths = @[
      @"name",
      @"selectors",
      @"foreground",
      @"background",
      @"flags"
    ];
  });
  return paths;
}


#pragma mark Private API for QRulesTableDelegate

@interface QRulesTableDelegate ()

@property (strong, readwrite) QSchemeRule *selectedRule;

@end


#pragma mark Private interface

@interface QDocument ()

@property (strong, readwrite) QScheme *scheme;
@property (weak) IBOutlet NSTableView *rulesTable;
@property (strong) QRulesTableData *rulesTableData;
@property (strong) QRulesTableDelegate *rulesTableDelegate;
@property (weak) IBOutlet NSTokenField *ruleScopeField;
@property (weak) IBOutlet NSButton *removeSelectedRulesButton;
@property (weak) IBOutlet NSTableView *selectorTable;
@property (strong) IBOutlet QSelectorTableSource *selectorData;

@property (strong) id observerKey;

@end


#pragma mark Implementation

@implementation QDocument

- (void)dealloc
{
  if (self.observerKey) {
    [[NSNotificationCenter defaultCenter] removeObserver:self.observerKey];
  }

  self.scheme = nil;

  [self removeObserver:self forKeyPath:@"scheme"];
}


- (id)init
{
    if ((self = [super init])) {
      NSUInteger options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
      [self addObserver:self forKeyPath:@"scheme" options:options context:NULL];
      self.scheme = [[QScheme alloc] initWithDocument:self];
    }
    return self;
}


- (void)bindTableView
{
  [self refreshTableAppearance];

  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

  if (self.observerKey) {
    [center removeObserver:self.observerKey];
    self.observerKey = nil;
  }

  __weak NSTableView *selectorTable = self.selectorTable;
  __weak NSButton *removeRulesButton = self.removeSelectedRulesButton;
  __weak QSelectorTableSource *selectorData = self.selectorData;
  void (^block)(NSNotification *) = ^(NSNotification *note) {
    NSTableView *view = (NSTableView *)note.object;
    NSIndexSet *indices = view ? view.selectedRowIndexes : nil;
    QRulesTableDelegate *delegate = view ? [note.object delegate] : nil;
    removeRulesButton.enabled = indices && [indices count] > 0;

    if (delegate) {
      if ([indices count] == 1) {
        QSchemeRule *rule = self.scheme.rules[indices.lastIndex];
        delegate.selectedRule = rule;
        selectorData.rule = rule;
      } else {
        delegate.selectedRule = nil;
        selectorData.rule = nil;
      }
      [selectorTable reloadData];
    }
  };

  self.selectorTable.dataSource = self.selectorData;
  self.rulesTableDelegate = [[QRulesTableDelegate alloc] initWithScheme:self.scheme tableView:self.rulesTable];
  self.rulesTableData = [[QRulesTableData alloc] initWithScheme:self.scheme];
  self.rulesTable.target = self.rulesTableDelegate;
  self.rulesTable.action = @selector(clickedTableView:);
  self.rulesTable.doubleAction = @selector(doubleClickedTableView:);
  self.rulesTable.delegate = self.rulesTableDelegate;
  self.rulesTable.dataSource = self.rulesTableData;
  self.observerKey = [center addObserverForName:NSTableViewSelectionDidChangeNotification
                                         object:self.rulesTable
                                          queue:[NSOperationQueue mainQueue]
                                     usingBlock:block];
}


#pragma mark NSDocument

- (NSString *)windowNibName
{
  return @"QDocument";
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
  [super windowControllerDidLoadNib:aController];

  self.ruleScopeField.delegate = self;

  [self bindTableView];
}


+ (BOOL)autosavesInPlace
{
  // Absolutely not.
  return YES;
}


#if 0

/*
 Implementation of these methods currently commented out because it doesn't allow the document
 to attach to a URL for some reason.
 */

- (NSData *)dataOfType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
  NSDictionary *plist = [self.scheme toPropertyList];

  if (!plist) {
    NSDictionary *info = @{
      @"type": typeName
    };
    *outError = [NSError errorWithDomain:@"QInvalidPList" code:2 userInfo:info];
    return NO;
  }

  return [NSPropertyListSerialization
          dataWithPropertyList:plist
          format:NSPropertyListXMLFormat_v1_0
          options:0
          error:outError];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
  NSDictionary *plist = [NSPropertyListSerialization
                         propertyListWithData:data
                         options:NSPropertyListImmutable
                         format:NULL
                         error:outError];
  if (!plist) {
    return NO;
  }

  self.scheme = [[QScheme alloc] initWithPropertyList:plist document:self];

  return YES;
}

#endif


- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
  NSDictionary *plist = [self.scheme toPropertyList];

  if (!plist) {
    NSDictionary *info = @{
      @"url": url,
      @"type": typeName
    };
    if (outError) {
      *outError = [NSError errorWithDomain:@"QInvalidPList" code:2 userInfo:info];
    }
    return NO;
  }

  if (![plist writeToURL:url atomically:NO]) {
    NSDictionary *info = @{
      @"url": url,
      @"type": typeName
    };
    if (outError) {
      *outError = [NSError errorWithDomain:@"QCannotWritePList" code:3 userInfo:info];
    }
    return NO;
  }

  return YES;
}


- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
  NSDictionary *plist = [NSDictionary dictionaryWithContentsOfURL:url];

  if (nil == plist) {
    NSDictionary *info = @{
      @"url": url,
      @"type": typeName
    };
    if (outError) {
      *outError = [NSError errorWithDomain:@"QInvalidPList" code:1 userInfo:info];
    }
    return NO;
  }

  self.scheme = [[QScheme alloc] initWithPropertyList:plist document:self];

  if (self.rulesTable) {
    [self bindTableView];
  }

  return YES;
}


- (BOOL)revertToContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
  if ([self readFromURL:url ofType:typeName error:outError]) {
    [self updateChangeCount:NSChangeCleared];

    return YES;
  }
  return NO;
}


#pragma mark Key-value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if ([keyPath isEqualToString:@"scheme"]) {
    NSNumber *kind = change[NSKeyValueChangeKindKey];
    switch (kind.unsignedIntegerValue) {
    case NSKeyValueChangeReplacement:
    case NSKeyValueChangeSetting:
      [self rebindObservationFromOldScheme:[change[NSKeyValueChangeOldKey] selfIfNotNull]
                               toNewScheme:[change[NSKeyValueChangeNewKey] selfIfNotNull]];
      break;
    default: break;
    }
  } else if (object == self.scheme) {
    [self updateChangeCount:NSChangeDone];

    if ([keyPath isEqual:@"rules"]) {
      [self rebindObservationFromOldRules:[change[NSKeyValueChangeOldKey] selfIfNotNull]
                               toNewRules:[change[NSKeyValueChangeNewKey] selfIfNotNull]];

      if (self.rulesTable) {
        [self.rulesTable reloadData];
      }
    }
  } else if ([object isKindOfClass:[QSchemeRule class]]) {
    // a rule changed
    [self updateChangeCount:NSChangeDone];
  }
}


- (void)rebindObservationFromOldScheme:(QScheme *)oldScheme toNewScheme:(QScheme *)newScheme
{
  [self rebindObservationFromOldObject:oldScheme
                           toNewObject:newScheme
                              forPaths:observedSchemePaths()];

  NSArray *oldRules = oldScheme ? oldScheme.rules : nil;
  NSArray *newRules = newScheme ? newScheme.rules : nil;

  [self rebindObservationFromOldRules:oldRules toNewRules:newRules];
}


- (void)rebindObservationFromOldRules:(NSArray *)oldRulesArray toNewRules:(NSArray *)newRulesArray
{
  NSArray *paths = observedSchemeRulePaths();

  NSSet *oldRules = nil;
  NSSet *newRules = nil;

  if (oldRulesArray && [oldRulesArray count]) {
    oldRules = [NSSet setWithArray:oldRulesArray];
  } else {
    oldRules = [NSSet set];
  }

  if (newRulesArray && [newRulesArray count]) {
    newRules = [NSSet setWithArray:newRulesArray];
  } else {
    newRules = [NSSet set];
  }

  if ([oldRules count]) {
    NSSet *filtered =
      [newRules count]
      ? [oldRules rejectedSetUsingBlock:^(id obj) { return [newRules containsObject:obj]; }]
      : oldRules;

    for (QSchemeRule *rule in filtered) {
      [self rebindObservationFromOldObject:rule toNewObject:nil forPaths:paths];
    }
  }

  if ([newRules count]) {
    NSSet *filtered =
      [oldRules count]
      ? [newRules rejectedSetUsingBlock:^(id obj) { return [oldRules containsObject:obj]; }]
      : newRules;

    for (QSchemeRule *rule in filtered) {
      [self rebindObservationFromOldObject:nil toNewObject:rule forPaths:paths];
    }
  }
}


- (void)rebindObservationFromOldObject:(id)oldObject toNewObject:(id)newObject forPaths:(NSArray *)paths
{
  if (oldObject) {
    for (NSString *path in paths) {
      [oldObject removeObserver:self forKeyPath:path];
    }
  }

  if (newObject) {
    for (NSString *path in paths) {
      [newObject addObserver:self forKeyPath:path options:0 context:NULL];
    }
  }
}


#pragma mark Actions

- (void) refreshTableAppearance
{
  self.rulesTable.backgroundColor = self.scheme.backgroundColor;
  [self.rulesTable reloadData];
}


- (IBAction)modifyColorWell:(id)sender
{
  [self refreshTableAppearance];
}


#pragma mark Edit rule scope

- (void)controlTextDidChange:(NSNotification *)obj
{
  id sender = obj.object;
  if ([sender isKindOfClass:[NSTokenField class]]) {
    [self updateRuleScope:sender];
  }
}


- (IBAction)updateRuleScope:(NSTokenField *)sender
{
  [self.rulesTableDelegate updateSelectedRuleSelectors:cleanedRuleSelectorArray(sender.stringValue)];
}


#pragma mark Add / remove rules

- (IBAction)appendNewRule:(id)sender {
  NSTableView *table = self.rulesTable;
  if (table) {
    [table beginUpdates];
    self.scheme.rules = [self.scheme.rules arrayByAddingObject:[[QSchemeRule alloc] initWithDocument:self]];
    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:[self.scheme.rules count] - 1];
    [table insertRowsAtIndexes:indices withAnimation:0];
    [table selectRowIndexes:indices byExtendingSelection:NO];
    [table endUpdates];

    __weak NSTableView *weakTable = table;
    NSUInteger row = indices.lastIndex;
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
      [weakTable scrollRowToVisible:row];
    }];
  }
}


- (IBAction)removeSelectedRules:(id)sender {
  NSTableView *table = self.rulesTable;
  if (table) {
    NSIndexSet *indices = table.selectedRowIndexes;

    if ([indices count]) {
      NSMutableArray *rules = [self.scheme.rules mutableCopy];
      [rules removeObjectsAtIndexes:indices];
      [table beginUpdates];
      self.scheme.rules = rules;
      [table removeRowsAtIndexes:indices withAnimation:NSTableViewAnimationSlideLeft];
      [table endUpdates];
    }
  }
}

@end
