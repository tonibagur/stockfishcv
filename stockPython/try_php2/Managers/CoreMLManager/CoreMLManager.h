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


typedef void (^CoreMLManagerCompletionPieces)(BOOL succes, NSMutableArray* _Nullable arrResultPieces, NSError * _Nullable error);
typedef void (^CoreMLManagerCompletionCGRectTupla)(BOOL succes, CGRect rectResultTupla, NSError * _Nullable error);

typedef enum : NSUInteger {
    MLSetupForPython,
    MLSetupForChessPieces,
} MLSetup;

@protocol CoreMLDelegate <NSObject>

@end


@interface CoreMLManager : NSObject
{
    CoreMLManagerCompletionPieces completionPieces;
    CoreMLManagerCompletionCGRectTupla  completionCGRect;
    PythonManager *python;
    MLSetup typeModel;
}

@property (nonatomic, weak) id  <CoreMLDelegate> _Nullable delegate;

@property (nonatomic, retain) VNCoreMLModel * _Nullable mlEngine;
@property (nonatomic, retain) VNCoreMLRequest * _Nullable mlRequest;
@property (nonatomic, retain) MLModel *_Nullable model;

@property (nonatomic, strong) NSArray* _Nullable results;
@property BOOL isAvailable;


#pragma mark - Initialize


/**
 First declaration Manager
 
 @param type set model type python or pieces
 @return objectManager
 */
+ (instancetype _Nonnull ) initModelForType:(MLSetup) type;


/**
 setup manager for model type
 
 @param type set model type python or pieces
 */
- (void) setupModelForType:(MLSetup) type;

#pragma mark - Models Results

/*************************************************************************
 *
 *  GET MODELS RESULTS
 *
 *************************************************************************/

/**
 Method to get pieces chess in board (only works with setup init -> MLSetupForPython)
 
 @param image original UIImage
 @param completion completionResult
 */
- (void) getChessPiecesWithImage:(UIImage*_Nullable) image withCompletion:(CoreMLManagerCompletionPieces _Nullable ) completion;

/**
 Method to get CGRect in python for max/min rectangle (only works with setup init -> MLSetupForChessPieces)
 
 @param image original UIImage
 @param completion completionResult
 */
- (void) getCGRectTuplaPythonWithImage:(UIImage*_Nullable) image withCompletion:(CoreMLManagerCompletionCGRectTupla _Nullable ) completion;



- (void) closeAll;



@end
