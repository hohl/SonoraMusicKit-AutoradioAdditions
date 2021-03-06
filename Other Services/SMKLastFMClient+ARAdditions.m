//
//  SMKLastFMClient+HTAdditions.m
//  Autoradio
//
//  Created by Michael Hohl on 09.10.12.
//  Copyright (c) 2012 Michael Hohl. All rights reserved.
//

#import "SMKLastFMClient+ARAdditions.h"

@implementation SMKLastFMClient (ARAdditions)

- (void)retrieveChart:(SMKChartType)chartType
                limit:(NSUInteger)limit
    completionHandler:(void (^)(NSDictionary *, NSError *))handler
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"method"] = chartType;
    parameters[@"lang"] = @(limit);
    [self getPath:nil parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (handler) handler(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (handler) handler(nil, error);
    }];
}

- (void)retrieveInfoForArtist:(NSString *)artistName completionHandler:(void (^)(NSDictionary *, NSError *))handler
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"method"] = @"artist.getInfo";
    parameters[@"artist"] = artistName;
    parameters[@"limit"] = self.languageCode;
    [self getPath:nil parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (handler) handler(responseObject, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (handler) handler(nil, error);
    }];
}

@end
