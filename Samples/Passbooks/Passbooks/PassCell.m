#import "PassCell.h"

@interface PassCell()
{
	CGFloat _shadowWidth;
}
@end

@implementation PassCell

- (void)layoutSubviews
{
	[super layoutSubviews];

	CGRect bounds = self.bounds;
	if (_shadowWidth != bounds.size.width)
	{
		if (_shadowWidth == 0)
		{
			[self.layer setMasksToBounds:NO ];
			[self.layer setShadowColor:[[UIColor blackColor ] CGColor ] ];
			[self.layer setShadowOpacity:0.5 ];
			[self.layer setShadowRadius:5.0 ];
			[self.layer setShadowOffset:CGSizeMake( 0 , 0 ) ];
			self.layer.cornerRadius = 5.0;
		}
		[self.layer setShadowPath:[[UIBezierPath bezierPathWithRect:bounds ] CGPath ] ];
		_shadowWidth = bounds.size.width;
	}
}

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
