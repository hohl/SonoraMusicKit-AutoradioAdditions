//
//  SMKQueueController.h
//  SNRMusicKit
//
//  Created by Indragie Karunaratne on 2012-08-29.
//  Copyright (c) 2012 Indragie Karunaratne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMKTrack.h"
#import "SMKPlayer.h"

enum {
    SMKQueueControllerRepeatModeNone = 0,
    SMKQueueControllerRepeatModeAll = 1,
    SMKQueueControllerRepeatModeOne = 2
};
typedef NSUInteger SMKQueueControllerRepeatMode;

// Notifications used to handle transitions between tracks.
static const NSString *SMKQueueTransitToNextTrackNotification = @"SMKQueueControllerTransitToNextTrackNotification";
static const NSString *SMKQueueTransitToPreviousTrackNotification = @"SMKQueueControllerTransitToPreviousTrackNotification";

@interface SMKQueueController : NSObject

#pragma mark - Queueing

@property (nonatomic, retain, readonly) NSArray *tracks;
- (id)initWithTracks:(NSArray *)tracks;
+ (instancetype)queueControllerWithTracks:(NSArray *)tracks;

- (void)insertTrack:(id<SMKTrack>)newTrack afterTrack:(id<SMKTrack>)track;
- (void)removeAllTracks;
- (void)removeTrack:(id<SMKTrack>)track;

#pragma mark - Player

@property (nonatomic, strong, readonly) id<SMKPlayer> currentPlayer;
@property (nonatomic, strong, readonly) id<SMKTrack> currentTrack;
@property (nonatomic, strong, readonly) id<SMKTrack> nextTrack;
@property (nonatomic, strong, readonly) id<SMKTrack> previousTrack;
@property (nonatomic, assign, readonly) NSUInteger indexOfCurrentTrack;
@property (nonatomic, assign, readonly) BOOL playing;
@property (nonatomic, assign) BOOL shuffle;
@property (nonatomic, assign) SMKQueueControllerRepeatMode repeatMode;
#if !TARGET_OS_IPHONE
@property (nonatomic, assign) float volume;
#endif

- (IBAction)play:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)playPause:(id)sender;
- (IBAction)next:(id)sender;
- (IBAction)previous:(id)sender;
- (IBAction)seekForward:(id)sender;
- (IBAction)seekBackward:(id)sender;

@property (nonatomic, assign, readonly) NSTimeInterval playbackTime;
- (void)seekToPlaybackTime:(NSTimeInterval)playbackTime;
@end
