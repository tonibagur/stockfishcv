//
//  CoreMLManager.h
//  Stockfish
//
//  Created by Omar on 29/9/17.
//

#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>
#import <Vision/Vision.h>

typedef void (^CoreMLManagerCompletionHandler)(BOOL succes, NSError * _Nullable error);

@protocol CoreMLDelegate <NSObject>

@end


@interface CoreMLManager : NSObject
{
    CoreMLManagerCompletionHandler completionHandler;
}

@property (nonatomic, weak) id  <CoreMLDelegate> _Nullable delegate;

@property (nonatomic, retain) VNCoreMLModel * _Nullable mlEngine;
@property (nonatomic, retain) VNCoreMLRequest * _Nullable mlRequest;

@property (nonatomic, strong) NSArray* _Nullable results;


- (void) setupModel;
- (void) executeImage:(UIImage*_Nullable) image withCompletion:(CoreMLManagerCompletionHandler _Nullable ) completion;
@end
