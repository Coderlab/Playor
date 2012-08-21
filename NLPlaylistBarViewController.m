//
//  NLPlaylistBarViewController.m
//  Noctis
//
//  Created by Nick Lauer on 12-07-25.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NLPlaylistBarViewController.h"

#import "NLFacebookFriend.h"
#import "NLYoutubeVideo.h"
#import "FXImageView.h"
#import "NLPlaylistEditorViewController.h"
#import "NLAppDelegate.h"
#import "NLPlaylist.h"
#import "NLPlaylistManager.h"
#import "NSArray+Videos.h"
#import <MediaPlayer/MediaPlayer.h>
#import "NLAppDelegate.h"
#import "NLContainerViewController.h"
#import "NLAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+NLColors.h"

@interface NLPlaylistBarViewController ()
@property (strong, nonatomic) iCarousel *iCarousel;
@property (strong, nonatomic) NLPlaylist *playlist;
@property (strong, nonatomic) UIWebView *videoWebView;
@end

@implementation NLPlaylistBarViewController {
    BOOL isShowingEditor_;
    UILabel *playlistTitleLabel_;
    UIBackgroundTaskIdentifier bgTask;
}
@synthesize iCarousel = _iCarousel, playlist = _playlist, videoWebView = _videoWebView;

static NLPlaylistBarViewController *sharedInstance = NULL;

+ (NLPlaylistBarViewController *)sharedInstance
{
    @synchronized(self) {
        if (sharedInstance == NULL) {
            sharedInstance = [[NLPlaylistBarViewController alloc] init];
        }
    }
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _playlist = [[NLPlaylistManager sharedInstance] getCurrentPlaylist];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    isShowingEditor_ = NO;
	[self.view setFrame:CGRectMake(0, 0, self.view.frame.size.width, 128)];
    [self.view setBackgroundColor:[UIColor playlistBarBackgroundColor]];
    
    UIView *playlistTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 20 - 64)];
    CAGradientLayer *topShadow = [CAGradientLayer layer];
    topShadow.frame = CGRectMake(0, 0, playlistTitleView.frame.size.width, 44);
    topShadow.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:0.9 alpha:0.4f] CGColor], (id)[[UIColor clearColor] CGColor], nil];
    [playlistTitleView.layer insertSublayer:topShadow atIndex:0];
    [playlistTitleView setBackgroundColor:[UIColor blackColor]];
    [self.view addSubview:playlistTitleView];
    
    playlistTitleLabel_ = [[UILabel alloc] init];
    [playlistTitleLabel_ setBackgroundColor:[UIColor clearColor]];
    [playlistTitleLabel_ setText:_playlist.name];
    [playlistTitleLabel_ setFont:[UIFont boldSystemFontOfSize:16]];
    [playlistTitleLabel_ setTextColor:[UIColor whiteColor]];
    [playlistTitleLabel_ sizeToFit];
    [playlistTitleLabel_ setFrame:CGRectMake(10, playlistTitleView.frame.size.height/2 - playlistTitleLabel_.frame.size.height/2, playlistTitleView.frame.size.width - 44 - 10, playlistTitleLabel_.frame.size.height)];
    [playlistTitleView addSubview:playlistTitleLabel_];
    
    UIButton *playlistEditorButton = [[UIButton alloc] initWithFrame:CGRectMake(playlistTitleView.frame.size.width - 44, 0, 44, 44)];
    [playlistEditorButton setBackgroundColor:[UIColor darkGrayColor]];
    [playlistEditorButton addTarget:self action:@selector(togglePlaylistEditor) forControlEvents:UIControlEventTouchUpInside];
    [playlistTitleView addSubview:playlistEditorButton];
    
    UIButton *stopLoadingVideoButton = [[UIButton alloc] initWithFrame:CGRectMake(playlistTitleView.frame.size.width - 88, 0, 44, 44)];
    [stopLoadingVideoButton setBackgroundColor:[UIColor blackColor]];
    [stopLoadingVideoButton addTarget:self action:@selector(stopLoadingCurrentVideo) forControlEvents:UIControlEventTouchUpInside];
    [playlistTitleView addSubview:stopLoadingVideoButton];
    
    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 40, 40)];
    [infoLabel setBackgroundColor:[UIColor clearColor]];
    [infoLabel setText:@"Swipe right on songs to add to playlist, swipe up on playlist items to remove"];
    [infoLabel setTextAlignment:UITextAlignmentCenter];
    [infoLabel setNumberOfLines:2];
    [infoLabel setLineBreakMode:UILineBreakModeWordWrap];
    [infoLabel setFont:[UIFont systemFontOfSize:14]];
    [infoLabel setTextColor:[UIColor whiteColor]];
    [infoLabel setTag:69];
    [infoLabel setCenter:CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height - 10 - 32)];
    [self.view addSubview:infoLabel];
    
    if ([_playlist.videos count] > 0) {
        [infoLabel setHidden:YES];
    }
    iCarousel *carousel = [[iCarousel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 64 - 10, self.view.frame.size.width, 64)];
    [carousel setType:iCarouselTypeLinear];
    [carousel setDataSource:self];
    [carousel setDelegate:self];
    [carousel setContentOffset:CGSizeMake(0, 0)];
    [self setICarousel:carousel];
    [self.view addSubview:carousel];
    
    _videoWebView = [[UIWebView alloc] initWithFrame:CGRectMake(-1, -1, 1, 1)];
    [_videoWebView setDelegate:self];
    [_videoWebView setMediaPlaybackRequiresUserAction:NO];
    [self.view addSubview:_videoWebView];
}

- (void)togglePlaylistEditor
{
    if (!isShowingEditor_) {
        NLPlaylistEditorViewController *playlistEditor = [[NLPlaylistEditorViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:playlistEditor];
        [[((NLAppDelegate *)[[UIApplication sharedApplication] delegate]) containerController] presentViewControllerBehindPlaylistBar:nav];
    } else {
        [[((NLAppDelegate *)[[UIApplication sharedApplication] delegate]) containerController] dismissPresentedViewControllerBehindPlaylistBar];
    }
    isShowingEditor_ = !isShowingEditor_;
}

- (void)updateICarousel
{
    [_iCarousel insertItemAtIndex:[_playlist.videos count]-1 animated:YES];
}

- (void)updatePlaylist:(NLPlaylist *)playlist
{
    if (playlist != _playlist) {
        _playlist = playlist;
        [[self.view viewWithTag:69] setHidden:([_playlist.videos count] > 0) ? YES : NO];
        [_iCarousel reloadData];
        [playlistTitleLabel_ setText:playlist.name];
    }
    [_iCarousel scrollToItemAtIndex:0 animated:NO];
}

#pragma mark -
#pragma mark BackgroundPlayMethods

- (void)prepareForBackgroundPlay
{
    // Watch for remote events to keep getting notifications
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(beginReceivingRemoteControlEvents)]){
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        [self becomeFirstResponder];
    }
    
    // Remove other watchers, and only watch for the necessary background events
    NSNotificationCenter *notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter removeObserver:self];
    [notifyCenter addObserver:self selector:@selector(playNextVideoInBackground) name:@"UIMoviePlayerControllerDidExitFullscreenNotification" object:nil];
    
    // The audio gets paused when entering background state, this restarts it
    [self resumeAudio];
}

- (void)endBackgroundPlay
{
    // Kill the background task if it was still running
    UIApplication *app = [UIApplication sharedApplication];
    if (bgTask != UIBackgroundTaskInvalid) {
        [app endBackgroundTask:bgTask]; 
        bgTask = UIBackgroundTaskInvalid;
    }
    
    // Stop watching for remote events
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(endReceivingRemoteControlEvents)]){
        [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
        [self resignFirstResponder];
    }
    
    // Remove the background observers and re-add the foreground playlist observer
    NSNotificationCenter *notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter removeObserver:self];
    [notifyCenter addObserver:self selector:@selector(videoDidExitFullscreen:) name:@"UIMoviePlayerControllerDidExitFullscreenNotification" object:nil];
}

// Start playing next video with a background task
- (void)playNextVideoInBackground
{
    UIApplication *app = [UIApplication sharedApplication];
    if (bgTask != UIBackgroundTaskInvalid) {
        [app endBackgroundTask:bgTask]; 
        bgTask = UIBackgroundTaskInvalid;
    }
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{ 
        [app endBackgroundTask:bgTask]; 
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self videoDidExitFullscreen:nil];
    });
}

// Resumes the audio when it got stopped
- (void)resumeAudio
{
    UIButton *b = [self findButtonInView:_videoWebView];
    [b sendActionsForControlEvents:UIControlEventTouchUpInside];
}

// Necessary to receive remote events
- (BOOL)canBecomeFirstResponder {
    return YES;
}

#pragma mark Playing Videos

- (void)stopLoadingCurrentVideo
{
    [_videoWebView stopLoading];
}

- (void)loadNewVideoWithIndex:(int)index
{
    [_iCarousel scrollToItemAtIndex:index animated:YES];
    [_videoWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://m.youtube.com/watch?v=%@", [[_playlist.videos objectAtIndex:index] youtubeID]]]]];
}

- (void)videoDidExitFullscreen:(NSNotification *)note
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    int index = [_iCarousel currentItemIndex] + 1;
    if (index < [_playlist.videos count]) {
        [self loadNewVideoWithIndex:index];
    }
}

#pragma mark -
#pragma mark iCarousel methods
- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return [_playlist.videos count];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    FXImageView *imageView = nil;
    
    if (view == nil) {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 64)];
        [view setBackgroundColor:[UIColor blackColor]];
        [view setUserInteractionEnabled:YES];
        [view.layer setBorderWidth:3.0];
        [view.layer setBorderColor:[[UIColor grayColor] CGColor]];
        
        imageView = [[FXImageView alloc] initWithFrame:view.bounds];
        [imageView setAsynchronous:YES];
        [imageView setContentMode:UIViewContentModeScaleAspectFill];
        [imageView setTag:2];
        [view addSubview:imageView];
        
        UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(deletePlaylistItem:)];
        [swipeRecognizer setDirection:UISwipeGestureRecognizerDirectionUp];
        [view addGestureRecognizer:swipeRecognizer];
    } else {
        imageView = (FXImageView *)[view viewWithTag:2];
    }
    
    [imageView setImage:nil];
    [imageView setImageWithContentsOfURL:[[_playlist.videos objectAtIndex:index] getPictureURL]];
    [view setUserInteractionEnabled:YES];
    
    return view;
}

- (CGFloat)carousel:(iCarousel *)_carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    //customize carousel display
    switch (option)
    {
        case iCarouselOptionWrap:
        {
            return NO;
        }
        case iCarouselOptionSpacing:
        {
            //add a bit of spacing between the item views
            return value*1.05;
        }
        default:
        {
            return value;
        }
    }
}

- (UIView *)carousel:(iCarousel *)carousel placeholderViewAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    return nil;
}

- (void)carouselDidScroll:(iCarousel *)carousel
{
    for (UIView *view in [carousel visibleItemViews]) {
        [view setUserInteractionEnabled:YES];
    }
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index
{
    [self loadNewVideoWithIndex:index];
}

#pragma mark -
#pragma mark YoutubeLinksFromFBLikesDelegate

- (void)receiveYoutubeLinksFromFBLikes:(NSArray *)links
{
    for (NLYoutubeVideo *video in links) {
        [self receiveYoutubeVideo:video];
    }
}

#pragma mark -
#pragma mark Receiving and Deleting Methods

- (void)receiveFacebookFriend:(NLFacebookFriend *)facebookFriend
{
    [[NLYoutubeLinksFromFBLikesFactory sharedInstance] createYoutubeLinksForFriendID:facebookFriend.ID andDelegate:self];
    //Need to get the shared videos here too
}

- (void)receiveYoutubeVideo:(NLYoutubeVideo *)video
{
    [[self.view viewWithTag:69] setHidden:YES];
    if (![_playlist.videos containsVideo:video]) {
        [_playlist.videos addObject:video];
        [self updateICarousel];
        [_iCarousel scrollToItemAtIndex:[_playlist.videos count] - 1 animated:YES];
    } else {
        int index = [_playlist.videos indexOfVideo:video];
        [_iCarousel scrollToItemAtIndex:index animated:YES];
    }
}

- (void)deletePlaylistItem:(UISwipeGestureRecognizer *)swipeRecognizer
{
    [self.view setUserInteractionEnabled:NO];
    UIView *playlistItemView = swipeRecognizer.view;
    [UIView animateWithDuration:0.3 animations:^{
        [playlistItemView setCenter:CGPointMake(playlistItemView.center.x, playlistItemView.center.y - playlistItemView.frame.size.height - 30)];
    } completion:^(BOOL finished) {
        [self.view setUserInteractionEnabled:YES];
        int index = [_iCarousel indexOfItemView:playlistItemView];
        [_playlist.videos removeObjectAtIndex:index];
        [_iCarousel removeItemAtIndex:index animated:YES];
    }];
}

#pragma mark -
#pragma mark UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    UIButton *b = [self findButtonInView:_videoWebView];
    [b sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    NSNotificationCenter *notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver:self selector:@selector(videoDidExitFullscreen:) name:@"UIMoviePlayerControllerDidExitFullscreenNotification" object:nil];
}

- (UIButton *)findButtonInView:(UIView *)view {
	UIButton *button = nil;
    
	if ([view isMemberOfClass:[UIButton class]]) {
		return (UIButton *)view;
	}
    
	if (view.subviews && [view.subviews count] > 0) {
		for (UIView *subview in view.subviews) {
			button = [self findButtonInView:subview];
			if (button) return button;
		}
	}
    
	return button;
}

@end
