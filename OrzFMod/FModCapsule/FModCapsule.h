//
//  FModCapsule.h
//  jokerHub
//
//  Created by JokerAtBaoFeng on 2018/1/3.
//  Copyright © 2018年 joker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FModEvent : NSObject

-(void)playBankWithPath:(NSString*)eventPath volume:(float)volume;
-(void)play:(float)volume;
-(void)stop;
-(void)releaseSound;
@end

@interface FModCapsule : NSObject
+(FModCapsule *)sharedSingleton;

-(void)releaseSystemFmod;
-(void)initializeFModSystem;
-(void)loadBankWithPath:(NSString*)bankPath;
-(void)update;
-(int)getEventLength:(NSString*)eventPath;

@end
