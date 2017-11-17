/*
 Stockfish, a chess program for iOS.
 Copyright (C) 2004-2014 Tord Romstad, Marco Costalba, Joona Kiiski
 
 Stockfish is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 Stockfish is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "BoardViewController.h"
#import "Options.h"
#import "SelectedPieceView.h"
#import "SetupBoardView.h"
#import "SetupViewController.h"
#import "SideToMoveController.h"

#import "CoreMLManager.h"

#import "PointsVCViewController.h"

@implementation SetupViewController 
{
    CameraVC *camVC;
}

@synthesize boardViewController;

- (id)initWithBoardViewController:(BoardViewController *)bvc
                              fen:(NSString *)aFen {
    if (self = [super init]) {
        [self setTitle: @"Board"];
        boardViewController = bvc;
        fen = aFen;
        [self setPreferredContentSize: CGSizeMake(320.0f, 418.0f)];
    }
    return self;
}

- (void) addButtonToCam
{
    CGRect r = [UIScreen mainScreen].bounds;
    UIButton *btCustomCam  = [UIButton buttonWithType:UIButtonTypeSystem];
    btCustomCam.tintColor = [UIColor redColor];
    btCustomCam.frame = CGRectMake(0, 0, 260, 55);
    btCustomCam.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    btCustomCam.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    btCustomCam.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
    [btCustomCam setTitle:@"New ChessBoard\ntaking Camera Photo" forState:UIControlStateNormal];
    btCustomCam.center = CGPointMake(r.size.width/2, r.size.height-40);
    [btCustomCam addTarget:self action:@selector(btnPressOnCam) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btCustomCam];
}

- (void)loadView {
    UIView *contentView;
    CGRect r = [[UIScreen mainScreen] applicationFrame];
    contentView = [[UIView alloc] initWithFrame: r];
    [self setView: contentView];
    [contentView setBackgroundColor: [UIColor colorWithRed: 0.934 green: 0.934 blue: 0.953 alpha: 1.0]];
    
    // Create a UISegmentedControl as a menu at the top of the screen
    NSArray *buttonNames = @[@"Clear", @"Cancel", @"Done"];
    menu = [[UISegmentedControl alloc] initWithItems: buttonNames];
    [menu setMomentary: YES];
    //[menu setSegmentedControlStyle: UISegmentedControlStyleBar];
    [menu setFrame: CGRectMake(0.0f, 0.0f, 300.0f, 20.0f)];
    [menu addTarget: self
             action: @selector(buttonPressed:)
   forControlEvents: UIControlEventValueChanged];
    [[self navigationItem] setTitleView: menu];
    
    [self addButtonToCam];
    BOOL isIpad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    
    // Selected piece view
    SelectedPieceView *spv;
    
    // I have no idea why, but the vertical view coordinates are different in
    // iOS 7 and iOS 8. We need to compensate for this to be able to handle both
    // OS versions correctly.
    BOOL isRunningiOS7 = [UIDevice currentDevice].systemVersion.floatValue < 8.0f;
    float sqSize;
    float dy = isIpad ? 50.0f : 64.0f;
    if (isIpad && isRunningiOS7) dy -= 34.0f;
    
    if (isIpad) {
        sqSize = 40.0f;
        spv = [[SelectedPieceView alloc] initWithFrame:CGRectMake(40.0f, 320.0f + dy, 240.0f, 80.0f)];
    } else {
        sqSize = [UIScreen mainScreen].applicationFrame.size.width / 8.0f;
        spv = [[SelectedPieceView alloc]
               initWithFrame:CGRectMake(40.0f, 8*sqSize + 74.0f, 6*sqSize, 2*sqSize)];
    }
    [contentView addSubview: spv];
    
    // Setup board view
    dy = isIpad ? 40.0f : 64.0f;
    if (isIpad && isRunningiOS7) dy -= 34.0f;
    boardView = [[SetupBoardView alloc]
                 initWithController: self
                 frame: CGRectMake(0.0f, dy, 8*sqSize, 8*sqSize)
                 fen: fen
                 phase: PHASE_EDIT_BOARD];
    [contentView addSubview: boardView];
    [boardView setSelectedPieceView: spv];
    
}

- (void) btnPressOnCam
{
#if TARGET_IPHONE_SIMULATOR
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openDrawPoints:) name:@"points" object:nil];
    
    CoreMLManager *mlPython = [CoreMLManager initModelForType:MLSetupForPython];
    
    UIImage *image = [UIImage imageNamed:@"tablero"];
    
    [mlPython getCGRectTuplaPythonWithImage:image
                             withCompletion:^(BOOL succes, CGRect rectResultTupla, NSError * _Nullable error)
     {
         NSLog(@"\n.\n                      end proces python\n.");
         NSLog(@"success: %@", succes?@"YES":@"NO");
         if (succes)
         {
             NSLog(@"result CGRect: (%.0f, %.0f, %0.f, %.0f)", rectResultTupla.origin.x, rectResultTupla.origin.y, rectResultTupla.size.width, rectResultTupla.size.height);
             
             if (rectResultTupla.size.width > 0 && rectResultTupla.size.height > 0) {
                 
                 // Si estubieramos en DISPOSITIVO recortaríamos la imagen que nos dijo Python y la pasaríamos por el ML de PIECES,
                 // en este caso en concreto, las pruebas de Simulador es sólo para dibujar los puntos a modo visual, no requerimos saber las piezas

             }
             else {
                 NSLog(@"*********** Height or Width Equals ZERO");
             }
         }
     }];

#else
    [self openCamera];
#endif
    
}

- (void) openCamera
{
    if (!camVC) {
        camVC = [CameraVC new];
        camVC.delegate = self;
    }
    
    [self presentViewController:camVC animated:YES completion:nil];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void) openDrawPoints:(NSNotification*)noti
{
    UIView *vPoints = (UIView*) noti.object;
    if (![vPoints isKindOfClass:[UIView class]]) return;
    
    PointsVCViewController *points = [PointsVCViewController new];
    
    [self presentViewController:points animated:YES completion:^{
        [points InsertView:vPoints];
    }];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) openTheML:(UIImage*) image
{
    NSLog(@"openML");
    [boardView clear];
    
    CoreMLManager *ml = [CoreMLManager initModelForType:MLSetupForChessPieces];
    
    [ml getChessPiecesWithImage:image
                 withCompletion:^(BOOL succes, NSMutableArray * _Nullable arrResultPieces, NSError * _Nullable error)
     {
         
         NSLog(@"success: %@", succes?@"YES":@"NO");
         if (error) NSLog(@"error of getChessPiecesWithImage: %@",error);
         
         dispatch_async(dispatch_get_main_queue(), ^{
             
             for (NSDictionary *dic in arrResultPieces)
             {
                 NSInteger x = [dic[@"x"]integerValue];
                 NSInteger y = [dic[@"y"]integerValue];
                 Piece piece = [boardView pieceFromMLByCode:[dic[@"z"]integerValue]];
                 
                 if (piece == NO_PIECE) {
                     [boardView removePieceOnSquare:make_square(File(y), Rank(7-x))];
                 }
                 else {
                     [boardView addPiece:[boardView pieceFromMLByCode:[dic[@"z"]integerValue]] onSquare:make_square(File(y), Rank(7-x))];
                 }
             }
             
             [ml closeAll];
             [boardView evaluateIsGameAvailable];
             
         });
     }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)buttonPressed:(id)sender {
    switch([sender selectedSegmentIndex]) {
        case 0:
            [boardView clear];
            break;
        case 1:
            [boardViewController editPositionCancelPressed];
            break;
        case 2:
            SideToMoveController *stmc = [[SideToMoveController alloc]
                                          initWithFen: [boardView fen]];
            [[self navigationController] pushViewController: stmc animated: YES];
            break;
    }
}

- (void)disableDoneButton {
    [menu setEnabled: NO forSegmentAtIndex: 2];
}

- (void)enableDoneButton {
    [menu setEnabled: YES forSegmentAtIndex: 2];
}

#pragma mark - CameraVC Delegate
- (void) cameraDidSelectPhoto:(UIImage *)imageSelected
{
    NSLog(@"did select photo from camera");
    NSLog(@"%@", imageSelected);
    [self openTheML:imageSelected];
}




@end
