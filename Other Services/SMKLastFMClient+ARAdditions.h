//
//  SMKLastFMClient+HTAdditions.h
//  Autoradio
//
//  Created by Michael Hohl on 09.10.12.
//  Copyright (c) 2012 Michael Hohl. All rights reserved.
//

#import "SMKLastFMClient.h"

typedef NSString* SMKChartType;
static const SMKChartType SMKChartHypedArtists = @"chart.getHypedArtists";
static const SMKChartType SMKChartHypedTracks = @"chart.getHypedTracks";
static const SMKChartType SMKChartTopArtists = @"chart.getTopArtists";
static const SMKChartType SMKChartTopTracks = @"chart.getTopTracks";

@interface SMKLastFMClient (ARAdditions)

/**
 Retrieves a chart list.
 @param chartType defines which chart to retrieve
 @param limit maximum number of responses
 @param handler a completion handler block
 */
- (void)retrieveChart:(SMKChartType)chartType
                limit:(NSUInteger)limit
    completionHandler:(void (^)(NSDictionary *response, NSError *error))handler;

/**
 Retrieves an info for the artist of the passed name.
 @param artistName the name of the artist to retrieve
 @param handler a completion handler block
 */
- (void)retrieveInfoForArtist:(NSString *)artistName
            completionHandler:(void (^)(NSDictionary *response, NSError *error))handler;


@end
