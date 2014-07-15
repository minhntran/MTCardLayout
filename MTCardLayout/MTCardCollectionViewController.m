#import "MTCardCollectionViewController.h"
#import "MTCardLayout.h"
#import "UICollectionView+CardLayout.h"

@interface MTCardCollectionViewController ()


@end

@implementation MTCardCollectionViewController

- (MTCardLayout *)cardLayout
{
	return (MTCardLayout *)self.collectionViewLayout;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.collectionView enableCardLayoutGestures];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.collectionView setPresenting:YES animated:YES completion:nil];
}

@end
