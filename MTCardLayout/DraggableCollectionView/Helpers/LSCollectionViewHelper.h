//
//  Copyright (c) 2013 Luke Scott
//  https://github.com/lukescott/DraggableCollectionView
//  Distributed under MIT license
//

#import <UIKit/UIKit.h>

@interface LSCollectionViewHelper : NSObject <UIGestureRecognizerDelegate>

- (id)initWithCollectionView:(UICollectionView *)collectionView;
- (void)unbindFromCollectionView:(UICollectionView *)collectionView;

@property (nonatomic, readonly, weak) UICollectionView *collectionView;
@property (nonatomic, readonly) UIGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, readonly) UIGestureRecognizer *panPressGestureRecognizer;
@property (nonatomic, assign) UIEdgeInsets scrollingEdgeInsets;
@property (nonatomic, assign) CGFloat scrollingSpeed;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, readonly) NSIndexPath *indexPathForMovingItem;
@property (nonatomic, strong) UIImageView *dropOnToDeleteView;
@end
