#import <UIKit/UIKit.h>
#import "MTCardLayout.h"

@interface MTCardCollectionViewController : UICollectionViewController

@property (nonatomic, readonly) MTCardLayout *cardLayout;

- (void)setPresenting:(BOOL)presenting animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

@end
