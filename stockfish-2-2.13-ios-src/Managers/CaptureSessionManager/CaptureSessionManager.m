//
//  CaptureSessionManager.m
//
//
//  Created by silenGSR on 5/11/15.
//  Copyright © 2015 Nibble development. All rights reserved.
//



#import "AudioSession.h"
#import "CaptureSessionManager.h"

@implementation CaptureSessionManager


- (id)init {
    if ((self = [super init]))
    {
        
        [self firstInit];
        
        
    }
    return self;
}


- (id)initWithFrame:(CGRect)frame withDel:(id<CaptureSessionManagerDelegate>)del
{
    if ((self = [super init]))
    {
        if (del) {
            _delegate = del;
        }
        [self firstInit];
        _previewLayer.frame = frame;
        
        
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super init]))
    {
        [self firstInit];
        _previewLayer.frame = frame;
        
        
    }
    return self;
}

- (CIImage*) getCIImageForFilter
{
    if (self.lastPhotoTaked) {
        if (self.lastPhotoCI) {
            return self.lastPhotoCI;
        }
        else {
            self.lastPhotoCI =  [CIImage imageWithData:UIImagePNGRepresentation(self.lastPhotoTaked)];
            return self.lastPhotoCI;
        }
    }
    return nil;
}

- (CIImage*) getCIImageForFilterSmall
{
    if (self.lastPhotoTakedSmall) {
        if (self.lastPhotoCISmall) {
            return self.lastPhotoCISmall;
        }
        else {
            self.lastPhotoCISmall =  [CIImage imageWithData:UIImagePNGRepresentation(self.lastPhotoTakedSmall)];
            return self.lastPhotoCISmall;
        }
    }
    return nil;
}

- (void) orientationChanged:(NSNotification *)note
{
    UIDevice * device = note.object;
    
    _previewLayer.frame = [UIScreen mainScreen].bounds;
    
    self.deviceOrientation = device.orientation;
    
    switch(device.orientation)
    {
        case UIDeviceOrientationPortrait:
            /* start special animation */
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            /* start special animation */
            break;
            
        default:
            break;
    };
}

- (void) prepareForvideo
{
    [AudioSession prepareSessionAudioToRecord];
    
    NSString *filePath = [[Utils getDirectoryForAudio] stringByAppendingPathComponent:@"video.m4a"];
    [[NSFileManager defaultManager] removeItemAtPath: filePath error: nil];
    
    
    
    AVCaptureConnection *videoConnection = [self getVideoConnection];
    
    if (!videoConnection || !self.output)
    {
        // hay algo que no esta bien..
        
        if ([self.delegate respondsToSelector:@selector(CaptureSessionManagerDelegate_PhotoFailed)])
        {
            [self.delegate CaptureSessionManagerDelegate_PhotoFailed];
        }
        
        return;
    }

      _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    

    //TODO  para entrar en el samplebuffer el _moviefileoutput no debe estar añadido, pq son incompatibles
    
    if (!_videoDataOutput)
    {
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
     //   [_videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    }
    if ([_captureSession canAddOutput:_videoDataOutput] ) {
       // [_captureSession addOutput:_videoDataOutput];
    }
    
    if (!_movieFileOutput) {
        _movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        _movieFileOutput.maxRecordedDuration = CMTimeMake(300000, 10000); // @ 5.3425 sec
    }
    
    //   [_captureSession removeOutput:_output];
    
    if ([_captureSession canAddOutput:_movieFileOutput]) {
        [_captureSession addOutput:_movieFileOutput];
    }
    

    

    NSURL *outputURL = [NSURL fileURLWithPath:filePath];
    
    
    //   NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputpathofmovie];
    
    AVCaptureVideoOrientation newOrientation;
    switch ([[UIDevice currentDevice] orientation])
    {
        case UIDeviceOrientationPortrait:
        {
            newOrientation = AVCaptureVideoOrientationPortrait;
            
            break;
        }
        case UIDeviceOrientationPortraitUpsideDown:
        {
            newOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            
            break;
        }
        case UIDeviceOrientationLandscapeLeft:
        {
            newOrientation = AVCaptureVideoOrientationLandscapeRight;
            
            break;
        }
        case UIDeviceOrientationLandscapeRight:
        {
            newOrientation = AVCaptureVideoOrientationLandscapeLeft;
            
            break;
        }
        default:
        {
            newOrientation = AVCaptureVideoOrientationPortrait;
        }
    }
    
    AVCaptureConnection *XvideoConnection = nil;
    
    for ( AVCaptureConnection *connection in [_movieFileOutput connections] )
    {
        //LogInfo(@" connection- %@", connection);
        for ( AVCaptureInputPort *port in [connection inputPorts] )
        {
           // LogInfo(@" port -%@", port);
            if ( [[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                XvideoConnection = connection;
            }
        }
    }
    
    if([XvideoConnection isVideoOrientationSupported]) {
        [XvideoConnection setVideoOrientation:newOrientation];//[[UIDevice currentDevice] orientation]];
    }
  //  XvideoConnection.videoMirrored = NO;
    
    
    
   // if ([XvideoConnection isVideoMirroringSupported]) {
    //    XvideoConnection.automaticallyAdjustsVideoMirroring = NO;

   // }
   // XvideoConnection.mir

    if (XvideoConnection.isVideoMirrored)
    {
        LogInfo(@" video MIRRORED");
    }
    
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
     if ([self.delegate respondsToSelector:@selector(CaptureSessionStartTimerVideo)]) {
         [self.delegate CaptureSessionStartTimerVideo];
     }
     
    [_movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
 });
    
}

- (void) stopVideoRecord
{
    [_movieFileOutput stopRecording];
    [self stopRunning];
}

- (void) prepareForPhoto
{
    _captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    [self CameraSetOutputProperties];
}



- (void) isAvailableAuthorization
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        
        
        
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        if(status == AVAuthorizationStatusAuthorized) {
            // authorized
            LogInfo(@" autorize");
            
        } else if(status == AVAuthorizationStatusDenied){
            LogInfo(@" denegao");
            if ([self.delegate respondsToSelector:@selector(showNotAuthorizeAudio:isCamera:isGalery:)]) {
                [self.delegate showNotAuthorizeAudio:NO isCamera:YES isGalery:NO];
            }
            // denied
        } else if(status == AVAuthorizationStatusRestricted){
            // restricted
            LogInfo(@" restringido");
        } else if(status == AVAuthorizationStatusNotDetermined){
            // not determined
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if(granted){
                    LogInfo(@"Granted access");
                } else {
                    LogInfo(@"Not granted access");
                }
            }];
        }
    }
}

- (void)firstInit
{
    [Utils validateExistFolderAudio];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
    
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera])
    {
        
        if (self.delegate) {
            [self isAvailableAuthorization];
        }
        
        _videoDevice = [AVCaptureDevice
                        defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        _captureSession = [[AVCaptureSession alloc] init];
        
        
        _captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
        
    }
    
    
    _audioCapture = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    _audioInput = [AVCaptureDeviceInput deviceInputWithDevice:_audioCapture error:nil];
    if ([_captureSession canAddInput:_audioInput]) {
        [_captureSession addInput:_audioInput];
    }
    
    
    _videoInput = [[AVCaptureDeviceInput alloc]
                   initWithDevice:_videoDevice error:nil];
    
    
    if ([_captureSession canAddInput:_videoInput]) {
        [_captureSession addInput:_videoInput];
    }
    
    _output = [[AVCaptureStillImageOutput alloc] init];
    
    
    if ( [_captureSession canAddOutput:_output] ) {
        [_captureSession addOutput:_output];
    }
    
    
  
    
    
    _flashMode = kFlashOff;
    
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc]
                     initWithSession:_captureSession];
    _previewLayer.videoGravity =
    AVLayerVideoGravityResizeAspectFill;

}

- (void) tapToFocus:(UITapGestureRecognizer* ) singleTap inContainerView:(UIView*) containerView
{
    if (![self isRunning]) return;
    
    CGPoint touchPoint = [singleTap locationInView:containerView];
    CGPoint convertedPoint = [_previewLayer captureDevicePointOfInterestForPoint:touchPoint];
    AVCaptureDevice *currentDevice = _videoInput.device;
    
    if([currentDevice isFocusPointOfInterestSupported] && [currentDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]){
        NSError *error = nil;
        [currentDevice lockForConfiguration:&error];
        if(!error){
            
            [currentDevice setFocusPointOfInterest:convertedPoint];
            [currentDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            [currentDevice unlockForConfiguration];
        }
    }
}
- (void)startRunning
{
    if (!self.isRunning)
    {
        [self.captureSession startRunning];
        self.isRunning = YES;
    }
}

- (void)stopRunning
{
    if (self.isRunning)
    {
        [self.captureSession stopRunning];
        self.isRunning = NO;
    }
    
}

- (void) resetPhoto
{
    self.isSaveVideo = NO;
    self.imgVideoThumbnail = nil;
    
    self.urlLastVideo = nil;
    
    self.lastPhotoTaked = nil;
    self.lastPhotoTakedSmall = nil;
    
    self.lastPhotoCI = nil;
    self.lastPhotoCISmall = nil;
}


- (UIImage *)flipImage:(UIImage *)image
{
    if ([image respondsToSelector:@selector(imageFlippedForRightToLeftLayoutDirection)]) {
        //iOS9
        image = image.imageFlippedForRightToLeftLayoutDirection;
    }
    
    return image;
    /*
     //CIImage *coreImage = [CIImage imageWithCGImage:image.CGImage];
     image = [Utils onlyScaleImage:image toMaxResolution:600];
     
     CIImage *coreImage = [CIImage imageWithData:UIImagePNGRepresentation(image)];
     
     coreImage = [coreImage imageByApplyingTransform:CGAffineTransformMakeScale(-1, 1)];
     image = [UIImage imageWithCIImage:coreImage scale:0.5 orientation:UIImageOrientationUp];
     
     return image;
     */
    
    
    //    return [UIImage imageWithCGImage:image.CGImage scale:1.0 orientation:UIImageOrientationRightMirrored];
    /*
     UIGraphicsBeginImageContext(image.size);
     CGContextDrawImage(UIGraphicsGetCurrentContext(),CGRectMake(0.,0., image.size.width, image.size.height),image.CGImage);
     UIImage *i = UIGraphicsGetImageFromCurrentImageContext();
     UIGraphicsEndImageContext();
     return i;
     */
}

- (void) takePhoto
{
    self.isSaveVideo = NO;
    self.urlLastVideo = nil;
    
    AVCaptureConnection *videoConnection = [self getVideoConnection];
    
    if (!videoConnection || !self.output)
    {
        // hay algo que no esta bien..
        
        if ([self.delegate respondsToSelector:@selector(CaptureSessionManagerDelegate_PhotoFailed)])
        {
            [self.delegate CaptureSessionManagerDelegate_PhotoFailed];
        }
        
        return;
    }
    
    // setea el Flash en el DEVICE
    [self putFlashIntoDevice];
    
    AVCaptureVideoOrientation newOrientation;
    switch ([[UIDevice currentDevice] orientation])
    {
        case UIDeviceOrientationPortrait:
        {
            newOrientation = AVCaptureVideoOrientationPortrait;
            
            break;
        }
        case UIDeviceOrientationPortraitUpsideDown:
        {
            newOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            
            break;
        }
        case UIDeviceOrientationLandscapeLeft:
        {
            newOrientation = AVCaptureVideoOrientationLandscapeRight;
            
            break;
        }
        case UIDeviceOrientationLandscapeRight:
        {
            newOrientation = AVCaptureVideoOrientationLandscapeLeft;
            
            break;
        }
        default:
        {
            newOrientation = AVCaptureVideoOrientationPortrait;
        }
    }
    
    [videoConnection setVideoOrientation:newOrientation];
    // videoConnection.automaticallyAdjustsVideoMirroring = YES;
    
    
    [self.output captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         if (imageSampleBuffer == NULL || error) {
             [SVProgressHUD showErrorWithStatus:HAVEVALUE(error.localizedDescription)?:@""];
             return ;
         }
         
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         
         UIImage *image = [[UIImage alloc] initWithData:imageData];
         
         if (image)
         {
             [self stopRunning];

             if (self.isFrontCamera) {
                 self.lastPhotoTaked = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:UIImageOrientationLeftMirrored];
                 if (newOrientation == AVCaptureVideoOrientationLandscapeRight || newOrientation == AVCaptureVideoOrientationLandscapeLeft) {
                     self.lastPhotoTaked = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:UIImageOrientationUp];
                 }

                 self.lastPhotoTaked = [self normalizeImage:self.lastPhotoTaked];
                   self.lastPhotoTaked = [Utils scaleImage:self.lastPhotoTaked  toMaxResolution:1200];
             }
             else {
                 self.lastPhotoTaked = [self normalizeImage:image];
                // self.lastPhotoTaked = [Utils scaleImage:self.lastPhotoTaked  toMaxResolution:1200];
             }
             
             if ([self.delegate respondsToSelector:@selector(CaptureSessionManagerDelegate_PhotoTaked:)]) {
                 dispatch_async(kMainQueue, ^{
                     
                 
                 [self.delegate CaptureSessionManagerDelegate_PhotoTaked:self.lastPhotoTaked];
                     });
             }
             
             
             [self generateAndSaveInternalImagesAfterTakePhotoWithPhoto:nil];
         }
         else
         {
             if ([self.delegate respondsToSelector:@selector(CaptureSessionManagerDelegate_PhotoFailed)])
             {
                 [self.delegate CaptureSessionManagerDelegate_PhotoFailed];
                 [self resetPhoto];
             }
         }
     }];
}

- (void) generateAndSaveInternalImagesAfterTakePhotoWithPhoto:(UIImage*) photo
{
    if (photo) {
        // [self resetPhoto];
        self.lastPhotoTaked = photo;
    }
    dispatch_async(kQueueBgDownload, ^{
        self.lastPhotoTakedSmall = [Utils scaleImage:self.lastPhotoTaked toMaxResolution:300];//[Utils onlyScaleImage:self.lastPhotoTaked toMaxResolution:300];
        
        //  self.lastPhotoCI = [CIImage imageWithData:UIImagePNGRepresentation(self.lastPhotoTaked)];
        //    self.lastPhotoCISmall = [CIImage imageWithData:UIImagePNGRepresentation(self.lastPhotoTakedSmall)];
        self.lastPhotoCI = [CIImage imageWithCGImage:self.lastPhotoTaked.CGImage];
        self.lastPhotoCISmall = [CIImage imageWithCGImage:self.lastPhotoTakedSmall.CGImage];
        
        dispatch_async(kMainQueue, ^{
            if ([self.delegate respondsToSelector:@selector(CaptureSessionManagerDelegate_EndProcessCIImage)])
            {
                [self.delegate CaptureSessionManagerDelegate_EndProcessCIImage];
            }
        });
    });
    
}

- (UIImage *)normalizeImage: (UIImage *)img
{

    self.orientationLastPhoto = img.imageOrientation;
    if (img.imageOrientation == UIImageOrientationUp || img.imageOrientation == UIImageOrientationLeftMirrored) return img;
    
    UIGraphicsBeginImageContextWithOptions(img.size, NO, img.scale);
    [img drawInRect:(CGRect){0, 0, img.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return normalizedImage;
}


- (void)toggleCam
{
    if (![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) return;
    
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1)		//Only do if device has multiple cameras
    {
        LogInfo(@"Toggle camera");
        NSError *error;
        
        AVCaptureDeviceInput *NewVideoInput;
        AVCaptureDevicePosition position = [[self.videoInput device] position];
        if (position == AVCaptureDevicePositionBack)
        {
            self.isFrontCamera = YES;
            NewVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self CameraWithPosition:AVCaptureDevicePositionFront] error:&error];
        }
        else if (position == AVCaptureDevicePositionFront)
        {
            self.isFrontCamera = NO;
            NewVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self CameraWithPosition:AVCaptureDevicePositionBack] error:&error];
        }
        
        if (NewVideoInput != nil)
        {
            [self.captureSession beginConfiguration];		//We can now change the inputs and output configuration.  Use commitConfiguration to end
            [self.captureSession removeInput:self.videoInput];
            if ([self.captureSession canAddInput:NewVideoInput])
            {
                [self.captureSession addInput:NewVideoInput];
                self.videoInput = NewVideoInput;
            }
            else
            {
                [self.captureSession addInput:self.videoInput];
            }
            
            
            [self CameraSetOutputProperties];
            
            
            [self.captureSession commitConfiguration];
            
        }
    }
    
}


- (void) putFlashIntoDevice
{
    AVCaptureDevice *device = self.videoInput.device;
    
    [device lockForConfiguration:nil];
    
    if (self.flashMode == kFlashOn)
    {
        if ([device isFlashModeSupported:AVCaptureFlashModeOn])
        {
            [device setFlashMode:AVCaptureFlashModeOn];
        }
    }
    else if (self.flashMode == kFlashAuto)
    {
        if ([device isFlashModeSupported:AVCaptureFlashModeAuto])
        {
            [device setFlashMode:AVCaptureFlashModeAuto];
        }
    }
    else
    {
        if ([device isFlashModeSupported:AVCaptureFlashModeOff])
        {
            [device setFlashMode:AVCaptureFlashModeOff];
        }
    }
    
    [device unlockForConfiguration];
}


- (void)CameraSetOutputProperties
{
    // properties de camara
    
    [_output setOutputSettings:
     [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil]];
}


// Busca camara fronta o posterior

- (AVCaptureDevice *)CameraWithPosition:(AVCaptureDevicePosition)Position
{
    NSArray *Devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *Device in Devices)
    {
        if ([Device position] == Position)
        {
            return Device;
        }
    }
    return nil;
}

// devuelve la conexion activa del video

- (AVCaptureConnection*) getVideoConnection
{
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.output.connections)
    {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection)
        {
            break;
        }
    }
    
    return videoConnection;
}

#pragma mark - AVCaptureFileOutPut Delegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error
{
    LogInfo(@"finish record: %@", outputFileURL);
    
    if ([self.delegate respondsToSelector:@selector(CaptureSessionManagerDelegate_DidFinishVideoRecording:)]) {
        self.isSaveVideo = YES;
        self.urlLastVideo = outputFileURL;
        self.imgVideoThumbnail = [Utils generateThumbnailFromURLVideo:outputFileURL];
        [self.delegate CaptureSessionManagerDelegate_DidFinishVideoRecording:outputFileURL];
    }
}


- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"....");

    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer( sampleBuffer );
    CGSize imageSize = CVImageBufferGetEncodedSize( imageBuffer );
    // also in the 'mediaSpecific' dict of the sampleBuffer
    
   // NSLog( @"frame captured at %.fx%.f", imageSize.width, imageSize.height );
}



- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didPauseRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    NSLog(@" did pause");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didResumeRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    NSLog(@"   ***** DID RESUME RECORDING: %@", fileURL);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput willFinishRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"will Finish Recording");
}

// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    NSLog(@"imageFromSampleBuffer: called");
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

// ****************
//
//  TEMA AUDIO
//
// ***************

@end
