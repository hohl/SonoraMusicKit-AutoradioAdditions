//
//  SMKQueueController.m
//  SNRMusicKit
//
//  Created by Indragie Karunaratne on 2012-08-29.
//  Copyright (c) 2012 Indragie Karunaratne. All rights reserved.
//

#import "SMKQueueController.h"
#import "SMKErrorCodes.h"
#import "NSError+SMKAdditions.h"
#import "NSMutableArray+SMKAdditions.h"

@interface SMKQueueItem : NSObject
@property (nonatomic, retain) id<SMKTrack> track;
@end

@interface SMKQueueController ()
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong, readwrite) id<SMKPlayer> currentPlayer;
@property (nonatomic, assign, readwrite) NSUInteger indexOfCurrentTrack;
@end

@implementation SMKQueueController {
    NSArray *_shuffledTrackIndexes;
    NSArray *_continualTrackIndexes;
}
- (id)init
{
    if ((self = [super init])) {
        self.items = [NSMutableArray array];
    }
    return self;
}

- (id)initWithTracks:(NSArray *)tracks
{
    if ((self = [super init])) {
        NSArray *items = [self _queueItemsForTracks:tracks];
        self.items = [NSMutableArray arrayWithArray:items];
    }
    return self;
}

+ (instancetype)queueControllerWithTracks:(NSArray *)tracks
{
    return [[self alloc] initWithTracks:tracks];
}

#pragma mark - Queue

- (void)insertTrack:(id<SMKTrack>)newTrack afterTrack:(id<SMKTrack>)track
{
    if (!track) {
        [self.items addObjectsFromArray:[self _queueItemsForTracks:@[newTrack]]];
    } else {
        NSUInteger index = [self _indexOfTrack:track];
        if (index != NSNotFound)
            [self insertObject:[self _queueItemForTrack:newTrack] inItemsAtIndex:index+1];
    }
}

- (void)removeAllTracks
{
    [self pause:nil];
    self.items = [NSMutableArray array];
    self.currentPlayer = nil;
}

- (void)removeTrack:(id<SMKTrack>)track
{
    NSUInteger index = [self _indexOfTrack:track];
    if (index == NSNotFound)
        return;
    if ([track isEqual:self.currentTrack]) {
        [self next:nil];
    }
    [self removeObjectFromItemsAtIndex:index];
}

#pragma mark - Accessors

- (NSTimeInterval)playbackTime
{
    return [self.currentPlayer playbackTime];
}

- (void)seekToPlaybackTime:(NSTimeInterval)playbackTime
{
    [self.currentPlayer seekToPlaybackTime:playbackTime];
}

+ (NSSet *)keyPathsForValuesAffectingPlaybackTime
{
    return [NSSet setWithObject:@"currentPlayer.playbackTime"];
}

- (BOOL)playing
{
    return [self.currentPlayer playing];
}

+ (NSSet *)keyPathsForValuesAffectingPlaying
{
    return [NSSet setWithObject:@"currentPlayer.playing"];
}

- (NSArray *)tracks
{
    return [self.items valueForKey:@"track"];
}

+ (NSSet *)keyPathsForValuesAffectingTracks
{
    return [NSSet setWithObject:@"items"];
}

- (id<SMKTrack>)currentTrack
{
    return [self.currentPlayer currentTrack];
}

+ (NSSet *)keyPathsForValuesAffectingCurrentTrack
{
    return [NSSet setWithObject:@"currentPlayer.currentTrack"];
}

#pragma mark - Array Accessors

- (NSUInteger)countOfItems
{
    return [self.items count];
}

- (id)objectInItemsIndex:(NSUInteger)index
{
    return [self.items objectAtIndex:index];
}

- (void)insertObject:(id)obj inItemsAtIndex:(NSUInteger)index
{
    [self.items insertObject:obj atIndex:index];
}

- (void)removeObjectFromItemsAtIndex:(NSUInteger)index
{
    [self.items removeObjectAtIndex:index];
}

- (void)replaceObjectInItemsAtIndex:(NSUInteger)index withObject:(id)obj
{
    [self.items replaceObjectAtIndex:index withObject:obj];
}

#pragma mark - Playback

- (IBAction)play:(id)sender
{
    if (!self.currentPlayer && [self.items count]) {
        [self _beginPlayingItemAtIndex:0];
    }
    [self.currentPlayer play];
}

- (IBAction)pause:(id)sender
{
    [self.currentPlayer pause];
}

- (IBAction)playPause:(id)sender
{
    [self playing] ? [self pause:nil] : [self play:nil];
}

- (void)playTrackAtIndex:(NSUInteger)trackIndex
{
    if ((!self.currentPlayer || self.indexOfCurrentTrack != trackIndex) && trackIndex < [self.items count]) {
        [self _beginPlayingItemAtIndex:trackIndex];
    }
    [self.currentPlayer play];
}

- (IBAction)next:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:(NSString *)SMKQueueTransitToNextTrackNotification object:self];

    if ([[self.currentPlayer class] supportsPreloading] && [self.currentPlayer preloadedTrack]) {
        [self.currentPlayer skipToPreloadedTrack];
        self.indexOfCurrentTrack++;
    } else {
        NSUInteger nextTrackIndex = [self _indexOfNextTrack];
        if (nextTrackIndex != NSNotFound) {
            [self _beginPlayingItemAtIndex:nextTrackIndex];
        }
    }
    [self _recalculateIndexOfCurrentTrack];
}

- (IBAction)previous:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:(NSString *)SMKQueueTransitToPreviousTrackNotification object:self];

    NSUInteger previousTrackIndex = [self _indexOfPreviousTrack];
    if (previousTrackIndex != NSNotFound) {
        [self _beginPlayingItemAtIndex:previousTrackIndex];
    }
    [self _recalculateIndexOfCurrentTrack];
}

- (IBAction)seekForward:(id)sender
{
    [self.currentPlayer seekForward];
}

- (IBAction)seekBackward:(id)sender
{
    [self.currentPlayer seekBackward];
}

#pragma mark - Additions for Autoradio Music Player

- (id<SMKTrack>)nextTrack
{
    NSUInteger nextTrackIndex = [self _indexOfNextTrack];
    if (nextTrackIndex == NSNotFound) {
        return nil;
    }
    return [self.tracks objectAtIndex:nextTrackIndex];
}

- (id<SMKTrack>)previousTrack
{
    NSUInteger previousTrackIndex = [self _indexOfPreviousTrack];
    if (previousTrackIndex == NSNotFound) {
        return nil;
    }
    return [self.tracks objectAtIndex:previousTrackIndex];
}

+ (NSSet *)keyPathsForValuesAffectingPreviousTrack
{
    return [NSSet setWithArray:@[@"currentPlayer.currentTrack", @"shuffle", @"repeatMode"]];
}

+ (NSSet *)keyPathsForValuesAffectingNextTrack
{
    return [NSSet setWithArray:@[@"currentPlayer.currentTrack", @"shuffle", @"repeatMode"]];
}

#pragma mark - SMKPlaylist

+ (NSSet *)supportedSortKeys
{
    return [NSSet set];
}

- (id<SMKContentSource>)contentSource
{
    return nil;
}

- (NSString *)name
{
    return NSLocalizedString(@"Queue", @"name of the queue playlist");
}

- (NSString *)uniqueIdentifier
{
    return [self description];
}

- (void)fetchTracksWithCompletionHandler:(void (^)(NSArray *, NSError *))handler
{
    NSArray *itemsToFetch = [NSArray arrayWithArray:self.items];
    NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:[itemsToFetch count]];
    [itemsToFetch enumerateObjectsUsingBlock:^(SMKQueueItem *queueItem, NSUInteger index, BOOL *stop) {
        [tracks addObject:[queueItem track]];
    }];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        handler(tracks, nil);
    });
}

- (BOOL)isEditable
{
    return YES;
}

- (NSString *)extendedDescription
{
    return NSLocalizedString(@"current playback queue", @"extended description of the queue playlist");
}

- (void)moveTracksAtIndexes:(NSIndexSet*)indexes toIndex:(NSUInteger)index completionHandler:(void(^)(NSError *error))handler {
    __block NSError *error = nil;
    NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:[indexes count]];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        if (index < [self.items count]) {
            SMKQueueItem *queueItem = [self.items objectAtIndex:index];
            [tracks addObject:[queueItem track]];
        } else {
            error = [NSError SMK_errorWithCode:SMKQueuePlayerErrorOutOfIndex description:[NSString stringWithFormat:@"Index %d is out of the array of items (%d) in playback queue!", index, [self.items count]]];
            *stop = YES;
        }
    }];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (error) {
            handler(error);
        } else {
            [self moveTracks:tracks toIndex:index completionHandler:handler];
        }
    });
}

- (void)moveTracks:(NSArray*)tracks toIndex:(NSUInteger)index completionHandler:(void(^)(NSError *error))handler {
    if (index >= [self.items count]) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            handler([NSError SMK_errorWithCode:SMKQueuePlayerErrorOutOfIndex
                                   description:[NSString stringWithFormat:@"Index %d is out of queue (count: %d)", index, [self.items count]]]);
        });
        return;
    }
    
    __block id<SMKTrack> previousTrack = [[self.items objectAtIndex:index] track];
    [tracks enumerateObjectsUsingBlock:^(id<SMKTrack> track, NSUInteger index, BOOL *stop) {
        [self removeTrack:track];
        [self insertTrack:track afterTrack:previousTrack];
        previousTrack = track;
    }];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        handler(nil);
    });
}

- (void)addTracks:(NSArray*)tracks atIndex:(NSUInteger)index completionHandler:(void(^)(NSError *error))handler {
    if (index >= [self.items count]) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            handler([NSError SMK_errorWithCode:SMKQueuePlayerErrorOutOfIndex
                                   description:[NSString stringWithFormat:@"Index %d is out of queue (count: %d)", index, [self.items count]]]);
        });
        return;
    }
    
    __block id<SMKTrack> previousTrack = [[self.items objectAtIndex:index] track];
    [tracks enumerateObjectsUsingBlock:^(id<SMKTrack> track, NSUInteger index, BOOL *stop) {
        [self insertTrack:track afterTrack:previousTrack];
        previousTrack = track;
    }];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        handler(nil);
    });
}

- (void)removeTracksAtIndexes:(NSIndexSet *)indexes completionHandler:(void(^)(NSError *error))handler {
    __block NSError *error = nil;
    __block NSMutableArray *tracksToRemove = [NSMutableArray arrayWithCapacity:[indexes count]];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        if (index < [self.items count]) {
            [tracksToRemove addObject:[[self.items objectAtIndex:index] track]];
        } else {
            error = [NSError SMK_errorWithCode:SMKQueuePlayerErrorOutOfIndex
                                   description:[NSString stringWithFormat:@"Index %d is out of queue (count: %d)", index, [self.items count]]];
            tracksToRemove = nil;
            *stop = YES;
        }
    }];
    [tracksToRemove enumerateObjectsUsingBlock:^(id<SMKTrack> track, NSUInteger index, BOOL *stop) {
        [self removeTrack:track];
    }];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        handler(error);
    });
}

#pragma mark - Private

- (NSArray *)_queueItemsForTracks:(NSArray *)tracks
{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:[tracks count]];
    [tracks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SMKQueueItem *item = [SMKQueueItem new];
        item.track = obj;
        [items addObject:item];
    }];
    return items;
}

- (SMKQueueItem *)_queueItemForTrack:(id<SMKTrack>)track
{
    SMKQueueItem *item = [SMKQueueItem new];
    item.track = track;
    return item;
}

- (NSUInteger)_indexOfTrack:(id<SMKTrack>)track
{
    __block NSUInteger index = NSNotFound;
    [self.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj track] isEqual:track]) {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}

- (void)_beginPlayingItemAtIndex:(NSUInteger)index
{
    id<SMKTrack> track = [[self.items objectAtIndex:index] track];
    id<SMKPlayer> player = [[track playerClass] new];
    NSLog(@"now playing %@ with %@", [track name], player);
    self.currentPlayer = player;
    __weak SMKQueueController *weakSelf = self;
    [player playTrack:track completionHandler:^(NSError *error) {
        SMKQueueController *strongSelf = weakSelf;
        if (error) {
            SMKGenericErrorLog([NSString stringWithFormat:@"Error playing track %@", track], error);
            [strongSelf removeObjectFromItemsAtIndex:index];
            strongSelf.currentPlayer = nil;
            if (index < [strongSelf countOfItems])
                [strongSelf _beginPlayingItemAtIndex:index];
        } else {
            [strongSelf _recalculateIndexOfCurrentTrack];
        }
    }];
    [player setFinishedTrackBlock:^(id<SMKPlayer> player, id<SMKTrack> track, NSError *error) {
        SMKQueueController *strongSelf = weakSelf;
        if (self.repeatMode == SMKQueueControllerRepeatModeOne && [player supportsSeeking]) {
            [strongSelf _beginPlayingItemAtIndex:index];
        } else {
            [strongSelf next:nil];
        }
    }];
}

- (void)_recalculateIndexOfCurrentTrack
{
    self.indexOfCurrentTrack = [self _indexOfTrack:self.currentTrack];
}

//
// The following method returns an array of NSNumbers. The NSNumbers represent track indexes. The order of the indexes
// in the array represent the order in which the tracks should get played. This allows shuffling.
//
- (NSArray *)_arrayOfOrderedTrackIndexes
{
    NSUInteger tracksCount = [self.tracks count];
    if (self.shuffle) {
        if (tracksCount == [_shuffledTrackIndexes count]) {
            return _shuffledTrackIndexes;
        }
        _continualTrackIndexes = [NSMutableArray SMK_arrayWithNumbersCountingTo:tracksCount];
        _shuffledTrackIndexes = [_continualTrackIndexes sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            // we abuse the sorter by just returning random values, this shuffles the ordered list
            switch (arc4random_uniform(3)) {
                case 0:
                    return NSOrderedAscending;
                case 1:
                    return NSOrderedDescending;
                default:
                    return NSOrderedSame;
            }
        }];
        return _shuffledTrackIndexes;
    } else {
        if (tracksCount == [_continualTrackIndexes count]) {
            return _continualTrackIndexes;
        }
        _continualTrackIndexes = [NSMutableArray SMK_arrayWithNumbersCountingTo:tracksCount];
        return _continualTrackIndexes;
    }
}

- (NSUInteger)_indexOfNextTrack
{
    NSArray *orderedTrackIndexes = [self _arrayOfOrderedTrackIndexes];
    NSUInteger indexInOrderedArray = [orderedTrackIndexes indexOfObject:[NSNumber numberWithUnsignedInteger:self.indexOfCurrentTrack]];
    NSUInteger nextIndexInOrderedArray = indexInOrderedArray + 1;
    if (self.repeatMode == SMKQueueControllerRepeatModeAll) {
        while (nextIndexInOrderedArray >= [orderedTrackIndexes count]) nextIndexInOrderedArray -= [orderedTrackIndexes count];
    }
    if (nextIndexInOrderedArray < [orderedTrackIndexes count]) {
        return [[orderedTrackIndexes objectAtIndex:nextIndexInOrderedArray] unsignedIntegerValue];
    } else {
        return NSNotFound;
    }
}

- (NSUInteger)_indexOfPreviousTrack
{
    NSArray *orderedTrackIndexes = [self _arrayOfOrderedTrackIndexes];
    NSUInteger indexInOrderedArray = [orderedTrackIndexes indexOfObject:[NSNumber numberWithUnsignedInteger:self.indexOfCurrentTrack]];
    if ((self.repeatMode == SMKQueueControllerRepeatModeAll) && indexInOrderedArray == 0) {
        indexInOrderedArray = [orderedTrackIndexes count];
    }
    if (indexInOrderedArray > 0) {
        return [[orderedTrackIndexes objectAtIndex:(indexInOrderedArray - 1)] unsignedIntegerValue];
    } else {
        return NSNotFound;
    }
    
}
@end

@implementation SMKQueueItem
@end
