#import <objc/runtime.h>
#import "UICollectionView+CardLayout.h"
#import "MTCollectionViewCardLayoutHelper.h"

static const char * MTCollectionViewCardLayoutHelperKey = "UICollectionViewCardLayoutHelper";

@implementation UICollectionView(CardLayout)

- (MTCollectionViewCardLayoutHelper *)getCardLayoutHelper
{
    MTCollectionViewCardLayoutHelper *helper = objc_getAssociatedObject(self, MTCollectionViewCardLayoutHelperKey);
    if(helper == nil) {
        helper = [[MTCollectionViewCardLayoutHelper alloc] initWithCollectionView:self];
        objc_setAssociatedObject(self, MTCollectionViewCardLayoutHelperKey, helper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return helper;
}

- (UIImageView *)dragUpToDeleteConfirmView
{
    return [self getCardLayoutHelper].dragUpToDeleteConfirmView;
}

- (void)setDragUpToDeleteConfirmView:(UIImageView *)dragUpToDeleteConfirmView
{
    [[self getCardLayoutHelper] setDragUpToDeleteConfirmView:dragUpToDeleteConfirmView];
}

- (BOOL)presenting
{
    return [self getCardLayoutHelper].presenting;
}

- (void)setPresenting:(BOOL)presenting
{
    [self setPresenting:presenting animated:NO completion:nil];
}

- (void)setPresenting:(BOOL)presenting animated:(BOOL)animated completion:(void (^)(BOOL))completion
{
    void (^setPresenting)() = ^{
        [self getCardLayoutHelper].presenting = presenting;
        self.scrollEnabled = !presenting;
        
        [self.collectionViewLayout invalidateLayout];
    };

    if (animated)
    {
        [self performBatchUpdates:^{
            setPresenting();
        } completion:completion];
    }
    else
    {
        setPresenting();
        if (completion) completion(TRUE);
    }
}

- (UITapGestureRecognizer *)cardLayoutTapGestureRecognizer
{
	return [self getCardLayoutHelper].tapGestureRecognizer;
}

- (UIPanGestureRecognizer *)cardLayoutPanGestureRecognizer
{
	return [self getCardLayoutHelper].panGestureRecognizer;
}

@end

@implementation UICollectionViewCell(CardLayout)

- (void)flipTransitionWithOptions:(UIViewAnimationOptions)options halfway:(void (^)(BOOL finished))halfway completion:(void (^)(BOOL finished))completion
{
	CGFloat degree = (options & UIViewAnimationOptionTransitionFlipFromRight) ? -M_PI_2 : M_PI_2;
	
	CGFloat duration = 0.4;
	CGFloat distanceZ = 2000;
	CGFloat translationZ = self.frame.size.width / 2;
	CGFloat scaleXY = (distanceZ - translationZ) / distanceZ;
	
	CATransform3D rotationAndPerspectiveTransform = CATransform3DIdentity;
	rotationAndPerspectiveTransform.m34 = 1.0 / -distanceZ; // perspective
	rotationAndPerspectiveTransform = CATransform3DTranslate(rotationAndPerspectiveTransform, 0, 0, translationZ);
	
	rotationAndPerspectiveTransform = CATransform3DScale(rotationAndPerspectiveTransform, scaleXY, scaleXY, 1.0);
	self.layer.transform = rotationAndPerspectiveTransform;
	
	[UIView animateWithDuration:duration / 2 animations:^{
		self.layer.transform = CATransform3DRotate(rotationAndPerspectiveTransform, degree, 0.0f, 1.0f, 0.0f);
	} completion:^(BOOL finished){
		if (halfway) halfway(finished);
		self.layer.transform = CATransform3DRotate(rotationAndPerspectiveTransform, -degree, 0.0f, 1.0f, 0.0f);
		[UIView animateWithDuration:duration / 2 animations:^{
			self.layer.transform = rotationAndPerspectiveTransform;
		} completion:^(BOOL finished){
			self.layer.transform = CATransform3DIdentity;
			if (completion) completion(finished);
		}];
	}];
}

@end
