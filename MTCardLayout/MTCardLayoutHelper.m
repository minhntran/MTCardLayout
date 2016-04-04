#import "MTCardLayoutHelper.h"
#import "UICollectionView+CardLayout.h"

static int kObservingCollectionViewOffset;
static NSString * const kContentOffsetKeyPath = @"contentOffset";

@interface MTCardLayoutHelper() <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UICollectionView *collectionView;

@property (nonatomic, strong) UITapGestureRecognizer * tapGestureRecognizer;

@end

@implementation MTCardLayoutHelper

- (id)initWithCollectionView:(UICollectionView *)collectionView
{
    self = [super init];
    if (self)
    {
        self.collectionView = collectionView;
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(handleTapGesture:)];
        self.tapGestureRecognizer.delegate = self;
        [self.collectionView addGestureRecognizer:self.tapGestureRecognizer];
        
        [collectionView addObserver:self
						 forKeyPath:kContentOffsetKeyPath
							options:0
							context:&kObservingCollectionViewOffset];
        
    }
    return self;
}

- (void)unbindFromCollectionView:(UICollectionView *)collectionView
{
	[collectionView removeObserver:self forKeyPath:kContentOffsetKeyPath context:&kObservingCollectionViewOffset];
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
                
                [self.collectionView setViewMode:MTCardLayoutViewModePresenting animated:YES completion:^(BOOL finished) {
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

#pragma mark - Tap gesture

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.tapGestureRecognizer)
    {
        CGPoint point = [gestureRecognizer locationInView:self.collectionView];
        id<UICollectionViewDelegate_Draggable> delegate = (id<UICollectionViewDelegate_Draggable>)self.collectionView.delegate;
        if ([delegate respondsToSelector:@selector(collectionView:shouldRecognizeTapGestureAtPoint:)] &&
            ![delegate collectionView:self.collectionView shouldRecognizeTapGestureAtPoint:point]) {
            return NO;
        }
    }
    
    return YES;
}

- (void)handleTapGesture:(UITapGestureRecognizer *)gestureRecognizer
{
    if (self.viewMode == MTCardLayoutViewModePresenting) {
        [self.collectionView setViewMode:MTCardLayoutViewModeDefault animated:YES completion:nil];
        NSArray *selectedIndexPaths = [self.collectionView indexPathsForSelectedItems];
        [selectedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath * indexPath, NSUInteger idx, BOOL *stop) {
            [self.collectionView deselectAndNotifyDelegate:indexPath];
        }];
    } else { // MTCardLayoutViewModeDefault
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
        if (indexPath) {
            [self.collectionView selectAndNotifyDelegate:indexPath];
        }
    }
}

@end