//
//  ViewController.m
//  BlocBrowser
//
//  Created by Ryan Walker on 10/1/15.
//  Copyright © 2015 Ryan Walker. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "AwesomeFloatingToolbar.h"

#define kWebBrowserBackString NSLocalizedString(@"Back", "Back Command")
#define kWebBrowserForwardString NSLocalizedString(@"Forward", "Forward Command")
#define kWebBrowserStopString NSLocalizedString(@"Stop", "Stop Command")
#define kWebBrowserReloadString NSLocalizedString(@"Reload", "Reload Command")

@interface ViewController () <WKNavigationDelegate, UITextFieldDelegate, AwesomeFloatingToolbarDelegate>

@property (strong, nonatomic) WKWebView *webView;
@property (strong, nonatomic) NSData *webData;
@property (strong, nonatomic) UITextField *textField;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) AwesomeFloatingToolbar *awesomeToolbar;
@property (assign, nonatomic) NSUInteger frameCount; //where did this come from?

@end

#pragma mark - UIViewController

@implementation ViewController

- (void)loadView {
    UIView *mainView = [UIView new];
    
    //create webview
    self.webView = [[WKWebView alloc] init];
    self.webView.navigationDelegate = self;
    
    //create text field
    self.textField = [[UITextField alloc] init];
    self.textField.keyboardType = UIKeyboardTypeURL;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.placeholder = NSLocalizedString(@"Search or Website URL", @"Placeholder text for web browser URL field");
    self.textField.backgroundColor = [UIColor colorWithWhite:220/255.0f alpha:1];
    self.textField.delegate = self;
    
    //create buttons at end of page
    self.awesomeToolbar = [[AwesomeFloatingToolbar alloc] initWithFourTitles:@[kWebBrowserBackString, kWebBrowserForwardString, kWebBrowserReloadString, kWebBrowserStopString]];
    self.awesomeToolbar.delegate = self;
    
    //load all of the views as subview
    for (UIView *viewToAdd in @[self.webView, self.textField, self.awesomeToolbar]) {
        [mainView addSubview:viewToAdd];
    }
    
    self.view = mainView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    static const CGFloat itemHeight = 50;
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat browserHeight = CGRectGetHeight(self.view.bounds) - ( itemHeight );
    
    self.textField.frame = CGRectMake(0, 0, width, itemHeight);
    self.webView.frame = CGRectMake(0, CGRectGetMaxY(self.textField.frame), width, browserHeight);
    
    self.awesomeToolbar.frame = CGRectMake( width / 4 , ( 20 + browserHeight / 10 ) , width / 2 , browserHeight / 5 );
    
    NSLog(@"the loading size is: %@", NSStringFromCGRect(self.awesomeToolbar.frame));
    
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    NSString *URLString;
    
    NSString *userString = textField.text;
    NSRange spaceRange  = [userString rangeOfString:@" "];
    NSRange periodRange = [userString rangeOfString:@"."];
    
    if ( spaceRange.location == NSNotFound ) {
        if ( periodRange.location == NSNotFound ) {
            URLString = [self wrapAndEncodeGoogleQueryToString:userString];
        } else {
            URLString = userString;
        }
    } else {
        
        URLString = [self wrapAndEncodeGoogleQueryToString:userString];
    }
    
    
    NSURL *URL= [NSURL URLWithString:URLString];
    NSString *correctURLScheme = @"https";
    
    if ( ![URL.scheme isEqualToString: correctURLScheme]) {
        if ( [URL.scheme isEqualToString:@"http"] ) {
            
            NSRange locationOfNonSecureURL = [URLString rangeOfString:@"http"];
            URLString = [URLString stringByReplacingCharactersInRange:locationOfNonSecureURL withString:correctURLScheme];
            URL = [NSURL URLWithString:URLString];
            
        } else {
            
            URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", correctURLScheme, URLString]];
            
        }
    }
    
    if (URL) {
        [self loadWebDataWithSession: URL];
    }
    
    return NO;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self updateButtonsAndTitle];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self updateButtonsAndTitle];
}

- (void) webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    
    [self webView:webView didFailProvisionalNavigation:navigation withError:error];
    
}

- (void) webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    
    if (error.code != NSURLErrorCancelled) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error")
                                                                       message:[error localizedDescription]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
        
        [alert addAction:okAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        [self updateButtonsAndTitle];
        
    }
}

#pragma mark - AwesomeFloatingToolbarDelegate

- (void) floatingToolbar:(AwesomeFloatingToolbar *)toolbar didSelectButtonWithTitle:(NSString *)title {
    
    if ( [title isEqualToString:kWebBrowserBackString] ) {
        [self.webView goBack];
    } else if ( [title isEqualToString:kWebBrowserForwardString] ) {
        [self.webView goForward];
    } else if ( [title isEqualToString:kWebBrowserReloadString] ) {
        [self.webView reload];
    } else {
        [self.webView stopLoading];
    }
}

- (void) floatingToolbar:(AwesomeFloatingToolbar *)toolbar didTryToPanWithOffset:(CGPoint)offset {
    CGPoint startingPoint = toolbar.frame.origin;
    CGPoint newPoint = CGPointMake(startingPoint.x + offset.x, startingPoint.y + offset.y);
    
    CGRect potentialNewFrame = CGRectMake(newPoint.x, newPoint.y, CGRectGetWidth(toolbar.frame), CGRectGetHeight(toolbar.frame));
    
    if ( CGRectContainsRect(self.view.bounds, potentialNewFrame) ) {
        NSLog(@"The new size is %@", NSStringFromCGRect(potentialNewFrame));
        toolbar.frame = potentialNewFrame;
    }
}

- (void) floatingToolbar:(AwesomeFloatingToolbar *)toolbar didTryToPinchWithScale:(CGFloat)scale {
    
    CGRect startingSize = toolbar.frame;
    CGPoint startingPoint = toolbar.frame.origin;
    CGRect newSize = CGRectMake(startingPoint.x, startingPoint.y, ( CGRectGetWidth(startingSize) * ( 1 + scale / 100 ) ), ( CGRectGetHeight(startingSize) * ( 1 + scale / 100 ) ));
    
    CGRect potentialNewFrame = newSize;
    
    if ( CGRectContainsRect(self.view.bounds, potentialNewFrame) ) {
        NSLog(@"The new size is %@", NSStringFromCGRect(potentialNewFrame));
        toolbar.frame = potentialNewFrame;
    } else {
        NSLog(@"Frame expanding, but too big");
    }
}


#pragma mark - Helper Methods

- (void) loadWebDataWithSession:(NSURL *)URL {
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithURL:URL
                                        completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            
            [self.webView loadData:data
                          MIMEType:@"text/html"
             characterEncodingName:@"UTF-8"
                           baseURL:URL];
            
        } else {
            
            if ([URL.scheme isEqualToString:@"https"]) {
                NSLog(@"Going to attempt to use an unsecure conneciton");
                [self loadWebDataWithFallbackProperties: URL];
                
            } else {
                NSLog(@"%@", [error localizedDescription] );
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showUserError:error];
                });
            }
        }
    }];
    [task resume];
    
}

- (void) loadWebDataWithFallbackProperties: (NSURL *)URL {
    NSURLComponents *componentsOfURL = [[NSURLComponents alloc] initWithURL:URL resolvingAgainstBaseURL:NO];
    NSURL *newURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@%@", componentsOfURL.host, componentsOfURL.path]];
    [self loadWebDataWithSession:newURL];
}


- (NSString *) wrapAndEncodeGoogleQueryToString:(NSString *)textString {

    NSString *googleBaseURL = @"https://google.com/search?q=";
    NSString *query;
    
    query = textString;
    NSString *searchString = [NSString stringWithFormat:@"%@%@", googleBaseURL, query];
    return [searchString stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];

}


#pragma mark - Alert Method

- (void) showUserError:(NSError *)error {
    
    if (error.code != NSURLErrorCancelled) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error")
                                                                       message:[error localizedDescription]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
        
        [alert addAction:okAction];
        
        [self presentViewController:alert animated:YES completion:nil];

    }
    
    [self updateButtonsAndTitle];
}

- (void) showUserWelcomeMessage {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Welcome!", @"Welcome title")
                                                                   message:NSLocalizedString(@"You are an amazing user and I am grateful you are here.", @"Welcome message that loves the user")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *welcomeAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"You're Welcome", @"grateful user response to my welcome alert")
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil];
    
    [alert addAction:welcomeAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

#pragma mark - Miscellaneous
- (void) updateButtonsAndTitle {
    
    NSString *webPageTitle = [self.webView.title copy];
    if ([ webPageTitle length ]) {
        
        self.title = webPageTitle;
        
    } else {
        
        self.title = self.webView.URL.absoluteString;
        
    }
    
    if (self.webView.isLoading) {
        
        [self.activityIndicator startAnimating];
        
    } else {
        
        [self.activityIndicator stopAnimating];
        
    }
    
    [self.awesomeToolbar setEnabled:[self.webView canGoBack] forButtonWithTile:kWebBrowserBackString];
    [self.awesomeToolbar setEnabled:[self.webView canGoForward] forButtonWithTile:kWebBrowserForwardString];
    [self.awesomeToolbar setEnabled:[self.webView isLoading] forButtonWithTile:kWebBrowserStopString];
    [self.awesomeToolbar setEnabled:( ![self.webView isLoading] && self.webView.URL ) forButtonWithTile:kWebBrowserReloadString];
    
}

- (void) resetWebView {
    [self.webView removeFromSuperview];
    
    WKWebView *newWebView = [[WKWebView alloc] init];
    newWebView.navigationDelegate = self;
    [self.view addSubview:newWebView];
    
    self.webView = newWebView;
    
    self.textField.text = nil;
    [self updateButtonsAndTitle];
    
}

@end
