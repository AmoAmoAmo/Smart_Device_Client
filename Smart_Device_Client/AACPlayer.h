//
//  AACPlayer.h
//  Audio_Client
//
//  Created by Josie on 2017/10/11.
//  Copyright © 2017年 Josie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>


@interface AACPlayer : NSObject

-(void)playAudioWithData:(char*)pBuf andLength:(ssize_t)length;
-(void)stop;

-(void)audioPause;
-(void)audioStart;
@end
