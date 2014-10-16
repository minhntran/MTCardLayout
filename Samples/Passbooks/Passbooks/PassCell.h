#import <UIKit/UIKit.h>

@interface PassCell : UICollectionViewCell

@property (nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) IBOutlet UIButton *infoButton;
@property (nonatomic) IBOutlet UIButton *doneButton;

- (void)flipTransitionWithOptions:(UIViewAnimationOptions)options halfway:(void (^)(BOOL finished))halfway completion:(void (^)(BOOL finished))completion;

@end
