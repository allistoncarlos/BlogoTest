// Retirado de http://saturnboy.com/2011/02/stack-queue-nsmutablearray/

#import <Foundation/Foundation.h>

@interface NSMutableArray (Queue)

- (void) enqueue: (id)item;
- (id) dequeue;
- (id) peek;

@end