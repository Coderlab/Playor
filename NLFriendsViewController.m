//
//  NLFriendsViewController.m
//  Noctis
//
//  Created by Nick Lauer on 12-07-21.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NLFriendsViewController.h"

#import "NLFacebookManager.h"
#import "NLFBLoginViewController.h"
#import "NLFacebookFriend.h"
#import "FXImageView.h"
#import "NLFriendsDetailViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "NLPlaylistBarViewController.h"
#import "NLUtils.h"

@interface NLFriendsViewController ()
@property (strong, nonatomic) iCarousel *iCarousel;
@property (strong, nonatomic) NSArray *facebookFriends;
@property (strong, nonatomic) NSArray *carouselArray;
@end

@implementation NLFriendsViewController {
    BOOL shouldBeginEditing_;
}
@synthesize iCarousel = _iCarousel, facebookFriends = _facebookFriends, carouselArray = _carouselArray;

- (void)viewDidLoad
{
    [super viewDidLoad];
    shouldBeginEditing_ = YES;
    [self.view setClipsToBounds:YES];
    [self.view setFrame:[NLUtils getContainerTopControllerFrame]];
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width- 100, 44.0)];
    [searchBar setBarStyle:UIBarStyleBlack];
    [searchBar setPlaceholder:@"Search for friends"];
    [searchBar setDelegate:self];
    [self.navigationItem setTitleView:searchBar];
    
    if ([[NLFacebookManager sharedInstance] isSignedInWithFacebook]) {
        [[NLFacebookManager sharedInstance] performBlockAfterFBLogin:^{
            [[NLFacebookFriendFactory sharedInstance] createFacebookFriendsWithDelegate:self];
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (![[NLFacebookManager sharedInstance] isSignedInWithFacebook]) {
        NLFBLoginViewController *loginViewController = [[NLFBLoginViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginViewController];
        [nav.navigationBar setBarStyle:UIBarStyleBlack];
        [[NLPlaylistBarViewController sharedInstance] presentViewController:nav animated:YES completion:nil];
    }
}

- (void)setupICarousel
{
    if (!_iCarousel) {
        iCarousel *carousel = [[iCarousel alloc] initWithFrame:CGRectMake(0, 10.0f + 10.0, self.view.frame.size.width, 170)];
        [carousel setType:iCarouselTypeLinear];
        [carousel setDataSource:self];
        [carousel setDelegate:self];
        [self setICarousel:carousel];
        [self.view addSubview:carousel];
    } else {
        [_iCarousel reloadData];
    }
}

- (NSString *)friendNameForIndex:(NSUInteger)index
{
    return [((NLFacebookFriend *)[_carouselArray objectAtIndex:index]) name];
}

#pragma mark -
#pragma mark iCarousel methods

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return [_carouselArray count];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    UILabel *nameLabel = nil;
    FXImageView *profileImageView = nil;
    
    if (view == nil) {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 170.0f, 170.0f)];
        [view setBackgroundColor:[UIColor blackColor]];
        
        profileImageView = [[FXImageView alloc] initWithFrame:view.frame];
        [profileImageView setContentMode:UIViewContentModeScaleAspectFill];
        [profileImageView setTag:2];
        [profileImageView setAsynchronous:YES];
        [profileImageView setReflectionAlpha:0.5];
        [profileImageView setReflectionGap:0];
        [profileImageView setReflectionScale:0.4];
        [view addSubview:profileImageView];
        
        nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 170, view.frame.size.width, 30)];
        [nameLabel setTextAlignment:UITextAlignmentCenter];
        [nameLabel setBackgroundColor:[UIColor clearColor]];
        [nameLabel setTag:1];
        [nameLabel setTextColor:[UIColor blackColor]];
        [view addSubview:nameLabel];
        
        UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeFriendView:)];
        [swipeRecognizer setDirection:UISwipeGestureRecognizerDirectionDown];
        [view addGestureRecognizer:swipeRecognizer];
        
    } else {
        nameLabel = (UILabel *)[view viewWithTag:1];
        profileImageView = (FXImageView *)[view viewWithTag:2];
    }
    
    [nameLabel setText:[self friendNameForIndex:index]];
    [nameLabel setCenter:CGPointMake(floorf(view.frame.size.width/2), view.frame.size.height + 20)];
    
    [profileImageView setImage:nil];
    [profileImageView setImageWithContentsOfURL:[[_carouselArray objectAtIndex:index] profilePictureURL]];
    
    return view;
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index
{
    NLFriendsDetailViewController *friendsDetailViewController = [[NLFriendsDetailViewController alloc] initWithFacebookFriend:[_carouselArray objectAtIndex:index]];
    [self.navigationController pushViewController:friendsDetailViewController animated:YES];
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
            return value * 1.1f;
        }
        default:
        {
            return value;
        }
    }
}

#pragma mark -
#pragma mark FacebookFriendDelegate
- (void)receiveFacebookFriends:(NSArray *)friends
{
    self.facebookFriends = [friends sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    self.carouselArray = _facebookFriends;
    [self setupICarousel];
}

#pragma mark -
#pragma mark UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (![searchBar isFirstResponder]) {
        shouldBeginEditing_ = NO;
        
        _carouselArray = _facebookFriends;
        
        [_iCarousel setCurrentItemIndex:0];
        [_iCarousel reloadData];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    if (_carouselArray != _facebookFriends) {
        _carouselArray = _facebookFriends;
        
        [searchBar setText:@""];
        
        [_iCarousel setCurrentItemIndex:0];
        [_iCarousel reloadData];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    if ([searchBar.text isEqualToString:@""]) {
        _carouselArray = _facebookFriends;
    } else {
        _carouselArray = [_facebookFriends filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K contains[cd] %@", @"name", searchBar.text]];
    }
    [_iCarousel reloadData];
    [_iCarousel setCurrentItemIndex:0];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES animated:NO];
    [UIView animateWithDuration:0.3 animations:^{
        [searchBar setFrame:CGRectMake(searchBar.frame.origin.x, searchBar.frame.origin.y, searchBar.frame.size.width+100, searchBar.frame.size.height)];
    }];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:NO];
    [UIView animateWithDuration:0.3 animations:^{
        [searchBar setFrame:CGRectMake(searchBar.frame.origin.x, searchBar.frame.origin.y, searchBar.frame.size.width-100, searchBar.frame.size.height)];
    }];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    BOOL boolToReturn = shouldBeginEditing_;
    shouldBeginEditing_ = YES;
    return boolToReturn;
}

#pragma mark -
#pragma mark Panning and Playlist Methods
- (void)swipeFriendView:(UISwipeGestureRecognizer *)swipeRecognizer
{
    [self.view setUserInteractionEnabled:NO];
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationCurveEaseOut animations:^{
        [swipeRecognizer.view setCenter:CGPointMake(swipeRecognizer.view.center.x, 170/2 + 220)];
        [swipeRecognizer.view setTransform:CGAffineTransformMakeScale(0.3, 0.3)];
        [[swipeRecognizer.view viewWithTag:1] setHidden:YES];
    } completion:^(BOOL finished) {
        [self addFriendToPlaylistFromCarouselForView:swipeRecognizer.view];
        [UIView animateWithDuration:0.2 animations:^{
            [swipeRecognizer.view setCenter:CGPointMake(swipeRecognizer.view.center.x, 170/2)];
            [swipeRecognizer.view setTransform:CGAffineTransformMakeScale(1.0, 1.0)];
            [[swipeRecognizer.view viewWithTag:1] setHidden:NO];
            [self.view setUserInteractionEnabled:YES];
        }];
    }];
}

- (void)addFriendToPlaylistFromCarouselForView:(UIView *)view
{
    int index = [_iCarousel indexOfItemView:view];
    NLFacebookFriend *facebookFriend = [_carouselArray objectAtIndex:index];
    [[NLPlaylistBarViewController sharedInstance] receiveFacebookFriend:facebookFriend];
}

@end
