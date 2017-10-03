//
//  CaptureSessionManager.h
//  
//
//  Created by silenGSR on 5/11/15.
//  Copyright © 2015 Nibble development. All rights reserved.
//


#define kFlashAuto 0
#define kFlashOn 1
#define kFlashOff 2




#import <QuartzCore/QuartzCore.h>

#import <Foundation/Foundation.h>

#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>


#import <AVFoundation/AVFoundation.h>


@protocol CaptureSessionManagerDelegate <NSObject>

- (void) CaptureSessionManagerDelegate_PhotoTaked:(UIImage*) photo;
- (void) CaptureSessionManagerDelegate_PhotoFailed;
- (void) CaptureSessionManagerDelegate_EndProcessCIImage;
- (void) showNotAuthorizeAudio:(BOOL) isAudio isCamera:(BOOL) isCamera isGalery:(BOOL) isGalery;

- (void) CaptureSessionManagerDelegate_DidFinishVideoRecording:(NSURL*) url;
- (void) CaptureSessionStartTimerVideo;

@end

@interface CaptureSessionManager : NSObject <
AVCaptureFileOutputRecordingDelegate,
AVCaptureAudioDataOutputSampleBufferDelegate,
AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, weak) id <CaptureSessionManagerDelegate> delegate;

@property UIDeviceOrientation deviceOrientation;
@property BOOL isRunning;
@property NSInteger flashMode;

@property (retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (retain) AVCaptureSession *captureSession;
@property (retain) AVCaptureDevice *videoDevice;
@property (retain) AVCaptureDeviceInput *videoInput;
@property (retain) AVCaptureDevice *audioCapture;

@property (retain) AVCaptureDeviceInput * audioInput;

//audioDevice = [AVCaptureDevice
@property (retain) AVCaptureStillImageOutput *output;

@property (retain) AVCaptureVideoDataOutput *videoDataOutput;
@property (retain) AVCaptureMovieFileOutput *movieFileOutput;
@property (assign) UIImageOrientation orientationLastPhoto;
@property (retain) UIImage *lastPhotoTaked;
//@property (retain) CIImage *lastPhotoCI;

@property (retain) UIImage *lastPhotoTakedSmall;
//@property (retain) CIImage *lastPhotoCISmall;

@property BOOL isSaveVideo;
@property (retain) NSURL *urlLastVideo;
@property UIImage *imgVideoThumbnail;

@property AVCaptureSessionPreset presetCam;
@property BOOL isFrontCamera;

- (id)initWithFrame:(CGRect)frame withDel:(id<CaptureSessionManagerDelegate>)del withPresset:(AVCaptureSessionPreset) preset;
- (id)initWithFrame:(CGRect)frame;
- (void) isAvailableAuthorization;
//- (CIImage*) getCIImageForFilter;
//- (CIImage*) getCIImageForFilterSmall;

- (void)takePhoto;
- (void)toggleCam;
- (void)startRunning;
- (void)stopRunning;

- (void) generateAndSaveInternalImagesAfterTakePhotoWithPhoto:(UIImage*) photo;
- (void) tapToFocus:(UITapGestureRecognizer* ) singleTap inContainerView:(UIView*) containerView;

//- (void) beginRecord;
- (void) stopVideoRecord;

- (void) prepareForvideo;
- (void) prepareForPhoto;

- (void) resetPhoto;

@end
