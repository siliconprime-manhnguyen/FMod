//
//  FModCapsule.h
//  jokerHub
//
//  Created by JokerAtBaoFeng on 2018/1/3.
//  Copyright © 2018年 joker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FModEvent : NSObject

-(id)playBankWithPath:(NSString*)eventPath volume:(float)volume;
-(void)play;
-(void)stop;

@end

@interface FModCapsule : NSObject
-(void)releaseSystemFmod;
-(void)initializeFModSystem;
-(void)loadBankWithPath:(NSString*)bankPath;
-(void)playStreamWithFilePath:(NSString *)filePath;
-(void)play;
-(void)pause;
-(void)stop;
-(void)close;
-(BOOL)isPlaying;
-(int)getEventLength:(NSString*)eventPath;

@end
