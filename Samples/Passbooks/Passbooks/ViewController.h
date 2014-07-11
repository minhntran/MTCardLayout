#import <UIKit/UIKit.h>
#import "SearchViewController.h"
#import "MTCardCollectionViewController.h"
#import "UICollectionView+Draggable.h"

@interface ViewController : MTCardCollectionViewController<SearchViewControllerDelegate, UICollectionViewDataSource_Draggable>

@end
