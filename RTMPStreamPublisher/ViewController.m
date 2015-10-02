//
//  ViewController.m
//  RTMPStreamPublisher
//
//  Created by Vyacheslav Vdovichenko on 7/10/12.
//  Copyright (c) 2014 The Midnight Coders, Inc. All rights reserved.
//

#import "ViewController.h"
#import "DEBUG.h"
#import "BroadcastStreamClient.h"
#import "MediaStreamPlayer.h"
#import "MPMediaEncoder.h"
#import "SocialCam-Swift.h"

NSString * const TOKEN_KEY = @"tokenQR";

@interface ViewController () <MPIMediaStreamEvent> {
    
    RTMPClient              *socket;
    BroadcastStreamClient   *upstream;
    
    NSString *apiURL;
    NSString *endpoint;
    NSString *streamURL;
    NSString *streamId;
    
    NSString *textQR;
    
    MPVideoResolution       resolution;
    AVCaptureVideoOrientation orientation;
}

-(void)setDisconnect;

//QR Code
@property (nonatomic) BOOL isReading;

@end

@implementation ViewController

#pragma mark -
#pragma mark  View lifecycle

-(void)viewDidLoad {
    
    //[DebLog setIsActive:YES];
    
    [super viewDidLoad];
    
    socket = nil;
    upstream = nil;
    
    [loading stopAnimating];
    
    apiURL = @"";
    
    //QRCode;
    _isReading = NO;
    _captureSession = nil;
    
    [self isTokenSavedOnDevice];
    [self showNextView];
}

-(void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    [[ UIApplication sharedApplication] setIdleTimerDisabled: NO];
}
#if 0
-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
#endif
#pragma mark -
#pragma mark Private Methods

// ALERT

-(void)showAlert:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Receive" message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [av show];
    });
}

-(BOOL)validToken {
    return tokenText.length > 0? YES : NO;
}

// ACTIONS
-(void)doConnectAPI {
    if( [self validToken] )
    {
        [loading startAnimating];
        endpoint = [NSString stringWithFormat: @"/status/%@/1", tokenText];
        //Call API
        [[CameraApi sharedInstance] setBaseUrl: apiURL];
        [[CameraApi sharedInstance] setEndpoint: endpoint];
        //Synchronous
        [[CameraApi sharedInstance] callAPI];
        _Bool status = [[CameraApi sharedInstance] getStatus];
        if(status)
        {
            NSDictionary *result = [[CameraApi sharedInstance] getResult];
            streamURL = [NSString stringWithFormat: @"rtmp://%@/%@",result[@"stream_server"],result[@"stream_app"]];
            streamId = result[@"stream_id"];
            //NSLog(@"URL: %@/%@", streamURL, streamId);
            [self doConnect];
            toolbar.hidden = NO;
            secondCV.hidden = YES;
        }
    }
    else
    {
        [self showAlert: @"TOKEN cannot be empty"];
    }
}

-(void)doConnect {

    NSLog(@"CONNECT");
    //resolution = RESOLUTION_LOW;
    //resolution = RESOLUTION_CIF;
    resolution = RESOLUTION_MEDIUM;
    //resolution = RESOLUTION_VGA;
    
#if 1 // use inside RTMPClient instance
    
    upstream = [[BroadcastStreamClient alloc] init:streamURL resolution:resolution];
    //upstream = [[BroadcastStreamClient alloc] initOnlyAudio:hostTextField.text];
    //upstream = [[BroadcastStreamClient alloc] initOnlyVideo:hostTextField.text resolution:resolution];

#else // use outside RTMPClient instance
    
    if (!socket) {
        socket = [[RTMPClient alloc] init:streamURL];
        if (!socket) {
            [self showAlert:@"Connection has not be created"];
            return;
        }
        
        [socket spawnSocketThread];
   }
    
    upstream = [[BroadcastStreamClient alloc] initWithClient:socket resolution:resolution];
    
#endif
    
    upstream.delegate = self;
    
    //upstream.videoCodecId = MP_VIDEO_CODEC_FLV1;
    upstream.videoCodecId = MP_VIDEO_CODEC_H264;
    
    //upstream.audioCodecId = MP_AUDIO_CODEC_NELLYMOSER;
    upstream.audioCodecId = MP_AUDIO_CODEC_AAC;
    //upstream.audioCodecId = MP_AUDIO_CODEC_SPEEX;

    [upstream setVideoBitrate:72000];
    [upstream setAudioBitrate:40000];
    
    orientation = AVCaptureVideoOrientationPortrait;
    //orientation = AVCaptureVideoOrientationPortraitUpsideDown;
    //orientation = AVCaptureVideoOrientationLandscapeRight;
    //orientation = AVCaptureVideoOrientationLandscapeLeft;
    [upstream setVideoOrientation:orientation];
    
    [upstream stream:streamId publishType:PUBLISH_LIVE];
    //[upstream stream:streamTextField.text orientation:orientation publishType:PUBLISH_RECORD];
    //[upstream stream:streamTextField.text orientation:orientation publishType:PUBLISH_APPEND];
    
    if(![upstream isUsingFrontFacingCamera])
    {
        [upstream switchCameras];
    }
    
}

-(void)doDisconnectAPI {
    if( [self validToken] )
    {
        endpoint = [NSString stringWithFormat: @"/status/%@/0", tokenText];
        //Call API
        [[CameraApi sharedInstance] setBaseUrl: apiURL];
        [[CameraApi sharedInstance] setEndpoint: endpoint];
        //    [[CameraApi sharedInstance] asyncResult];
        //Synchronous
        NSDictionary *jsonData = [[CameraApi sharedInstance] getResult];
        //NSLog(@"JSON: %@", jsonData);
        [self doDisconnect];
        [[ UIApplication sharedApplication] setIdleTimerDisabled: NO];
        
        toolbar.hidden = YES;
        secondCV.hidden = NO;
    }
}

-(void)doDisconnect {
//    NSLog(@"DISCONNECT");
    [upstream disconnect];
}

-(void)setDisconnect {

    [socket disconnect];
    socket = nil;
    
    [upstream teardownPreviewLayer];
    upstream = nil;
    
    previewView.hidden = YES;
    [self doDisconnectAPI];
}

-(void)sendMetadata {
    
    NSString *camera = upstream.isUsingFrontFacingCamera ? @"FRONT" : @"BACK";
    NSDate *date = [NSDate date];
    NSDictionary *meta = [NSDictionary dictionaryWithObjectsAndKeys:camera, @"camera", [date description], @"date", nil];
    [upstream sendMetadata:meta event:@"changedCamera:"];
}

-(BOOL)isTokenSavedOnDevice {
    textQR = [[NSUserDefaults standardUserDefaults] stringForKey:TOKEN_KEY];
    if( textQR != nil )
    {
        [self getDataFromQR];
    }
    successToken = NO;
    //NSLog(@"ITSOD: %@", tokenText);
    if(tokenText.length > 0)
    {
        pairedTokenLabel.text = [NSString stringWithFormat:@"Device Token: %@",tokenText];
        successToken = YES;
    }
    
    return successToken;
}

-(void)saveTokenOnDevice {
    //NSLog(@"SAVE TOKEN: %@", textQR);
    [[NSUserDefaults standardUserDefaults] setObject:textQR forKey:TOKEN_KEY];
}

-(void)clearTokenOnDevice {
    //NSLog(@"CLEAR TOKEN: %@", textQR);
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:TOKEN_KEY];
}

#pragma mark -
#pragma mark Public Methods 

// ACTIONS

-(IBAction)connectControl:(id)sender {
    
    //NSLog(@"connectControl: host = %@", apiURL);
    
    (!upstream) ? [self doConnectAPI] : [self doDisconnectAPI];
    
}

-(IBAction)publishControl:(id)sender {
   
    //NSLog(@"publishControl: stream = %@", tokenText);

    (upstream.state != STREAM_PLAYING) ? [upstream start] : [upstream pause];
}

-(IBAction)camerasToggle:(id)sender {
    
    //NSLog(@"camerasToggle:");
    
    if (upstream.state != STREAM_PLAYING)
        return;
     
    [upstream switchCameras];
    
    [self sendMetadata];
}

-(IBAction)unpairDevice:(id)sender {
    successToken = NO;
    tokenText = @"";
    textQR = @"";
    [self clearTokenOnDevice];
    [self showNextView];
}

#pragma mark -
#pragma mark UITextFieldDelegate Methods 

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

#pragma mark -
#pragma mark MPIMediaStreamEvent Methods 

-(void)stateChanged:(id)sender state:(MPMediaStreamState)state description:(NSString *)description {
    
    NSLog(@" $$$$$$ <MPIMediaStreamEvent> stateChangedEvent: %d = %@ [%@]", (int)state, description, [NSThread isMainThread]?@"M":@"T");
    
    switch (state) {
            
        case CONN_DISCONNECTED: {
            
            [self setDisconnect];
            
            break;
        }
            
        case CONN_CONNECTED: {
            
            if (![description isEqualToString:MP_RTMP_CLIENT_IS_CONNECTED])
                break;

            [upstream start];
            
            break;
           
        }
        
        case STREAM_CREATED: {
            break;
        }
            
        case STREAM_PAUSED: {
            break;
        }
            
        case STREAM_PLAYING: {
           
            [upstream setPreviewLayer:previewView];

            [loading stopAnimating];
            previewView.hidden = NO;
            btnToggle.enabled = YES;
            break;
        }
            
        default:
            break;
    }
}

-(void)connectFailed:(id)sender code:(int)code description:(NSString *)description {
    
    NSLog(@" $$$$$$ <MPIMediaStreamEvent> connectFailedEvent: %d = %@, [%@]", code, description, [NSThread isMainThread]?@"M":@"T");
    
    if (!upstream)
        return;
    
    [self setDisconnect];
    
    [self showAlert:(code == -1) ? 
     @"Unable to connect to the server. Make sure the hostname/IP address and port number are valid" : 
     [NSString stringWithFormat:@"connectFailedEvent: %@", description]];
}

#if 0
// Send metadata for each video frame
-(void)pixelBufferShouldBePublished:(CVPixelBufferRef)pixelBuffer timestamp:(int)timestamp {
    
    NSLog(@" $$$$$$ <MPIMediaStreamEvent> pixelBufferShouldBePublished: %d [%@]", timestamp, [NSThread isMainThread]?@"M":@"T");

    //[upstream sendMetadata:@{@"videoTimestamp":[NSNumber numberWithInt:timestamp]} event:@"videoFrameOptions:"];
    
    //
    CVPixelBufferRef frameBuffer = pixelBuffer;
    
    // Get the base address of the pixel buffer.
    uint8_t *baseAddress = CVPixelBufferGetBaseAddress(frameBuffer);
    // Get the data size for contiguous planes of the pixel buffer.
    size_t bufferSize = CVPixelBufferGetDataSize(frameBuffer);
    // Get the pixel buffer width and height.
    size_t width = CVPixelBufferGetWidth(frameBuffer);
    size_t height = CVPixelBufferGetHeight(frameBuffer);
    
    [upstream sendMetadata:@{@"videoTimestamp":[NSNumber numberWithInt:timestamp], @"bufferSize":[NSNumber numberWithInt:bufferSize], @"width":[NSNumber numberWithInt:width], @"height":[NSNumber numberWithInt:height]} event:@"videoFrameOptions:"];
}
#endif


//QR CODE

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            textQR = [metadataObj stringValue];
            [self performSelectorOnMainThread:@selector(getDataFromQR) withObject:nil waitUntilDone:NO];
            
            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
            _isReading = NO;
        }
    }
}

- (void)getDataFromQR:(BOOL)displayAlert {
    NSURL *url = [NSURL URLWithString:textQR];
    if([url scheme] == nil || [url host] == nil || [url lastPathComponent] == nil)
    {
        successToken = NO;
        if(displayAlert)
        {
            [self showAlert: @"Invalid QR Code"];
        }
    }
    else
    {
        successToken = YES;
        apiURL = [NSString stringWithFormat:@"%@://%@", [url scheme], [url host]];
        tokenText = [url lastPathComponent];
        //NSLog(@"TOKEN TEXT: %@", tokenText);
    }
}

- (void)getDataFromQR {
    [self getDataFromQR:YES];
}

- (BOOL)startReading {
    
    NSError *error;
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error: &error];
    if(!input)
    {
        NSLog(@"Error StartReading: %@", [error localizedDescription]);
        return NO;
    }
    
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession addInput:input];
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [_captureSession addOutput:captureMetadataOutput];
    
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate: self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:viewScan.layer.bounds];
    [viewScan.layer addSublayer:_videoPreviewLayer];
    
    [_captureSession startRunning];
    
    return YES;
}

-(void)stopReading {
    [_captureSession stopRunning];
    _captureSession = nil;

    [_videoPreviewLayer removeFromSuperlayer];
    
    [self showNextView];
}

-(void)hideShowQRScan {

    if(_isReading) {
        [self stopReading];
        _isReading = !_isReading;
    }
    else {
        if([self startReading]) {
            _isReading = !_isReading;
            viewScan.hidden = NO;
            btnBack.hidden = NO;
            firstCV.hidden = YES;
            secondCV.hidden = YES;
        }
    }
}

-(void)showNextView {
    viewScan.hidden = YES;
    btnBack.hidden = YES;
    if(successToken)
    {
        firstCV.hidden = YES;
        secondCV.hidden = NO;
        //Save token on device for next time
        [self saveTokenOnDevice];
    }
    else
    {
        firstCV.hidden = NO;
        secondCV.hidden = YES;
    }
}

-(IBAction)scanQRCode:(id)sender {
    
    [self hideShowQRScan];
}


-(IBAction)cancelScanQRCode:(id)sender {
    
    [self hideShowQRScan];
}

@end
