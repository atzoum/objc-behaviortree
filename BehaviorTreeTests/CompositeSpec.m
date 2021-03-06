/*
 * objc-behaviortree: http://github.com/andoco/objc-behaviortree
 *
 * Copyright (c) 2012 Andrew O'Connor
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "Kiwi.h"
#import "AOTask.h"
#import "AOComposite.h"

SPEC_BEGIN(CompositeSpec)

describe(@"Composite", ^{
    __block AOComposite *task;
    __block NSMutableDictionary *blackboard;
    
    beforeEach(^{
        task = [[AOComposite alloc] init];
    });

    context(@"when initialized", ^{
        it(@"children should be empty", ^{
            [task.children shouldNotBeNil];
            [[theValue(task.children.count) should] equal:theValue(0)];
        });
    });
    
    context(@"when child added", ^{
        it(@"should be added to children", ^{
            id action1 = [KWMock nullMockForProtocol:@protocol(AOTask)];
            id action2 = [KWMock nullMockForProtocol:@protocol(AOTask)];
            
            [task addChild:action1];
            [task addChild:action2];
            
            [[theValue(task.children.count) should] equal:theValue(2)];
            [[[task.children objectAtIndex:0] should] equal:action1];
            [[[task.children objectAtIndex:1] should] equal:action2];
        });
    });
    
    context(@"when initialized with children", ^{
        
        it(@"arguments should be added to children", ^{
            id task1 = [KWMock nullMockForProtocol:@protocol(AOTask)];
            id task2 = [KWMock nullMockForProtocol:@protocol(AOTask)];
            
            task = [[AOComposite alloc] initWithChildren:task1, task2, nil];

            [[theValue(task.children.count) should] equal:theValue(2)];
        });
    });
    
    context(@"when run", ^{
                
        beforeEach(^{
            blackboard = [NSMutableDictionary dictionary];
        });
        
        it(@"should start all child tasks with status Ready", ^{
            id task1 = [KWMock nullMockForProtocol:@protocol(AOTask)];
            [[task1 stubAndReturn:theValue(AOStatusReady)] status];
            [[task1 should] receive:@selector(start:)];
            
            id task2 = [KWMock nullMockForProtocol:@protocol(AOTask)];
            [[task2 stubAndReturn:theValue(AOStatusRunning)] status];
            [[task2 shouldNot] receive:@selector(start)];
            
            [task addChild:task1];
            [task addChild:task2];
            
            [task run:blackboard];
        });
        
        it(@"should stop child task that returns Success", ^{
            id task1 = [KWMock nullMockForProtocol:@protocol(AOTask)];
            [[task1 stubAndReturn:theValue(AOStatusReady)] status];
            [[task1 stubAndReturn:theValue(AOResultSuccess)] run:blackboard];
            [[task1 should] receive:@selector(stop:)];
            
            [task addChild:task1];
            
            [task run:blackboard];
        });
        
        it(@"should stop child task that returns Failure", ^{
            id task1 = [KWMock nullMockForProtocol:@protocol(AOTask)];
            [[task1 stubAndReturn:theValue(AOStatusReady)] status];
            [[task1 stubAndReturn:theValue(AOResultFailure)] run:blackboard];
            [[task1 should] receive:@selector(stop:)];
            
            [task addChild:task1];
            
            [task run:blackboard];
        });

        it(@"should not stop child task that returns Pending", ^{
            id task1 = [KWMock nullMockForProtocol:@protocol(AOTask)];
            [[task1 stubAndReturn:theValue(AOStatusReady)] status];
            [[task1 stubAndReturn:theValue(AOResultPending)] run:blackboard];
            [[task1 shouldNot] receive:@selector(stop)];
            
            [task addChild:task1];
            
            [task run:blackboard];            
        });
        
        context(@"child task returns Success", ^{
            it(@"should change task status to Ready", ^{
                id task1 = [KWMock nullMockForProtocol:@protocol(AOTask)];
                [[task1 should] receive:@selector(run:) andReturn:theValue(AOResultSuccess)];
                [[task1 should] receive:@selector(setStatus:) withArguments:theValue(AOStatusReady)];
                
                [task addChild:task1];
                
                [task run:blackboard];
            });
        });

        context(@"child task returns Failure", ^{
            it(@"should change task status to Ready", ^{
                id task1 = [KWMock nullMockForProtocol:@protocol(AOTask)];
                [[task1 should] receive:@selector(run:) andReturn:theValue(AOResultFailure)];
                [[task1 should] receive:@selector(setStatus:) withArguments:theValue(AOStatusReady)];
                
                [task addChild:task1];
                
                [task run:blackboard];
            });
        });

        context(@"child task returns Pending", ^{
            it(@"should change task status to Running", ^{
                id task1 = [KWMock nullMockForProtocol:@protocol(AOTask)];
                [[task1 should] receive:@selector(run:) andReturn:theValue(AOResultPending)];
                [[task1 should] receive:@selector(setStatus:) withArguments:theValue(AOStatusRunning)];
                
                [task addChild:task1];
                
                [task run:blackboard];
            });
        });

    });
    
    context(@"when stopped", ^{

        it(@"should stop running children", ^{
            
            id task1 = [KWMock nullMockForProtocol:@protocol(AOTask)];
            [[task1 stubAndReturn:theValue(AOStatusRunning)] status];
            [[task1 should] receive:@selector(stop:) withArguments:blackboard];

            id task2 = [KWMock nullMockForProtocol:@protocol(AOTask)];
            [[task2 stubAndReturn:theValue(AOStatusRunning)] status];
            [[task2 should] receive:@selector(stop:) withArguments:blackboard];

            [task addChild:task1];
            [task addChild:task2];
            
            [task stop:blackboard];
        });
        
    });
});

SPEC_END