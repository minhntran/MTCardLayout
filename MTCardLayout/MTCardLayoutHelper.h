#import <UIKit/UIKit.h>
#import "MTCommonTypes.h"

@interface MTCardLayoutHelper : NSObject

@property (nonatomic) MTCardLayoutViewMode viewMode;

- (id)initWithCollectionView:(UICollectionView *)collectionView;
- (void)unbindFromCollectionView:(UICollectionView *)collectionView;

@end