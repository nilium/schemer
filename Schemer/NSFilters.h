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

/* NSFilters.h - Noel Cower */

#ifndef __SNOW_NSFILTERS_H__
#define __SNOW_NSFILTERS_H__

#import <Foundation/Foundation.h>


typedef id (^SPMapBlock)(id obj);
typedef BOOL (^SPFilterBlock)(id obj);
typedef id (^SPReduceBlock)(id memo, id obj);


// Default stride used by concurrent methods below.
extern const NSUInteger NSFiltersDefaultStride;


/*
All map/select/reject operations can be performed asynchronously (provided your
block is fine under those conditions). They will block execution of the calling
thread until complete - if you want to run them without blocking, use
dispatch_async to call them, though bear in mind that for mutable containers,
you should not modify them while the operation is running (this sounds obvious,
but obvious things often have to be said).

map blocks must return non-nil objects (because you can't store nil in any
Cocoa containers - if you must, use NSNull).

Async map/reject/select will allow you to use an arbitrary stride. By default,
if you exclude the stride, they will use the NSFiltersDefaultStride of 256.
*/

@interface NSArray (SPImmutableArrayFilters)

// map
- (NSArray *)mappedTo:(SPMapBlock)block;

- (NSArray *)mappedTo:(SPMapBlock)block queue:(dispatch_queue_t)queue;

- (NSArray *)
  mappedTo:(SPMapBlock)block
     queue:(dispatch_queue_t)queue
    stride:(NSUInteger)stride;

// reject
- (NSArray *)rejectedBy:(SPFilterBlock)block;

- (NSArray *)rejectedBy:(SPFilterBlock)block queue:(dispatch_queue_t)queue;

- (NSArray *)
  rejectedBy:(SPFilterBlock)block
       queue:(dispatch_queue_t)queue
      stride:(NSUInteger)stride;

// select
- (NSArray *)selectedBy:(SPFilterBlock)block;

- (NSArray *)selectedBy:(SPFilterBlock)block queue:(dispatch_queue_t)queue;

- (NSArray *)
  selectedBy:(SPFilterBlock)block
       queue:(dispatch_queue_t)queue
      stride:(NSUInteger)stride;

// reduce
- (id)reduceWithInitialValue:(id)memo usingBlock:(SPReduceBlock)block;

// reduce (memo is nil)
- (id)reduceUsingBlock:(SPReduceBlock)block;

@end

@interface NSMutableArray (SPMutableArrayFilters)

// map
- (id)mapTo:(SPMapBlock)block;

- (id)mapTo:(SPMapBlock)block queue:(dispatch_queue_t)queue;

- (id)
   mapTo:(SPMapBlock)block
   queue:(dispatch_queue_t)queue
  stride:(NSUInteger)stride;

// reject
- (id)rejectBy:(SPFilterBlock)block;

- (id)rejectBy:(SPFilterBlock)block queue:(dispatch_queue_t)queue;

- (id)
  rejectBy:(SPFilterBlock)block
     queue:(dispatch_queue_t)queue
    stride:(NSUInteger)stride;

// select
- (id)selectBy:(SPFilterBlock)block;

- (id)selectBy:(SPFilterBlock)block queue:(dispatch_queue_t)queue;

- (id)
  selectBy:(SPFilterBlock)block
     queue:(dispatch_queue_t)queue
    stride:(NSUInteger)stride;

@end

@interface NSSet (SPImmutableSetFilters)

// map
- (NSSet *)mappedTo:(SPMapBlock)block;

- (NSSet *)mappedTo:(SPMapBlock)block queue:(dispatch_queue_t)queue;

- (NSSet *)
  mappedTo:(SPMapBlock)block
     queue:(dispatch_queue_t)queue
    stride:(NSUInteger)stride;

// reject
- (NSSet *)rejectedBy:(SPFilterBlock)block;

- (NSSet *)rejectedBy:(SPFilterBlock)block queue:(dispatch_queue_t)queue;

- (NSSet *)
  rejectedBy:(SPFilterBlock)block
       queue:(dispatch_queue_t)queue
      stride:(NSUInteger)stride;

// select
- (NSSet *)selectedBy:(SPFilterBlock)block;

- (NSSet *)selectedBy:(SPFilterBlock)block queue:(dispatch_queue_t)queue;

- (NSSet *)
  selectedBy:(SPFilterBlock)block
       queue:(dispatch_queue_t)queue
      stride:(NSUInteger)stride;

// reduce
- (id)reduceWithInitialValue:(id)memo usingBlock:(SPReduceBlock)block;

// reduce (memo is nil)
- (id)reduceUsingBlock:(SPReduceBlock)block;

// auxiliary getObjects:count: to place set objects in an unretained array
- (void)
  getUnsafeObjects:(__unsafe_unretained id *)objects
             count:(NSUInteger)count;

@end

@interface NSMutableSet (SPMutableSetFilters)

// map
- (id)mapTo:(SPMapBlock)block;

- (id)mapTo:(SPMapBlock)block queue:(dispatch_queue_t)queue;

- (id)
   mapTo:(SPMapBlock)block
   queue:(dispatch_queue_t)queue
  stride:(NSUInteger)stride;

// reject
- (id)rejectBy:(SPFilterBlock)block;

- (id)rejectBy:(SPFilterBlock)block queue:(dispatch_queue_t)queue;

- (id)
  rejectBy:(SPFilterBlock)block
     queue:(dispatch_queue_t)queue
    stride:(NSUInteger)stride;

// select
- (id)selectBy:(SPFilterBlock)block;

- (id)selectBy:(SPFilterBlock)block queue:(dispatch_queue_t)queue;

- (id)
  selectBy:(SPFilterBlock)block
     queue:(dispatch_queue_t)queue
    stride:(NSUInteger)stride;

@end

#endif /* end __SNOW_NSFILTERS_H__ include guard */
