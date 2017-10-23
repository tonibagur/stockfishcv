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
@property (nonatomic, retain) MLModel *_Nullable modelPieces;

@property (nonatomic, strong) NSArray* _Nullable results;
@property BOOL isAvailable;

- (void) setupModelForType:(MLSetup) type;

/*************************************************************************
 *
 *  Setup and Method to get pieces chess in board
 *
*************************************************************************/
 
- (void) setupModelForPieces;
- (void) getChessPiecesWithImage:(UIImage*_Nullable) image withCompletion:(CoreMLManagerCompletionPieces _Nullable ) completion;

/*************************************************************************
 *
 *  Setup and Method to get CGRect in python for max/min rectangle
 *
 *************************************************************************/

- (void) setupModelForPythonResult;
- (void) getCGRectTuplaPythonWithImage:(UIImage*_Nullable) image withCompletion:(CoreMLManagerCompletionCGRectTupla _Nullable ) completion;

- (void) closeAll;



@end
