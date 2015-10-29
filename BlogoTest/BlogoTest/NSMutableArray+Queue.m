// Retirado de http://saturnboy.com/2011/02/stack-queue-nsmutablearray/

#import "NSMutableArray+Queue.h"

@implementation NSMutableArray (Queue)

- (void) enqueue: (id)item {
	[self addObject:item];
}

- (id) dequeue {
	id item = nil;
	if ([self count] != 0) {
		item = [self objectAtIndex:0];
		[self removeObjectAtIndex:0];
	}
	return item;
}

- (id) peek {
	id item = nil;
	if ([self count] != 0) {
		item = [self objectAtIndex:0];
	}
	return item;
}

@end