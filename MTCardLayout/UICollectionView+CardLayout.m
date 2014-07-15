#import "UICollectionView+CardLayout.h"
#import "MTCardLayout.h"
#import <objc/runtime.h>

#define DRAG_CURVE_LIMIT 50.0
#define DRAG_ACTION_LIMIT 200.0

static const char * MTCollectionViewCardLayoutHelperKey = "UICollectionViewCardLayoutHelper";
static int kObservingCollectionViewOffset;

@interface MTCollectionViewCardLayoutHelper : NSObject

@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic) BOOL presenting;
@property (nonatomic) UIPanGestureRecognizer * panGestureRecognizer;
@property (nonatomic) UITapGestureRecognizer * tapGestureRecognizer;

@end

@implementation MTCollectionViewCardLayoutHelper

- (id)initWithCollectionView:(UICollectionView *)collectionView
{
    self = [super init];
    if (self)
    {
        self.collectionView = collectionView;
        [collectionView addObserver:self
                          forKeyPath:@"contentOffset"
                             options:0
                             context:&kObservingCollectionViewOffset];
        
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &kObservingCollectionViewOffset) {
        UICollectionView *collectionView = self.collectionView;
        if (collectionView && collectionView.dragging)
        {
            UIEdgeInsets edgeInsets = collectionView.contentInset;
            BOOL bounces = collectionView.bounces;
            
            if (collectionView.contentOffset.y < - 100 - edgeInsets.top && collectionView.scrollEnabled)
            {
                collectionView.contentInset = UIEdgeInsetsMake(-collectionView.contentOffset.y, edgeInsets.left, edgeInsets.bottom, edgeInsets.right);
                collectionView.bounces = NO;
                
                [self.collectionView setPresenting:YES animated:YES completion:^(BOOL finished) {
                    collectionView.contentInset = edgeInsets;
                    collectionView.bounces = bounces;
                }];
            }
        }
	}
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

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
        self.cardLayoutTapGestureRecognizer.enabled = presenting;
        self.cardLayoutPanGestureRecognizer.enabled = presenting;
        
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

- (void)deselect:(NSIndexPath *)indexPath
{
	[self deselectItemAtIndexPath:indexPath animated:NO];
    if ([self.delegate respondsToSelector:@selector(collectionView:didDeselectItemAtIndexPath:)])
        [self.delegate collectionView:self didDeselectItemAtIndexPath:indexPath];
}

- (void)enableCardLayoutGestures
{
    [self addGestureRecognizer:self.cardLayoutTapGestureRecognizer];
    [self addGestureRecognizer:self.cardLayoutPanGestureRecognizer];
}

#pragma mark - Tap gesture

- (UITapGestureRecognizer *)cardLayoutTapGestureRecognizer
{
    MTCollectionViewCardLayoutHelper *helper = [self getCardLayoutHelper];
	if (helper.tapGestureRecognizer == nil)
	{
		helper.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
        helper.tapGestureRecognizer.enabled = helper.presenting;
	}
	
	return helper.tapGestureRecognizer;
}

- (void)tapped:(id)sender
{
    if (!self.presenting) return;
    
    [self performBatchUpdates:^{
        NSArray *selectedIndexPaths = [self indexPathsForSelectedItems];
        [selectedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath * indexPath, NSUInteger idx, BOOL *stop) {
            [self deselect:indexPath];
        }];
        [self setPresenting:NO];
    } completion:nil];
}

#pragma mark - Pan gesture

- (UIPanGestureRecognizer *)cardLayoutPanGestureRecognizer
{
    MTCollectionViewCardLayoutHelper *helper = [self getCardLayoutHelper];
    if (helper.panGestureRecognizer == nil)
	{
		helper.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
		helper.panGestureRecognizer.maximumNumberOfTouches = 1;
        helper.panGestureRecognizer.enabled = helper.presenting;
	}
    
    return helper.panGestureRecognizer;
}

- (void)panned:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (!self.presenting) return;
    
    NSIndexPath *indexPath = [[self indexPathsForSelectedItems] firstObject];
    if (!indexPath) return;
    
    UICollectionViewCell *cell = [self cellForItemAtIndexPath:indexPath];
    
	UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
	CGRect originFrame = attributes.frame;
    
	if (gestureRecognizer.state != UIGestureRecognizerStateCancelled)
	{
		CGPoint translation = [gestureRecognizer translationInView:[cell superview]];
		CGFloat translatedY = translation.y < DRAG_ACTION_LIMIT ? DRAG_CURVE_LIMIT * atanf(translation.y / DRAG_CURVE_LIMIT) : translation.y;
		cell.frame = CGRectOffset(originFrame, 0, translatedY);
        
        if (translatedY >= DRAG_ACTION_LIMIT)
        {
            [self deselect:indexPath];
            [self performBatchUpdates:nil completion:nil];
            return;
        }
	}
	
	if (gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateCancelled)
	{
		[UIView animateWithDuration:0.3 animations:^{
			cell.frame = originFrame;
		} completion:nil];
	}
}

@end
