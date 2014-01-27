/*
Copyright (c) 2012 Noel Cower

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#import "NSFilters.h"

// An arbitrarily chosen stride - change to suit your needs.
const NSUInteger NSFiltersDefaultStride = 256;

typedef __unsafe_unretained id unsafe_id;
typedef void (^s_complete_block_t)(const unsafe_id* objects, size_t num_objects);

static NSString *const SPNilObjectMappingException = @"SPNilObjectMappingException";
static NSString *const SPNilObjectMappingExceptionReason = @"Objects returned by map blocks must not be nil.";
static NSString *const SPNoMemoryException = @"SPNoMemoryException";
static NSString *const SPNoMemoryExceptionReason = @"Unable to allocate objects array.";

// Mutates the given mutable array, removing blocks that match checkFor (TRUE or FALSE)
static void SPFilterArrayUsingBlock(NSMutableArray *arr, SPFilterBlock block, BOOL checkFor, NSUInteger stride, dispatch_queue_t queue);
// Returns a new array filtered by removing blocks that match checkFor (TRUE or FALSE)
static NSArray *SPArrayFilteredUsingBlock(NSArray *arr, SPFilterBlock block, BOOL checkFor, NSUInteger stride, dispatch_queue_t queue);
// Transforms all objects in the array with the given block and then passes an id array of the objects to the completion block.
static void SPMapArrayUsingBlock(NSArray *array, SPMapBlock block, NSUInteger stride, dispatch_queue_t queue, s_complete_block_t completion);
// Similar to SPMapArrayUsingBlock, except passes an id array of the objects passing the test to the completion block.
static void SPFilterSetUsingBlock(NSSet *set, SPFilterBlock block, BOOL checkFor, NSUInteger stride, dispatch_queue_t queue, s_complete_block_t completion);
// More or less the same as SPMapArrayUsingBlock, just for sets.
static void SPMapSetUsingBlock(NSSet *set, SPMapBlock block, NSUInteger stride, dispatch_queue_t queue, s_complete_block_t completion);

static NSArray *SPArrayFilteredUsingBlock(NSArray *arr, SPFilterBlock block, BOOL checkFor, NSUInteger stride, dispatch_queue_t queue)
{
  dispatch_group_t write_group;
  NSArray *result = nil;
  unsafe_id *objects = NULL;
  __block NSUInteger index_filtered = 0;
  NSUInteger index = 0;
  const NSUInteger array_len = [arr count];
  const NSRange range = NSMakeRange(0, array_len);

  if (array_len == 0)
    return [arr copy];

  objects = (unsafe_id *)calloc(array_len, sizeof(id));

  if (objects == NULL) {
    @throw [NSException exceptionWithName:SPNoMemoryException
                                   reason:SPNoMemoryExceptionReason
                                 userInfo:nil];
    return nil;
  }

  [arr getObjects:objects range:range];

  if (queue) {
    size_t iterations = (size_t)(array_len / stride);
    if (array_len % stride)
      ++iterations;
    write_group = dispatch_group_create();
    dispatch_apply(iterations, queue, ^(size_t start) {
      NSUInteger index = start * stride;
      NSUInteger term = index + stride;
      if (term > array_len)
        term = array_len;

      for (; index < term; ++index) {
        id object = objects[index];
        BOOL filter = (block(object) == checkFor);

        if (filter) {
          objects[index] = NULL;
        } else {
          dispatch_group_enter(write_group);
          dispatch_barrier_async(queue, ^{
            if (index != index_filtered)
              objects[index_filtered] = object;

            ++index_filtered;
            dispatch_group_leave(write_group);
          });
        }
      }
    });
    dispatch_group_wait(write_group, DISPATCH_TIME_FOREVER);
  } else {
    for (index = 0, index_filtered = 0; index < array_len; ++index) {
      BOOL filter = block(objects[index]);

      if (filter == checkFor) {
        objects[index] = NULL;
      } else {
        if (index != index_filtered)
          objects[index_filtered] = objects[index];

        ++index_filtered;
      }
    }
  }

  result = [[arr class] arrayWithObjects:objects count:index_filtered];

  free(objects);

  return result;
}


static void SPFilterArrayUsingBlock(NSMutableArray *arr, SPFilterBlock block, BOOL checkFor, NSUInteger stride, dispatch_queue_t queue)
{
  dispatch_group_t write_group;
  unsafe_id *objects = NULL;
  NSUInteger index = 0;
  NSMutableIndexSet *indices = nil;
  const NSUInteger array_len = [arr count];
  const NSRange range = NSMakeRange(0, array_len);

  if (array_len == 0)
    return;

  objects = (unsafe_id *)calloc(array_len, sizeof(id));

  if (objects == NULL) {
    @throw [NSException exceptionWithName:SPNoMemoryException
                                   reason:SPNoMemoryExceptionReason
                                 userInfo:nil];
    return;
  }

  indices = [NSMutableIndexSet indexSet];
  [arr getObjects:objects range:range];

  if (queue) {
    size_t iterations = (size_t)(array_len / stride);
    if (array_len % stride)
      ++iterations;
    write_group = dispatch_group_create();
    dispatch_apply(iterations, queue, ^(size_t start) {
      NSUInteger obj_index = start * stride;
      NSUInteger term = obj_index + stride;
      if (term > array_len)
        term = array_len;

      for (; obj_index < term; ++obj_index) {
        if (block(objects[obj_index]) == checkFor) {
          const NSUInteger index_for_set = (NSUInteger)obj_index - 1;
          dispatch_group_enter(write_group);
          dispatch_barrier_async(queue, ^{
            [indices addIndex:index_for_set];
            dispatch_group_leave(write_group);
          });
        }
      }
    });
    dispatch_group_wait(write_group, DISPATCH_TIME_FOREVER);
  } else {
    for (index = 0; index < array_len; ++index)
      if (block(objects[index]) == checkFor)
        [indices addIndex:index];
  }

  if ([indices count] > 0)
    [arr removeObjectsAtIndexes:indices];

  free(objects);
}


static void SPFilterSetUsingBlock(NSSet *set, SPFilterBlock block, BOOL checkFor, NSUInteger stride, dispatch_queue_t queue, s_complete_block_t completion)
{
  dispatch_group_t write_group;
  unsafe_id *objects = NULL;
  NSUInteger index;
  __block NSUInteger matched_count = 0;
  const NSUInteger set_len = [set count];

  if (set_len == 0) {
    if (completion)
      completion(NULL, 0);

    return;
  }

  objects = (unsafe_id *)calloc(set_len, sizeof(id));

  if (objects == NULL) {
    @throw [NSException exceptionWithName:SPNoMemoryException
                                   reason:SPNoMemoryExceptionReason
                                 userInfo:nil];
    return;
  }

  if (queue) {
    write_group = dispatch_group_create();
    size_t iterations = (size_t)(set_len / stride);
    if (set_len % stride)
      ++iterations;
    [set getUnsafeObjects:objects count:set_len];
    dispatch_apply(iterations, queue, ^(size_t start) {
      NSUInteger obj_index = start * stride;
      NSUInteger term = obj_index + stride;
      if (term > set_len)
        term = set_len;

      for (; obj_index < term; ++obj_index) {
        id obj = objects[obj_index];
        if (block(obj) == checkFor) {
          dispatch_group_enter(write_group);
          dispatch_barrier_async(queue, ^{
            objects[matched_count++] = (__bridge id)CFRetain((__bridge CFTypeRef)obj);
            dispatch_group_leave(write_group);
          });
        }
      }
    });
    dispatch_group_wait(write_group, DISPATCH_TIME_FOREVER);
  } else {
    for (id obj in set) {
      if (block(obj) == checkFor)
        objects[matched_count++] = (__bridge id)CFRetain((__bridge CFTypeRef)obj);
    }
  }

  if (matched_count && completion)
    completion(objects, matched_count);

  for (index = 0; index < matched_count; ++index)
    CFRelease((__bridge CFTypeRef)objects[index]);

  free(objects);
}


static void SPMapArrayUsingBlock(NSArray *array, SPMapBlock block, NSUInteger stride, dispatch_queue_t queue, s_complete_block_t completion)
{
  __block id exception = nil;
  unsafe_id *objects = NULL;
  NSUInteger index = 0;
  const NSUInteger array_len = [array count];
  const NSRange range = NSMakeRange(0, array_len);

  if (array_len == 0) {
    if (completion)
      completion(NULL, 0);

    return;
  }

  objects = (unsafe_id *)calloc(array_len, sizeof(id));

  if (objects == NULL) {
    @throw [NSException exceptionWithName:SPNoMemoryException
                                   reason:SPNoMemoryExceptionReason
                                 userInfo:nil];
    return;
  }

  [array getObjects:objects range:range];

  if (queue) {
    __weak id weak_self = array;
    size_t iterations = (size_t)(array_len / stride);
    if (array_len % stride)
      ++iterations;
    dispatch_apply(iterations, queue, ^(size_t start) {
      NSUInteger obj_index = start * stride;
      NSUInteger term = obj_index + stride;
      if (term > array_len)
        term = array_len;

      for (; obj_index < term; ++obj_index) {
        id mapped = block(objects[obj_index]);
        if (mapped == nil) {
          // prevents the original object from being incorrectly released on cleanup
          objects[obj_index] = nil;
          @synchronized(weak_self) {
            exception = [NSException exceptionWithName:SPNilObjectMappingException
                         reason:SPNilObjectMappingExceptionReason userInfo:nil];
          }
        } else {
          objects[obj_index] = (__bridge id)CFRetain((__bridge CFTypeRef)mapped);
        }
      }
    });
  } else {
    for (index = 0; index < array_len; ++index) {
      id mapped = block(objects[index]);
      if ( ! (objects[index] = block(objects[index]))) {
        goto sp_array_map_cleanup;
        exception = [NSException exceptionWithName:SPNilObjectMappingException
                     reason:SPNilObjectMappingExceptionReason userInfo:nil];
      }
      objects[index] = (__bridge id)CFRetain((__bridge CFTypeRef)mapped);
    }
  }

  if (completion && !exception)
    completion(objects, array_len);

sp_array_map_cleanup:
  for (index = 0; index < array_len; ++index)
    if (objects[index])
      CFRelease((__bridge CFTypeRef)objects[index]);

  free(objects);

  if (exception)
    @throw exception;
}


static void SPMapSetUsingBlock(NSSet *set, SPMapBlock block, NSUInteger stride, dispatch_queue_t queue, s_complete_block_t completion)
{
  __block id exception = nil;
  const NSUInteger num_objects = [set count];
  unsafe_id *objects;
  NSUInteger index = 0;

  if (num_objects == 0) {
    if (completion)
      completion(NULL, 0);

    return;
  }

  objects = (unsafe_id *)calloc(num_objects, sizeof(id));

  if (!objects) {
    @throw [NSException exceptionWithName:SPNoMemoryException
            reason:SPNoMemoryExceptionReason userInfo:nil];
    return;
  }

  if (queue) {
    __weak id weak_self = set;
    size_t iterations = (size_t)(num_objects / stride);
    if (num_objects % stride)
      ++iterations;
    [set getUnsafeObjects:objects count:num_objects];
    dispatch_apply(iterations, queue, ^(size_t start) {
      NSUInteger obj_index = start * stride;
      NSUInteger term = obj_index + stride;
      if (term > num_objects)
        term = num_objects;

      for (; obj_index < term; ++obj_index) {
        id mapped = block(objects[obj_index]);
        if (mapped == nil) {
          @synchronized(weak_self) {
            exception = [NSException exceptionWithName:SPNilObjectMappingException
                         reason:SPNilObjectMappingExceptionReason userInfo:nil];
          }
          objects[obj_index] = nil;
          return;
        }
        objects[obj_index] = (__bridge id)CFRetain((__bridge CFTypeRef)mapped);
      }
    });
  } else {
    for (id obj in set) {
      id mapped = block(obj);
      if (mapped == nil) {
        exception = [NSException exceptionWithName:SPNilObjectMappingException
                     reason:SPNilObjectMappingExceptionReason userInfo:nil];
        goto sp_set_map_cleanup;
      }
      objects[index] = (__bridge id)CFRetain((__bridge CFTypeRef)mapped);
      ++index;
    }
  }

  if (completion && !exception)
    completion(objects, num_objects);

sp_set_map_cleanup:
  for (index = 0; index < num_objects; ++index)
    if (objects[index])
      CFRelease((__bridge CFTypeRef)objects[index]);

  free(objects);

  if (exception)
    @throw exception;
}


@implementation NSArray (SPImmutableArrayFilters)

- (NSArray *)mappedArrayUsingBlock:(SPMapBlock)block
{
  return [self mappedArrayUsingBlock:block queue:nil stride:NSFiltersDefaultStride];
}

- (NSArray *)mappedArrayUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue
{
  return [self mappedArrayUsingBlock:block queue:nil stride:NSFiltersDefaultStride];
}

- (NSArray *)mappedArrayUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride
{
  __block NSArray *result = nil;
  NSAssert(stride > 0, @"Stride must be greater than zero.");

  SPMapArrayUsingBlock(self, block, stride, queue, ^(const unsafe_id *objects, NSUInteger num_objects) {
      if (!objects)
        result = [self copy];
      else
        result = [[self class] arrayWithObjects:objects count:num_objects];
    });

  return result;
}

- (NSArray *)rejectedArrayUsingBlock:(SPFilterBlock)block
{
  return SPArrayFilteredUsingBlock(self, block, TRUE, NSFiltersDefaultStride, nil);
}

- (NSArray *)selectedArrayUsingBlock:(SPFilterBlock)block
{
  return SPArrayFilteredUsingBlock(self, block, FALSE, NSFiltersDefaultStride, nil);
}

- (NSArray *)rejectedArrayUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue
{
  return SPArrayFilteredUsingBlock(self, block, TRUE, NSFiltersDefaultStride, queue);
}

- (NSArray *)selectedArrayUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue
{
  return SPArrayFilteredUsingBlock(self, block, FALSE, NSFiltersDefaultStride, queue);
}

- (NSArray *)rejectedArrayUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride
{
  NSAssert(stride > 0, @"Stride must be greater than zero.");
  return SPArrayFilteredUsingBlock(self, block, TRUE, stride, queue);
}

- (NSArray *)selectedArrayUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride
{
  NSAssert(stride > 0, @"Stride must be greater than zero.");
  return SPArrayFilteredUsingBlock(self, block, FALSE, stride, queue);
}

- (id)reduceWithInitialValue:(id)memo usingBlock:(SPReduceBlock)block
{
  for (id obj in self)
    memo = block(memo, obj);

  return memo;
}

- (id)reduceUsingBlock:(SPReduceBlock)block
{
  return [self reduceWithInitialValue:nil usingBlock:block];
}

@end

@implementation NSMutableArray (SPMutableArrayFilters)

- (id)mapUsingBlock:(SPMapBlock)block
{
  return [self mapUsingBlock:block queue:nil stride:NSFiltersDefaultStride];
}

- (id)mapUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue
{
  return [self mapUsingBlock:block queue:queue stride:NSFiltersDefaultStride];
}

- (id)mapUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride
{
  NSAssert(stride > 0, @"Stride must be greater than zero.");
  SPMapArrayUsingBlock(self, block, stride, queue, ^(const unsafe_id *objects, NSUInteger num_objects) {
      NSUInteger index = 0;
      for (; index < num_objects; ++index)
        [self replaceObjectAtIndex:index withObject:objects[index]];
    });
  return self;
}

- (id)rejectUsingBlock:(SPFilterBlock)block
{
  SPFilterArrayUsingBlock(self, block, TRUE, NSFiltersDefaultStride, nil);
  return self;
}

- (id)selectUsingBlock:(SPFilterBlock)block
{
  SPFilterArrayUsingBlock(self, block, FALSE, NSFiltersDefaultStride, nil);
  return self;
}

- (id)rejectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue
{
  SPFilterArrayUsingBlock(self, block, TRUE, NSFiltersDefaultStride, queue);
  return self;
}

- (id)selectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue
{
  SPFilterArrayUsingBlock(self, block, FALSE, NSFiltersDefaultStride, queue);
  return self;
}

- (id)rejectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride
{
  NSAssert(stride > 0, @"Stride must be greater than zero.");
  SPFilterArrayUsingBlock(self, block, TRUE, stride, queue);
  return self;
}

- (id)selectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride
{
  NSAssert(stride > 0, @"Stride must be greater than zero.");
  SPFilterArrayUsingBlock(self, block, FALSE, stride, queue);
  return self;
}

@end

@implementation NSSet (SPImmutableSetFilters)

- (NSSet *)mappedSetUsingBlock:(SPMapBlock)block
{
  return [self mappedSetUsingBlock:block queue:nil stride:NSFiltersDefaultStride];
}

- (NSSet *)mappedSetUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue
{
  return [self mappedSetUsingBlock:block queue:queue stride:NSFiltersDefaultStride];
}

- (NSSet *)mappedSetUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride
{
  __block NSSet *result = nil;

  SPMapSetUsingBlock(self, block, stride, queue, ^(const unsafe_id *objects, NSUInteger num_objects){
      if (!objects)
        result = [self copy];
      else
        result = [NSSet setWithObjects:objects count:num_objects];
    });
  return result;
}

- (NSSet *)rejectedSetUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride
{
  __block NSSet *result;
  SPFilterSetUsingBlock(self, block, FALSE, stride, queue, ^(const unsafe_id *objects, NSUInteger num_objects) {
      result = [NSSet setWithObjects:objects count:num_objects];
    });
  return result;
}

- (NSSet *)selectedSetUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride
{
  __block NSSet *result;
  SPFilterSetUsingBlock(self, block, TRUE, stride, queue, ^(const unsafe_id *objects, NSUInteger num_objects) {
      result = [NSSet setWithObjects:objects count:num_objects];
    });
  return result;
}

- (NSSet *)rejectedSetUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue
{
  return [self rejectedSetUsingBlock:block queue:queue stride:NSFiltersDefaultStride];
}

- (NSSet *)selectedSetUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue
{
  return [self selectedSetUsingBlock:block queue:queue stride:NSFiltersDefaultStride];
}

- (NSSet *)rejectedSetUsingBlock:(SPFilterBlock)block
{
  return [self rejectedSetUsingBlock:block queue:nil stride:NSFiltersDefaultStride];
}

- (NSSet *)selectedSetUsingBlock:(SPFilterBlock)block
{
  return [self selectedSetUsingBlock:block queue:nil stride:NSFiltersDefaultStride];
}

- (id)reduceWithInitialValue:(id)memo usingBlock:(SPReduceBlock)block
{
  for (id obj in self)
    memo = block(memo, obj);

  return memo;
}

- (id)reduceUsingBlock:(SPReduceBlock)block
{
  return [self reduceWithInitialValue:nil usingBlock:block];
}


- (void)getUnsafeObjects:(__unsafe_unretained id *)objects count:(NSUInteger)count
{
  if (count < 1)
    return;

  for (id obj in self) {
    objects[--count] = obj;
    if ( ! count)
      return;
  }
}

@end

@implementation NSMutableSet (SPMutableSetFilters)

- (id)mapUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride
{
  SPMapSetUsingBlock(self, block, stride, queue, ^(const unsafe_id *objects, NSUInteger num_objects){
      if (objects) {
        NSUInteger index = 0;
        [self removeAllObjects];
        for (; index < num_objects; ++index)
          [self addObject:objects[index]];
      }
    });
  return self;
}

- (id)rejectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride
{
  SPFilterSetUsingBlock(self, block, TRUE, stride, queue, ^(const unsafe_id *objects, NSUInteger num_objects) {
      NSUInteger index = 0;
      for (; index < num_objects; ++index)
        [self removeObject:objects[index]];
    });
  return self;
}

- (id)selectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue stride:(NSUInteger)stride
{
  SPFilterSetUsingBlock(self, block, FALSE, stride, queue, ^(const unsafe_id *objects, NSUInteger num_objects) {
      NSUInteger index = 0;
      for (; index < num_objects; ++index)
        [self removeObject:objects[index]];
    });
  return self;
}

- (id)mapUsingBlock:(SPMapBlock)block queue:(dispatch_queue_t)queue
{
  return [self mapUsingBlock:block queue:queue stride:NSFiltersDefaultStride];
}

- (id)rejectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue
{
  return [self rejectUsingBlock:block queue:queue stride:NSFiltersDefaultStride];
}

- (id)selectUsingBlock:(SPFilterBlock)block queue:(dispatch_queue_t)queue
{
  return [self selectUsingBlock:block queue:queue stride:NSFiltersDefaultStride];
}

- (id)mapUsingBlock:(SPMapBlock)block
{
  return [self mapUsingBlock:block queue:nil stride:NSFiltersDefaultStride];
}

- (id)rejectUsingBlock:(SPFilterBlock)block
{
  return [self rejectUsingBlock:block queue:nil stride:NSFiltersDefaultStride];
}

- (id)selectUsingBlock:(SPFilterBlock)block
{
  return [self selectUsingBlock:block queue:nil stride:NSFiltersDefaultStride];
}

@end
