//
//  CameraVC.h
//  Stockfish
//
//  Created by Omar on 2/10/17.
//

#import <UIKit/UIKit.h>

@protocol CameraVCDelegate <NSObject>
- (void) cameraDidSelectPhoto:(UIImage*) imageSelected;
@end

@interface CameraVC : UIViewController
@property (weak, nonatomic) id <CameraVCDelegate> delegate;

@end
