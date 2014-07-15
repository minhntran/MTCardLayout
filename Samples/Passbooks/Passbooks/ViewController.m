#import "ViewController.h"
#import "PassCell.h"
#import "MTCardLayout.h"
#import "MTDraggableCardLayout.h"
#import "UICollectionView+CardLayout.h"

@interface ViewController ()

@property (nonatomic, strong) SearchViewController *searchViewController;

@property (nonatomic, strong) NSMutableArray * items;

@end

@implementation ViewController

#pragma mark Status Bar color

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    self.items = [NSMutableArray arrayWithCapacity:20];
    for (int i = 0; i < 20; i++)
    {
        [self.items addObject:[NSString stringWithFormat:@"Item %d", i]];
    }

    self.searchViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"SearchViewController"];
    self.searchViewController.delegate = self;
	self.collectionView.backgroundView = self.searchViewController.view;
	
	UIImageView *deleteView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"trashcan"] highlightedImage:[UIImage imageNamed:@"trashcan_red"]];
	self.collectionView.deleteView = deleteView;
}

#pragma mark - UICollectionViewDatasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	PassCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"pass" forIndexPath:indexPath];

	cell.titleLabel.text = self.items[indexPath.item];
	return cell;
}

- (UIImage *)collectionView:(UICollectionView *)collectionView imageForDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
	UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
	CGSize size = cell.bounds.size;
	size.height = 72.0;
	
	UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
	CGContextRef context = UIGraphicsGetCurrentContext();
	[cell.layer renderInContext:context];
	
	UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}

- (CGAffineTransform)collectionView:(UICollectionView *)collectionView transformForDraggingItemAtIndexPath:(NSIndexPath *)indexPath duration:(NSTimeInterval *)duration
{
	return CGAffineTransformMakeScale(1.05f, 1.05f);
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSString * item = self.items[fromIndexPath.item];
    [self.items removeObjectAtIndex:fromIndexPath.item];
    [self.items insertObject:item atIndex:toIndexPath.item];
}

//- (void)collectionView:(UICollectionView *)collectionView didMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)toIndexPath
//{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.collectionView reloadData];
//    });
//}

- (CGPoint)collectionView:(UICollectionView *)collectionView deleteViewCenterForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGPointMake(50, 300);
}

- (void)collectionView:(UICollectionView *)collectionView deleteItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.items removeObjectAtIndex:indexPath.item];
}

//- (void)collectionView:(UICollectionView *)collectionView didDeleteItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.collectionView reloadData];
//    });
//}

#pragma mark SearchCell

- (void)searchControllerWillBeginSearch:(SearchViewController *)controller
{
    if (!self.collectionView.presenting)
    {
        [self.collectionView setPresenting:YES animated:YES completion:nil];
    }
}

- (void)searchControllerWillEndSearch:(SearchViewController *)controller
{
    if (self.collectionView.presenting)
    {
        [self.collectionView setPresenting:NO animated:YES completion:nil];
    }
}

@end
