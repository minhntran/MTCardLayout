#import <UIKit/UIKit.h>
#import "MTCommonTypes.h"

@interface UICollectionView (CardLayout)

@property (nonatomic) MTCardLayoutViewMode viewMode;

- (void)setViewMode:(MTCardLayoutViewMode)viewMode animated:(BOOL)animated completion:(void (^)(BOOL))completion;

- (void)selectAndNotifyDelegate:(NSIndexPath *)indexPath;
- (void)deselectAndNotifyDelegate:(NSIndexPath *)indexPath;

@end
