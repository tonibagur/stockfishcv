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

@implementation SetupViewController

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
   
    UIButton *btCustomCam  = [UIButton buttonWithType:UIButtonTypeSystem];
    btCustomCam.tintColor = [UIColor redColor];
    btCustomCam.frame = CGRectMake(0, 0, 180, 50);
    btCustomCam.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
    [btCustomCam setTitle:@"Camera Photo" forState:UIControlStateNormal];
    btCustomCam.center = CGPointMake(r.size.width/2, r.size.height-10);
    [btCustomCam addTarget:self action:@selector(btnPressOnCam) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btCustomCam];
    
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

- (Square) getSquareByIndex:(NSInteger) index
{
    // FILA 1
    if (index == 0) return SQ_A1;
    else if (index == 1) return SQ_B1;
    else if (index == 2) return SQ_C1;
    else if (index == 3) return SQ_D1;
    else if (index == 4) return SQ_E1;
    else if (index == 5) return SQ_F1;
    else if (index == 6) return SQ_G1;
    else if (index == 7) return SQ_H1;
    
    // FILA 2
    else if (index == 8) return SQ_A2;
    else if (index == 9) return SQ_B2;
    else if (index == 10) return SQ_C2;
    else if (index == 11) return SQ_D2;
    else if (index == 12) return SQ_E2;
    else if (index == 13) return SQ_F2;
    else if (index == 14) return SQ_G2;
    else if (index == 15) return SQ_H2;
    
    // FILA 3
    else if (index == 16) return SQ_A3;
    else if (index == 17) return SQ_B3;
    else if (index == 18) return SQ_C3;
    else if (index == 19) return SQ_D3;
    else if (index == 20) return SQ_E3;
    else if (index == 21) return SQ_F3;
    else if (index == 22) return SQ_G3;
    else if (index == 23) return SQ_H3;
    
    // FILA 4
    else if (index == 24) return SQ_A4;
    else if (index == 25) return SQ_B4;
    else if (index == 26) return SQ_C4;
    else if (index == 27) return SQ_D4;
    else if (index == 28) return SQ_E4;
    else if (index == 29) return SQ_F4;
    else if (index == 30) return SQ_G4;
    else if (index == 31) return SQ_H4;
    
    
    // FILA 5
    else if (index == 32) return SQ_A5;
    else if (index == 33) return SQ_B5;
    else if (index == 34) return SQ_C5;
    else if (index == 35) return SQ_D5;
    else if (index == 36) return SQ_E5;
    else if (index == 37) return SQ_F5;
    else if (index == 38) return SQ_G5;
    else if (index == 39) return SQ_H5;
    
    // FILA 6
    else if (index == 40) return SQ_A6;
    else if (index == 41) return SQ_B6;
    else if (index == 42) return SQ_C6;
    else if (index == 43) return SQ_D6;
    else if (index == 44) return SQ_E6;
    else if (index == 45) return SQ_F6;
    else if (index == 46) return SQ_G6;
    else if (index == 47) return SQ_H6;
    
    // FILA 7
    else if (index == 48) return SQ_A7;
    else if (index == 49) return SQ_B7;
    else if (index == 50) return SQ_C7;
    else if (index == 51) return SQ_D7;
    else if (index == 52) return SQ_E7;
    else if (index == 53) return SQ_F7;
    else if (index == 54) return SQ_G7;
    else if (index == 55) return SQ_H7;

    // FILA 6
    else if (index == 56) return SQ_A8;
    else if (index == 57) return SQ_B8;
    else if (index == 58) return SQ_C8;
    else if (index == 59) return SQ_D8;
    else if (index == 60) return SQ_E8;
    else if (index == 61) return SQ_F8;
    else if (index == 62) return SQ_G8;
    else if (index == 63) return SQ_H8;
    
    return SQ_NONE;
}

- (void) btnPressOnCam
{
    if (!ml) {
        ml = [CoreMLManager  new];
        [ml setupModel];
    }
    
    [ml executeImage:nil withCompletion:^(BOOL succes, NSMutableArray * _Nullable arrResultPieces, NSError * _Nullable error)
    {
        NSLog(@"success: %@", succes?@"YES":@"NO");
        NSLog(@"error of completion: %@",error);
        NSLog(@"arrResults: %@", arrResultPieces);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            for (NSDictionary *dic in arrResultPieces)
            {
                Piece piece = [boardView pieceFromMLByCode:[dic[@"z"]integerValue]];
                if (piece == NO_PIECE) {
                    [boardView removePieceOnSquare:make_square(File([dic[@"x"]integerValue]), Rank([dic[@"y"]integerValue]))];
                }
                else {
                    [boardView addPiece:[boardView pieceFromMLByCode:[dic[@"z"]integerValue]] onSquare:make_square(File([dic[@"x"]integerValue]), Rank([dic[@"y"]integerValue]))];
                }
            }
            });
    }];
    

    return;
    
         [boardView addPiece:[boardView.selectedPieceView selectedPiece] onSquare:make_square(File(0), Rank(2))];
   // [boardView addPiece:[boardView.selectedPieceView selectedPiece] onSquare:make_square(File(0), Rank(7))];
   
    
 //   [boardView addPiece:BK onSquare:make_square(File(4), Rank(2))];
    
    
   //     [boardView addPiece:WK onSquare:[self getSquareByIndex:2]];
    
    return;
//    [boardView addPiece:BK onSquare:SQ_B1];
    for (int i = 0; i < 64; i++) {
        
        [boardView addPiece:[boardView.selectedPieceView selectedPiece] onSquare:[self getSquareByIndex:i]];
    }
    
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




@end
