#import "PassCell.h"

@interface PassCell()
{
	CGFloat _shadowWidth;
}
@end

@implementation PassCell

- (void)setSelected:(BOOL)selected
{
    self.backgroundColor = selected ? [UIColor lightGrayColor] : [UIColor whiteColor];
}

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
			[self.layer setShadowRadius:3.0 ];
			[self.layer setShadowOffset:CGSizeMake( 0 , 0 ) ];
		}
		[self.layer setShadowPath:[[UIBezierPath bezierPathWithRect:bounds ] CGPath ] ];
		_shadowWidth = bounds.size.width;
	}
}

@end
