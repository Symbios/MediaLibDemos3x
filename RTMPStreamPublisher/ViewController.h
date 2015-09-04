//
//  ViewController.h
//  RTMPStreamPublisher
//
//  Created by Vyacheslav Vdovichenko on 7/10/12.
//  Copyright (c) 2014 The Midnight Coders, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

extern NSString * const TOKEN_KEY;

@interface ViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate> {
    
    BOOL     successToken;
    NSString *tokenText;
    
    IBOutlet UIView         *previewView;
    IBOutlet UIBarButtonItem *btnDisconnect;
    IBOutlet UIBarButtonItem *btnToggle;
    IBOutlet UIButton       *btnConnect; //Button to start streaming
    IBOutlet UIButton       *btnScan;  //Button to scan QR Code
    IBOutlet UIButton       *btnBack;  //Button to cancel QR Scanning
    IBOutlet UIButton       *btnUnpair;//Button to unpair device
    IBOutlet UIActivityIndicatorView *loading; //Spinning
    IBOutlet UIView         *firstCV;  //First ControlView (Instrucctions)
    IBOutlet UIView         *secondCV; //Second ControlView (Broadcast)
    IBOutlet UIToolbar      *toolbar; //Bottom toolbar to disconnect and toggle cameras
    IBOutlet UILabel        *pairedTokenLabel;
    
    IBOutlet UIView          *viewScan;
    IBOutlet UIBarButtonItem *scanButton;
    
    IBOutlet UIScrollView *scrollView;
}

-(IBAction)connectControl:(id)sender;
-(IBAction)publishControl:(id)sender;
-(IBAction)camerasToggle:(id)sender;
-(IBAction)unpairDevice:(id)sender;

//QR Code
-(BOOL)startReading;
-(void)stopReading;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;

-(IBAction)scanQRCode:(id)sender;


@end