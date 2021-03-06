//
//  NLYoutubeVideo.m
//  Noctis
//
//  Created by Nick Lauer on 12-07-22.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NLYoutubeVideo.h"

@implementation NLYoutubeVideo
@synthesize youtubeID = _youtubeID, thumbnailURL = _thumbnailURL, title = _title, addedDate = _addedDate;

- (id)initWithDataDictionary:(NSDictionary *)dataDictionary
{
    self = [super init];
    if (self) {
        if (![self isPlayableOnMobile:dataDictionary]) {
            return nil;
        } else {
            self.title = [self getVideoTitleFromDictionary:dataDictionary];
            self.youtubeID = [self getYoutubeIDFromDictionary:dataDictionary];
            self.thumbnailURL = [self getVideoThumnailURLFromDictionary:dataDictionary];
        }
    }
    
    return self;
}

#pragma mark -
#pragma mark DataDictionary

+ (BOOL)isMusicLinkForDataDictionary:(NSDictionary *)dataDictonary
{
    return [((NSString *)[[[[dataDictonary objectForKey:@"media$group"] objectForKey:@"media$category"] objectAtIndex:0] objectForKey:@"label"]) isEqualToString:@"Music"];
}

- (BOOL)isPlayableOnMobile:(NSDictionary *)dataDictionary
{
    NSString *syndicate = [[[dataDictionary objectForKey:@"yt$accessControl"] objectAtIndex:7] objectForKey:@"permission"];
    return [syndicate isEqualToString:@"denied"] ? NO : YES;
}

- (BOOL)isRestrictedForPlaybackForDataDictionary:(NSDictionary *)dataDictionary
{
    return [[dataDictionary objectForKey:@"media$group"] objectForKey:@"media$restriction"] ? YES : NO;
}

- (NSString *)getVideoCategoryFromDictionary:(NSDictionary *)dataDictionary
{
    NSString *category = [[[[dataDictionary objectForKey:@"media$group"] objectForKey:@"media$category"] objectAtIndex:0] objectForKey:@"label"];
    return category;
}

- (NSString *)getVideoTitleFromDictionary:(NSDictionary *)dataDictionary
{
    NSString *title = [[[dataDictionary objectForKey:@"media$group"] objectForKey:@"media$title"] objectForKey:@"$t"];
    return title;
}

- (NSString *)getYoutubeIDFromDictionary:(NSDictionary *)dataDictionary
{
    NSString *youtubeID = [[[dataDictionary objectForKey:@"media$group"] objectForKey:@"yt$videoid"] objectForKey:@"$t"];
    return youtubeID;
}

- (NSURL *)getVideoThumnailURLFromDictionary:(NSDictionary *)dataDictionary
{
    NSString *thumbnailString = [[[[dataDictionary objectForKey:@"media$group"] objectForKey:@"media$thumbnail"] objectAtIndex:2] objectForKey:@"url"];
    return [NSURL URLWithString:thumbnailString];
}

#pragma mark -
#pragma mark PlaylistItemDelegate
- (NSURL *)getPictureURL
{
    return self.thumbnailURL;
}

#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _thumbnailURL = [aDecoder decodeObjectForKey:@"thumbnailURL"];
        _title = [aDecoder decodeObjectForKey:@"title"];
        _youtubeID = [aDecoder decodeObjectForKey:@"youtubeID"];
        _addedDate = [aDecoder decodeObjectForKey:@"addedDate"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_thumbnailURL forKey:@"thumbnailURL"];
    [aCoder encodeObject:_title forKey:@"title"];
    [aCoder encodeObject:_youtubeID forKey:@"youtubeID"];
    [aCoder encodeObject:_addedDate forKey:@"addedDate"];
}

@end
