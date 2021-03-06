//
//  HomeViewController.m
//  MySpots
//
//  Created by Jiaqi Liu on 3/18/14.
//  Copyright (c) 2014 OSU. All rights reserved.
//

#import "SpotsManager.h"
#import "FileManager.h"
#import "HomeViewController.h"
#import "ShareHandler.h"
#import "Utilities.h"
#import "SIAlertView.h"
#import "PulsingHaloLayer.h"
#import "ANBlurredImageView.h"
#import "UIColor+MLPFlatColors.h"
#import "JDStatusBarNotification.h"
#import "URBAlertView.h"
#import "ETActivityIndicatorView.h"
#import "CircularProgressView.h"
#import "DCPathButton.h"
#import "CHTumblrMenuView.h"
#import "FBShimmeringView.h"

#import <Social/Social.h>
#import <MessageUI/MessageUI.h>

@interface HomeViewController () <DCPathButtonDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, CHTumblrMenuViewDelegate> {
    BOOL needsToDisplayLaunchAnimation;
}

@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (strong, nonatomic) IBOutlet ANBlurredImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *buttonView;
@property (weak, nonatomic) IBOutlet UIView *masterView;
@property (nonatomic) PulsingHaloLayer *halo;
@property (nonatomic) DCPathButton *dcPathButton;
@property (nonatomic) URBAlertView *alertView;
@property (nonatomic) CircularProgressView *circularProgressView;
@property (nonatomic) CHTumblrMenuView *menuView;
@end

@implementation HomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (!DEVICE_IS_4INCH_IPHONE) {
        self.bottomLabel.frame = CGRectMake(self.bottomLabel.frame.origin.x, self.bottomLabel.frame.origin.y - 88, self.bottomLabel.frame.size.width, self.bottomLabel.frame.size.height);
    }
    
    NSLog(@"%@", [FileManager imageFilePathWithFileName:nil]);

    [Utilities addBackgroundImageToView:self.masterView withImageName:@"bg_2.jpg"];
    
    CGFloat locationY = DEVICE_IS_4INCH_IPHONE ? 300 : 260;
    
    self.LogoLabel.textColor = [UIColor flatWhiteColor];
    
    [_imageView setHidden:YES];
    [_imageView setFramesCount:10];
    [_imageView setBlurAmount:1];
    
    self.dcPathButton = [[DCPathButton alloc]
                          initDCPathButtonWithSubButtons:5
                          totalRadius:110
                          centerRadius:45
                          subRadius:35
                          centerImage:@"circle"
                          centerBackground:nil
                          subImages:^(DCPathButton *dc){
                              [dc subButtonImage:@"spot_c" withTag:0];
                              [dc subButtonImage:@"maps_c" withTag:1];
                              [dc subButtonImage:@"camera_c" withTag:2];
                              [dc subButtonImage:@"setting" withTag:3];
                              [dc subButtonImage:@"download_c" withTag:4];
                          }
                          subImageBackground:nil
                          inLocationX:160 locationY:locationY toParentView:self.buttonView];
    self.dcPathButton.delegate = self;
    
    // Animation setup
    [self animationSetup];
    needsToDisplayLaunchAnimation = YES;

    self.circularProgressView = [[CircularProgressView alloc]initWithFrame:CGRectMake(160 - 42.5, locationY - 42.5, 85, 85)];
    
    self.circularProgressView.backColor = [UIColor whiteColor];
    self.circularProgressView.progressColor = [UIColor flatBlueColor];
    self.circularProgressView.lineWidth = 7.5;
    self.circularProgressView.alpha = 1.0f;
    self.circularProgressView.userInteractionEnabled = NO;
    [self.circularProgressView setProgress:0.0];
    self.circularProgressView.hidden = YES;
    [self.view addSubview:self.circularProgressView];
    self.shareButton.alpha = 0.0f;
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.screenName = @"Home Screen";
}

- (void)animationSetup
{
    CGFloat yOffset = DEVICE_IS_4INCH_IPHONE ? 0 : -88;

    self.bottomLabel.frame = CGRectMake(-280, 510 + yOffset, 280, 40);
    self.LogoLabel.frame = CGRectMake(320 + 280, 35, 280, 90);
    self.dcPathButton.alpha = 0.0f;
    self.dcPathButton.userInteractionEnabled = NO;
    self.bottomLabel.alpha = 0.0f;
    self.shareButton.alpha = 0.0f;
    [self stopHaloAnimation];
}

- (void)startHaloAnimation
{
    [self stopHaloAnimation];
    if (!self.dcPathButton.userInteractionEnabled) return;

    CGFloat locationY = DEVICE_IS_4INCH_IPHONE ? 300 : 260;
    self.halo = [PulsingHaloLayer layer];
    self.halo.position = CGPointMake(160, locationY);
    self.halo.radius = 130;
    self.halo.backgroundColor = [UIColor flatWhiteColor].CGColor;
    [self.buttonView.layer insertSublayer:self.halo atIndex:0];
}

- (void)stopHaloAnimation
{
    NSMutableArray *layersNeedToBeRemoved = [[NSMutableArray alloc]init];
    [self.buttonView.layer.sublayers enumerateObjectsUsingBlock:^(CALayer *layer, NSUInteger index, BOOL *stop) {
        if ([layer isKindOfClass:[PulsingHaloLayer class]]) {
            [layersNeedToBeRemoved addObject:layer];
        }
    }];
    for (CALayer *layer in layersNeedToBeRemoved) {
        [layer removeFromSuperlayer];
    }
}

- (void)executeAnimation
{
    [self animationSetup];
    
    if (self.dcPathButton.isExpanded) {
        [self.dcPathButton close];
    }
    CGFloat yOffset = DEVICE_IS_4INCH_IPHONE ? 0 : -88;
    
    [UIView animateWithDuration:1.0f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        self.LogoLabel.frame = CGRectMake(20, 35, 280, 90);
        self.bottomLabel.frame = CGRectMake(20, 510 + yOffset, 280, 40);
        self.bottomLabel.alpha = 1.0f;
    } completion:^(BOOL finished){
        
        if (!self.imageView.image) {
            self.imageView.image = [Utilities snapshotViewForView:self.masterView];
            self.imageView.baseImage = self.imageView.image;
            [self.imageView setBlurTintColor:[UIColor colorWithWhite:0.f alpha:0.5]];
            [self.imageView generateBlurFramesWithCompletion:^{}];
        }
        
        [UIView animateWithDuration:0.7f animations:^{
            
            self.dcPathButton.alpha = 1.0f;
            self.shareButton.alpha = 1.0f;
        } completion:^(BOOL finished){
            
            self.dcPathButton.userInteractionEnabled = YES;
            [self startHaloAnimation];
        }];
    }];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    
    if (needsToDisplayLaunchAnimation) {
        [self executeAnimation];
        needsToDisplayLaunchAnimation = NO;
    }
}

- (void)handleDidEnterBackground
{
    [self animationSetup];
    if (!self.alertView.isHidden) {
        [self.alertView hide];
    }
    needsToDisplayLaunchAnimation = YES;
    if (self.dcPathButton.isExpanded) {
        [self.dcPathButton close];
    }
}

- (void)handleDidBecomeActive
{
    if (needsToDisplayLaunchAnimation) {
        [self executeAnimation];
        needsToDisplayLaunchAnimation = NO;
    }
}


- (void)deleteAllData {
    
    SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"Warning" andMessage:@"Are you sure? Everything will be removed!"];
    [alertView addButtonWithTitle:@"Cancel"
                             type:SIAlertViewButtonTypeCancel
                          handler:^(SIAlertView *alertView) {
                          }];
    [alertView addButtonWithTitle:@"Yes"
                             type:SIAlertViewButtonTypeDestructive
                          handler:^(SIAlertView *alertView) {
  
                              [[SpotsManager sharedManager] removeAllSpots];
                              [JDStatusBarNotification showWithStatus:@"All spots have been removed!" dismissAfter:2 styleName:JDStatusBarStyleWarning];
                          }];
    alertView.transitionStyle = SIAlertViewTransitionStyleDropDown;
    alertView.backgroundStyle = SIAlertViewBackgroundStyleSolid;
    alertView.titleFont = [UIFont fontWithName:@"Chalkduster" size:25.0];
    alertView.messageFont = [UIFont fontWithName:@"Chalkduster" size:15.0];
    alertView.buttonFont = [UIFont fontWithName:@"Chalkduster" size:17.0];
    
    [alertView show];
}


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - DCPathButton delegate

- (void)button_0_action:(DCSubButton *)sender {

    [self executeSubButtonAnimationForButton:sender];
    [self.dcPathButton close];
    
    [self performSegueWithIdentifier:@"createMarkerSegue" sender:nil];
}

- (void)button_1_action:(DCSubButton *)sender {

    [self executeSubButtonAnimationForButton:sender];
    
    [self.dcPathButton close];
    
    if ([SpotsManager sharedManager].spots.count > 0) {
        [self performSegueWithIdentifier:@"spotsSegue" sender:nil];
    } else {
        SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"Oops" andMessage:@"No spots are found, please create one first!"];
        [alertView addButtonWithTitle:@"OK"
                                 type:SIAlertViewButtonTypeDestructive
                              handler:^(SIAlertView *alertView) {
        }];
        alertView.transitionStyle = SIAlertViewTransitionStyleDropDown;
        alertView.backgroundStyle = SIAlertViewBackgroundStyleSolid;
        alertView.titleFont = [UIFont fontWithName:@"Chalkduster" size:25.0];
        alertView.messageFont = [UIFont fontWithName:@"Chalkduster" size:15.0];
        alertView.buttonFont = [UIFont fontWithName:@"Chalkduster" size:17.0];
        
        [alertView show];
    }
}

- (void)button_2_action:(DCSubButton *)sender {
    
    [self executeSubButtonAnimationForButton:sender];
    
    [self.dcPathButton close];
    
    if ([SpotsManager sharedManager].spots.count > 0) {
        
        [self performSegueWithIdentifier:@"cameraSegue" sender:nil];
        
    } else {
        SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"Oops" andMessage:@"No spots are found, please create one first!"];
        [alertView addButtonWithTitle:@"OK"
                                 type:SIAlertViewButtonTypeDestructive
                              handler:^(SIAlertView *alertView) {
                              }];
        alertView.transitionStyle = SIAlertViewTransitionStyleDropDown;
        alertView.backgroundStyle = SIAlertViewBackgroundStyleSolid;
        alertView.titleFont = [UIFont fontWithName:@"Chalkduster" size:25.0];
        alertView.messageFont = [UIFont fontWithName:@"Chalkduster" size:15.0];
        alertView.buttonFont = [UIFont fontWithName:@"Chalkduster" size:17.0];
        
        [alertView show];
    }
}

- (void)button_3_action:(DCSubButton *)sender {

    [self executeSubButtonAnimationForButton:sender];
}

- (void)button_4_action:(DCSubButton *)sender {

    [self executeSubButtonAnimationForButton:sender];
    
    [self.dcPathButton close];
    __weak typeof(self) weakSelf = self;
    self.alertView = [URBAlertView dialogWithTitle:@"Download Spot" message:@"Enter your MySpots download code here:"];
    [self.alertView addButtonWithTitle:@"Cancel"];
    [self.alertView addButtonWithTitle:@"Confirm"];
    [self.alertView addTextFieldWithPlaceholder:@"Download code" secure:NO];
    [self.alertView setHandlerBlock:^(NSInteger buttonIndex, URBAlertView *alertView) {
        
        if (buttonIndex == 1) {
            if ([alertView textForTextFieldAtIndex:0].length == 8) {
                
                
                CGFloat locationY = DEVICE_IS_4INCH_IPHONE ? 270 : 220;
                ETActivityIndicatorView *etActivity = [[ETActivityIndicatorView alloc] initWithFrame:CGRectMake(weakSelf.view.frame.size.width/2 - 30, locationY, 60, 60)];
                etActivity.color = [UIColor flatBlueColor];
                [etActivity startAnimating];
                etActivity.tag = 6713;
                [weakSelf.view addSubview:etActivity];
                weakSelf.circularProgressView.hidden = NO;
                
                [JDStatusBarNotification showWithStatus:@"Downloading..." styleName:JDStatusBarStyleWarning];
                
                 [ShareHandler downloadSpotByDownloadCode:[alertView textForTextFieldAtIndex:0]
                                                 progress:^(NSUInteger totalBytesRead, NSInteger totalBytesExpectedToRead){
                 
                                                    //NSLog(@"%.0f", (float)totalBytesRead/(float)totalBytesExpectedToRead);
                                                    if (totalBytesExpectedToRead != -1 && totalBytesRead > 0) {
                                                        [weakSelf.circularProgressView setProgress:(float)totalBytesRead/(float)totalBytesExpectedToRead];
                                                    }
                                                }
                                          completionBlock:^(ShareHandlerOption option, NSError *error){
                 
                                             weakSelf.circularProgressView.hidden = YES;
                                             weakSelf.dcPathButton.userInteractionEnabled = YES;
                                             [[weakSelf.view viewWithTag:6713] removeFromSuperview];
                                             if (option == ShareHandlerOptionSuccess) {
                                                 [JDStatusBarNotification showWithStatus:@"New spot added" dismissAfter:2.0f styleName:JDStatusBarStyleSuccess];
                                             } else if (option == ShareHandlerOptionFailure) {
                 
                                                 if (error) {
                                                     [JDStatusBarNotification showWithStatus:error.localizedDescription dismissAfter:2.0f styleName:JDStatusBarStyleError];
                                                 } else {
                                                     [JDStatusBarNotification showWithStatus:@"Error occurs" dismissAfter:2.0f styleName:JDStatusBarStyleError];
                                                 }
                                             }
                                         }];
                
                
                weakSelf.dcPathButton.userInteractionEnabled = NO;
                [alertView hideWithAnimation:URBAlertAnimationDefault];
            } else {
                CAKeyframeAnimation * anim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
                anim.values = @[ [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f) ], [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f) ] ] ;
                anim.autoreverses = YES ;
                anim.repeatCount = 2.0f ;
                anim.duration = 0.07f ;
                [alertView.layer addAnimation:anim forKey:nil] ;
            }
        } else if (buttonIndex == 0) {
            [alertView hideWithAnimation:URBAlertAnimationDefault];
        }
        
    }];
    [self.alertView showWithAnimation:URBAlertAnimationDefault];
}

- (void)executeSubButtonAnimationForButton:(DCSubButton *)button
{
    if (button.layer.sublayers.count == 2) {
        [[button.layer.sublayers objectAtIndex:0] removeFromSuperlayer];
    }
    PulsingHaloLayer *buttonHalo = [PulsingHaloLayer layer];
    buttonHalo.repeatCount = 0;
    buttonHalo.animationDuration = 1.0f;
    buttonHalo.position = CGPointMake(button.frame.size.width/2.0, button.frame.size.height/2.0);
    buttonHalo.radius = 80;
    buttonHalo.backgroundColor = [UIColor flatGrayColor].CGColor;
    [button.layer insertSublayer:buttonHalo atIndex:0];
}

- (void)pathButtonWillOpen
{
    self.imageView.hidden = NO;
    [self stopHaloAnimation];
    [self.imageView blurInAnimationWithDuration:0.25f];
    
    self.shareButton.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.2f animations:^{
        self.shareButton.alpha = 0.0f;
    }];
}

- (void)pathButtonWillClose
{
    [self.imageView blurOutAnimationWithDuration:0.5f completion:^{
        self.imageView.hidden = YES;
        [self startHaloAnimation];
    }];
    
    [UIView animateWithDuration:0.8f animations:^{
        self.shareButton.alpha = 1.0f;
    } completion:^(BOOL finished) {
        self.shareButton.userInteractionEnabled = YES;
    }];
}


- (IBAction)shareButtonPressed:(id)sender {
    
    self.shareButton.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.2f animations:^{
        self.shareButton.alpha = 0.0f;
    } completion:nil];
    
    [self stopHaloAnimation];
    [self.halo removeFromSuperlayer];
    
    self.dcPathButton.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.2f animations:^{
        self.dcPathButton.alpha = 0.0;
    } completion:^(BOOL finished){
        
    }];
    
    self.imageView.hidden = NO;
    [self.imageView blurInAnimationWithDuration:0.25f];

    
    
    self.menuView = [[CHTumblrMenuView alloc] init];
    self.menuView.delegate = self;
    
    __weak typeof(self) weakSelf = self;
    [self.menuView addMenuItemWithTitle:@"Text" andIcon:[UIImage imageNamed:@"sms.png"] andSelectedBlock:^{
        
        if([MFMessageComposeViewController canSendText])
        {
            MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
            controller.body = @"Hi\n\nCheck out the #MySpots App! It's amazing!";
            controller.messageComposeDelegate = weakSelf;
            [weakSelf presentViewController:controller animated:YES completion:nil];
        }
        
    }];
    [self.menuView addMenuItemWithTitle:@"Email" andIcon:[UIImage imageNamed:@"email.png"] andSelectedBlock:^{
        
        if ([MFMailComposeViewController canSendMail])
        {
            MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
            mailer.mailComposeDelegate = weakSelf;
            [mailer setSubject:@"MySpots"];
            NSString *emailBody = @"Hi\n\nCheck out the #MySpots App! It's amazing!";
            [mailer setMessageBody:emailBody isHTML:NO];
            [weakSelf presentViewController:mailer animated:YES completion:nil];
        }
        
    }];
    [self.menuView addMenuItemWithTitle:@"Facebook" andIcon:[UIImage imageNamed:@"facebook_new.png"] andSelectedBlock:^{
        
        if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
            
            SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
            
            [controller setInitialText:@"Hi\n\nCheck out the #MySpots App! It's amazing!"];
            [controller addImage:[UIImage imageNamed:@"icon.png"]];
            
            [weakSelf presentViewController:controller animated:YES completion:Nil];
        } else {
            SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"Oops" andMessage:@"Please login with your Facebook account in settings!"];
            [alertView addButtonWithTitle:@"OK"
                                     type:SIAlertViewButtonTypeDestructive
                                  handler:^(SIAlertView *alertView) {
                                  }];
            alertView.transitionStyle = SIAlertViewTransitionStyleDropDown;
            alertView.backgroundStyle = SIAlertViewBackgroundStyleSolid;
            alertView.titleFont = [UIFont fontWithName:@"Chalkduster" size:25.0];
            alertView.messageFont = [UIFont fontWithName:@"Chalkduster" size:15.0];
            alertView.buttonFont = [UIFont fontWithName:@"Chalkduster" size:17.0];
            
            [alertView show];
        }
        
    }];
    [self.menuView addMenuItemWithTitle:@"Twitter" andIcon:[UIImage imageNamed:@"twitter.png"] andSelectedBlock:^{
        
        if([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
            
            SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            
            [controller setInitialText:@"Hi\n\nCheck out the #MySpots App! It's amazing!"];
            [controller addImage:[UIImage imageNamed:@"icon.png"]];
            
            [weakSelf presentViewController:controller animated:YES completion:Nil];
        } else {
            SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"Oops" andMessage:@"Please login with your Twitter account in settings!"];
            [alertView addButtonWithTitle:@"OK"
                                     type:SIAlertViewButtonTypeDestructive
                                  handler:^(SIAlertView *alertView) {
                                  }];
            alertView.transitionStyle = SIAlertViewTransitionStyleDropDown;
            alertView.backgroundStyle = SIAlertViewBackgroundStyleSolid;
            alertView.titleFont = [UIFont fontWithName:@"Chalkduster" size:25.0];
            alertView.messageFont = [UIFont fontWithName:@"Chalkduster" size:15.0];
            alertView.buttonFont = [UIFont fontWithName:@"Chalkduster" size:17.0];
            
            [alertView show];
        }
    }];
    [self.menuView addMenuItemWithTitle:@"Google+" andIcon:[UIImage imageNamed:@"google_plus.png"] andSelectedBlock:^{
        
    }];
    [self.menuView addMenuItemWithTitle:@"Weibo" andIcon:[UIImage imageNamed:@"weibo.png"] andSelectedBlock:^{
        
        if([SLComposeViewController isAvailableForServiceType:SLServiceTypeSinaWeibo]) {
            
            SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeSinaWeibo];
            
            [controller setInitialText:@"Hi\n\nCheck out the #MySpots App! It's amazing!"];
            [controller addImage:[UIImage imageNamed:@"icon.png"]];
            
            [weakSelf presentViewController:controller animated:YES completion:Nil];
        } else {
            SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"Oops" andMessage:@"Please login with your Weibo account in settings!"];
            [alertView addButtonWithTitle:@"OK"
                                     type:SIAlertViewButtonTypeDestructive
                                  handler:^(SIAlertView *alertView) {
                                  }];
            alertView.transitionStyle = SIAlertViewTransitionStyleDropDown;
            alertView.backgroundStyle = SIAlertViewBackgroundStyleSolid;
            alertView.titleFont = [UIFont fontWithName:@"Chalkduster" size:25.0];
            alertView.messageFont = [UIFont fontWithName:@"Chalkduster" size:15.0];
            alertView.buttonFont = [UIFont fontWithName:@"Chalkduster" size:17.0];
            
            [alertView show];
        }
    }];
    
    //CGFloat yOffset = DEVICE_IS_4INCH_IPHONE ? 0 : -30;
    
    /*
     FBShimmeringView *shimmeringView = [[FBShimmeringView alloc] initWithFrame:CGRectMake(20, 95 + yOffset, 280, 150)];
     UILabel *downloadCodeLabel = [[UILabel alloc] initWithFrame:shimmeringView.bounds];
     downloadCodeLabel.textAlignment = NSTextAlignmentCenter;
     downloadCodeLabel.font = [UIFont fontWithName:@"Chalkduster" size:45];
     downloadCodeLabel.numberOfLines = 3;
     downloadCodeLabel.textColor = [UIColor flatWhiteColor];
     shimmeringView.contentView = downloadCodeLabel;
     shimmeringView.shimmering = YES;
     shimmeringView.alpha = 0.0f;
     [self.menuView addSubview:shimmeringView];
     */
    
    [self.menuView setUserInteractionEnabled:YES];
    [self.menuView showInView:self.buttonView];
    
    /*
     [UIView animateWithDuration:0.7f animations:^{
     shimmeringView.alpha = 1.0f;
     }];
     */
}

#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    switch (result) {
        case MessageComposeResultSent:
            [JDStatusBarNotification showWithStatus:@"Message sent!" dismissAfter:1.5f styleName:JDStatusBarStyleSuccess];
            break;
        default:
            break;
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled: you cancelled the operation and no email message was queued.");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved: you saved the email message in the drafts folder.");
            break;
        case MFMailComposeResultSent:
            [JDStatusBarNotification showWithStatus:@"Email sent!" dismissAfter:1.5f styleName:JDStatusBarStyleSuccess];
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail failed: the email message was not saved or queued, possibly due to an error.");
            break;
        default:
            NSLog(@"Mail not sent.");
            break;
    }
    
    // Remove the mail view
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tumblrMenuViewDidDismiss
{
    self.menuView.userInteractionEnabled = NO;
    [self.imageView blurOutAnimationWithDuration:0.6f];

    [UIView animateWithDuration:0.8f delay:0.5f options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.dcPathButton.alpha = 1.0;
        self.shareButton.alpha = 1.0f;
    } completion:^(BOOL finished){
        self.imageView.hidden = YES;
        self.dcPathButton.userInteractionEnabled = YES;
        self.shareButton.userInteractionEnabled = YES;
        [self startHaloAnimation];
    }];
}


@end
