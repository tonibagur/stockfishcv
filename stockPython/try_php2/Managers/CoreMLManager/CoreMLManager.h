//
//  CoreMLManager.h
//  Stockfish
//
//  Created by Omar on 29/9/17.
//

#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>
#import <Vision/Vision.h>
#import "PythonManager.h"

//typedef void (^CoreMLManagerCompletionHandler)(BOOL succes, NSMutableArray* _Nullable arrResultPieces, NSError * _Nullable error);
//typedef void (^CoreMLManagerSpecialCompletionHandler)(BOOL succes, MLMultiArray* _Nullable arrMulti, NSError * _Nullable error);


typedef void (^CoreMLManagerCompletionPieces)(BOOL succes, NSMutableArray* _Nullable arrResultPieces, NSError * _Nullable error);
typedef void (^CoreMLManagerCompletionCGRectTupla)(BOOL succes, CGRect rectResultTupla, NSError * _Nullable error);

@protocol CoreMLDelegate <NSObject>

@end


@interface CoreMLManager : NSObject
{
    CoreMLManagerCompletionPieces completionPieces;
     CoreMLManagerCompletionCGRectTupla  completionCGRect;
    PythonManager *python;
}

@property (nonatomic, weak) id  <CoreMLDelegate> _Nullable delegate;

@property (nonatomic, retain) VNCoreMLModel * _Nullable mlEngine;
@property (nonatomic, retain) VNCoreMLRequest * _Nullable mlRequest;
@property (nonatomic, retain) MLModel *_Nullable modelPieces;

@property (nonatomic, strong) NSArray* _Nullable results;
@property BOOL isAvailable;


- (void) setupModelForPieces;
- (void) setupModelForPythonResult;

- (void) closeAll;


- (void) getChessPiecesWithImage:(UIImage*_Nullable) image withCompletion:(CoreMLManagerCompletionPieces _Nullable ) completion;
- (void) getCGRectTuplaPythonWithImage:(UIImage*_Nullable) image withCompletion:(CoreMLManagerCompletionCGRectTupla _Nullable ) completion;
@end
