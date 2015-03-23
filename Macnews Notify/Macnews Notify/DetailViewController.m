//
//  DetailViewController.m
//  Macnews Notify
//
//  Created by mtjddnr on 2015. 3. 6..
//  Copyright (c) 2015년 mtjddnr. All rights reserved.
//

#import "DetailViewController.h"
#import "TUSafariActivity.h"
#import <MacnewsCore/MacnewsCore.h>

@interface DetailViewController () 
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation DetailViewController {
    CGPoint _tapPoint;
    UIRefreshControl *_refreshControl;
    NSURL *_urlToPush;
}

#pragma mark - Managing the detail item
- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
            
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    NSURL *url = nil;
    if (self.detailItem) {
        //self.detailDescriptionLabel.text = [[self.detailItem valueForKey:@"timeStamp"] description];
        
        url = [[DataStore sharedData] urlWithArticle:self.detailItem];
    } else if (self.url != nil) {
        url = self.url;
    } else {
        url = [NSURL URLWithString:@"http://macnews.tistory.com/m/"];
    }
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    [_refreshControl beginRefreshing];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UITapGestureRecognizer *webViewTapped = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction:)];
    webViewTapped.numberOfTapsRequired = 1;
    webViewTapped.delegate = self;
    [self.webView addGestureRecognizer:webViewTapped];
    
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(onRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.webView.scrollView addSubview:_refreshControl];
    
    [self configureView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.navigationItem.rightBarButtonItem.enabled = ![webView.request.URL.absoluteString isEqualToString:@""];
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.navigationItem.rightBarButtonItem.enabled = ![webView.request.URL.absoluteString isEqualToString:@""];
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    [_refreshControl endRefreshing];
}

- (void)onHome {
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://macnews.tistory.com/m/"]]];
}

- (void)onRefresh:(UIRefreshControl *)refresh {
    [self.webView reload];
}

- (IBAction)onAction:(id)sender {
    NSURL *url = self.webView.request.URL;
    if ([url.absoluteString isEqualToString:@""]) return;
    
    TUSafariActivity *activity = [[TUSafariActivity alloc] init];
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[ url ] applicationActivities:@[ activity ]];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self presentViewController:activityController animated:YES completion:nil];
    } else {
        UIPopoverController *popup = [[UIPopoverController alloc] initWithContentViewController:activityController];
        [popup presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)tapAction:(UITapGestureRecognizer *)event {
    _tapPoint = [event locationInView:self.webView];
}

/*
 http://stackoverflow.com/questions/1781427/what-is-mt-8-in-itunes-links-for-the-appstore
 1   Music
 2   Podcasts
 3   Audiobooks
 4   TV Shows
 5   Music Videos
 6   Movies
 7   iPod Games
 8   Mobile Software Applications
 9   Ringtones
 10  iTunes U
 11  E-Books
 12  Desktop Apps
 */

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = [request URL];
    if ([[url host] isEqualToString:@"itunes.apple.com"]) {
        if ([[[url query] componentsSeparatedByString:@"&"] containsObject:@"mt=12"]) {
            NSString *macURL = [NSString stringWithFormat:@"macappstore%@", [url.absoluteString substringFromIndex:5]];
            TUSafariActivity *activity = [[TUSafariActivity alloc] init];
            UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[ [NSURL URLWithString:macURL] ] applicationActivities:@[ activity ]];
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                [self presentViewController:activityController animated:YES completion:nil];
            } else {
                UIPopoverController *popup = [[UIPopoverController alloc] initWithContentViewController:activityController];
                [popup presentPopoverFromRect:CGRectMake(_tapPoint.x, _tapPoint.y, 0, 0) inView:self.webView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
            return NO;
        }
    } else if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        _urlToPush = url;
        [self performSegueWithIdentifier:@"link" sender:self];
        return NO;
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"link"]) {
        DetailViewController *controller = (DetailViewController *)[segue destinationViewController];
        controller.url = _urlToPush;
        _urlToPush = nil;
    } else if ([segue.identifier isEqualToString:@"notification"]) {
        DetailViewController *controller = (DetailViewController *)[segue destinationViewController];
        
        [controller setDetailItem:nil];
        NSDictionary *item = sender;
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:[[DataStore sharedData] hostWithWebId:item[@"webId"]][@"url"], item[@"arg"]]];
            
        [controller setUrl:url];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

@end
