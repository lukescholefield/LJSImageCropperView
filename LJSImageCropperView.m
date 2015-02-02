//
//  LJSImageCropperView.m
//
//  Copyright (c) 2015 Luke Scholefield
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "LJSImageCropperView.h"

@interface LJSImageCropperView () <UIScrollViewDelegate>

@property (strong, nonatomic) UIView *containerView; // this helps clean up the ugly CALayer animation on rotate

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;

@property (strong, nonatomic) UIView *overlayView;
@property (strong, nonatomic) CALayer *fadeLayer;
@property (strong, nonatomic) CAShapeLayer *maskLayer;
@property (strong, nonatomic) CALayer *cropBoxBorderLinesLayer;
@property (strong, nonatomic) CALayer *cropBoxHorizontalLinesLayer;
@property (strong, nonatomic) CALayer *cropBoxVerticalLinesLayer;

@property (strong, nonatomic) UIView *cropBoxView;

@property (assign, nonatomic) CGFloat currentRotationAngle;
@property (assign, nonatomic) CGFloat lastCompletedRotationAngle;
@property (assign, nonatomic) CGFloat initialZoomScale;

@property (strong, nonatomic) UIRotationGestureRecognizer *rotationGestureRecognizer;

@property (assign, nonatomic, getter=isRotating) BOOL rotating;
@property (assign, nonatomic, getter=isFirstLayout) BOOL firstLayout;

@end


@implementation LJSImageCropperView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.containerView = [[UIView alloc] init];
        self.containerView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        [self addSubview:self.containerView];
        
        self.clipsToBounds = YES;
        self.scrollView = [[UIScrollView alloc] init];
        self.scrollView.delegate = self;
        self.scrollView.clipsToBounds = NO;
        self.scrollView.alwaysBounceHorizontal = YES;
        self.scrollView.alwaysBounceVertical = YES;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.showsVerticalScrollIndicator = NO;
        [self.containerView addSubview:self.scrollView];
        
        self.imageView = [[UIImageView alloc] init];
        [self.scrollView addSubview:self.imageView];
        
        self.cropBoxView = [[UIView alloc] init];
        [self.containerView addSubview:self.cropBoxView];
        
        self.scrollView.minimumZoomScale = 1.0;
        self.scrollView.maximumZoomScale = 2.0;
        
        [self addGestureRecognizer:self.scrollView.panGestureRecognizer];
        [self addGestureRecognizer:self.scrollView.pinchGestureRecognizer];
        
        self.rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotationGestureRecognized:)];
        [self addGestureRecognizer:self.rotationGestureRecognizer];
        
        self.overlayView = [[UIView alloc] init];
        [self.containerView addSubview:self.overlayView];
        
        self.fadeLayer = [[CALayer alloc] init];
        self.fadeLayer.backgroundColor = [[UIColor colorWithWhite:0.0 alpha:0.5] CGColor];
        [self.overlayView.layer addSublayer:self.fadeLayer];
        
        self.maskLayer = [CAShapeLayer layer];
        self.maskLayer.fillRule = kCAFillRuleEvenOdd;
        self.maskLayer.fillColor  = [[UIColor blackColor] CGColor];
        self.fadeLayer.mask = self.maskLayer;
        
        CGFloat screenScale = [UIScreen mainScreen].scale;
        
        self.cropBoxBorderLinesLayer = [[CALayer alloc] init];
        self.cropBoxBorderLinesLayer.borderColor = [[UIColor whiteColor] CGColor];
        self.cropBoxBorderLinesLayer.borderWidth = 1.0/screenScale;
        self.cropBoxBorderLinesLayer.opacity = 0.7;
        [self.overlayView.layer addSublayer:self.cropBoxBorderLinesLayer];
        
        self.cropBoxHorizontalLinesLayer = [[CALayer alloc] init];
        self.cropBoxHorizontalLinesLayer.borderColor = [[UIColor colorWithWhite:1.0 alpha:0.5*screenScale] CGColor];
        self.cropBoxHorizontalLinesLayer.borderWidth = 1.0/screenScale;
        [self.cropBoxBorderLinesLayer addSublayer:self.cropBoxHorizontalLinesLayer];
        
        self.cropBoxVerticalLinesLayer = [[CALayer alloc] init];
        self.cropBoxVerticalLinesLayer.borderColor = [[UIColor colorWithWhite:1.0 alpha:0.5*screenScale] CGColor];
        self.cropBoxVerticalLinesLayer.borderWidth = 1.0/screenScale;
        [self.cropBoxBorderLinesLayer addSublayer:self.cropBoxVerticalLinesLayer];
    }
    return self;
}

- (void)layoutSubviews
{
    // we need to preserve some state, so lets make notes before we do any new layout
    CGRect visibleRect;
    if (!self.isFirstLayout) {
        visibleRect = [self.scrollView convertRect:self.scrollView.bounds toView:self.imageView];
    } else {
        self.firstLayout = NO;
        
        if (self.image.size.width/self.cropSize.width < self.image.size.height/self.cropSize.height) {
            CGFloat height = self.image.size.width * self.cropSize.height / self.cropSize.width;
            visibleRect = CGRectMake(0.0,
                                     (self.image.size.height - height)/2.0,
                                     self.image.size.width,
                                     height);
        } else {
            CGFloat width = self.image.size.height * self.cropSize.width / self.cropSize.height;
            visibleRect = CGRectMake((self.image.size.height - width)/2.0,
                                     0.0,
                                     width,
                                     self.image.size.height);
        }
    }
    
    [super layoutSubviews];
    
    CGFloat maxDimension = MAX(self.frame.size.width, self.frame.size.height);
    
    self.containerView.frame = CGRectMake((self.frame.size.width - maxDimension)/2.0,
                                          (self.frame.size.height - maxDimension)/2.0,
                                          maxDimension,
                                          maxDimension);
    
    self.overlayView.frame = self.containerView.bounds;
    self.fadeLayer.frame = self.overlayView.bounds;
    
    self.scrollView.transform = CGAffineTransformIdentity;
    
    CGFloat xSpace = self.frame.size.width - self.cropBoxMinimumEdgeInsets.left - self.cropBoxMinimumEdgeInsets.right;
    CGFloat ySpace = self.frame.size.height - self.cropBoxMinimumEdgeInsets.top - self.cropBoxMinimumEdgeInsets.bottom;
    CGFloat cropBoxScale = MIN(xSpace/self.cropSize.width, ySpace/self.cropSize.height);
    
    self.cropBoxView.frame = CGRectMake((self.containerView.frame.size.width - self.cropSize.width*cropBoxScale
                                          - self.cropBoxMinimumEdgeInsets.left - self.cropBoxMinimumEdgeInsets.right)/2.0
                                          + self.cropBoxMinimumEdgeInsets.left,
                                        (self.containerView.frame.size.height - self.cropSize.height*cropBoxScale
                                          - self.cropBoxMinimumEdgeInsets.top - self.cropBoxMinimumEdgeInsets.bottom)/2.0
                                          + self.cropBoxMinimumEdgeInsets.top,
                                        self.cropSize.width*cropBoxScale,
                                        self.cropSize.height*cropBoxScale);
    
    self.cropBoxBorderLinesLayer.frame = self.cropBoxView.frame;
    
    self.cropBoxHorizontalLinesLayer.frame = CGRectMake(0.0,
                                                        floor(self.cropBoxBorderLinesLayer.frame.size.height/3.0),
                                                        self.cropBoxBorderLinesLayer.frame.size.width,
                                                        ceil(self.cropBoxBorderLinesLayer.frame.size.height/3.0));
    
    self.cropBoxVerticalLinesLayer.frame = CGRectMake(floor(self.cropBoxBorderLinesLayer.frame.size.width/3.0),
                                                      0.0,
                                                      ceil(self.cropBoxBorderLinesLayer.frame.size.width/3.0),
                                                      self.cropBoxBorderLinesLayer.frame.size.height);
    
    CGMutablePathRef maskPath = CGPathCreateMutable();
    CGPathAddRect(maskPath, &CGAffineTransformIdentity, self.overlayView.bounds);
    CGPathAddRect(maskPath, &CGAffineTransformIdentity, self.cropBoxView.frame);
    
    self.maskLayer.path = maskPath;
    
    CGFloat x = fabs(sin(self.currentRotationAngle) * self.cropBoxView.frame.size.height)
                + fabs(cos(self.currentRotationAngle) * self.cropBoxView.frame.size.width);
    CGFloat y = fabs(sin(self.currentRotationAngle) * self.cropBoxView.frame.size.width)
                + fabs(cos(self.currentRotationAngle) * self.cropBoxView.frame.size.height);
    
    self.scrollView.frame = CGRectMake((self.containerView.frame.size.width - x
                                         - self.cropBoxMinimumEdgeInsets.left - self.cropBoxMinimumEdgeInsets.right)/2.0
                                         + self.cropBoxMinimumEdgeInsets.left,
                                       (self.containerView.frame.size.height - y
                                         - self.cropBoxMinimumEdgeInsets.top - self.cropBoxMinimumEdgeInsets.bottom)/2.0
                                         + self.cropBoxMinimumEdgeInsets.top,
                                       x,
                                       y);
    
    self.scrollView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, self.currentRotationAngle);
    
    // we probably need some safety here
    CGFloat horizontalScale = self.image.size.width/x;
    CGFloat verticalScale = self.image.size.height/y;
    
    CGFloat scale = MIN(horizontalScale, verticalScale);
    
    self.scrollView.minimumZoomScale = 1.0/scale;
    
    // might want to eventually make this rotation only
    if (self.scrollView.zoomScale > self.initialZoomScale) {
        self.scrollView.zoomScale = self.initialZoomScale;
    }
    
    if (self.scrollView.minimumZoomScale > self.scrollView.zoomScale) {
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
    }
    
    if (!self.isRotating) {
        [self.scrollView zoomToRect:visibleRect animated:NO];
    }
}

- (void)setImage:(UIImage *)image
{
    self.currentRotationAngle = 0.0;
    self.imageView.image = image;
    
    // this only makes sense for non-zero width and height
    if (self.cropSize.width == 0 || self.cropSize.height == 0) {
        self.imageView.frame = CGRectZero;
        return;
    }
    
    CGFloat horizontalScale = image.size.width/self.cropSize.width;
    CGFloat verticalScale = image.size.height/self.cropSize.height;
    
    CGFloat scale = MIN(horizontalScale, verticalScale);
    
    self.scrollView.minimumZoomScale = 1.0/scale;
    
    self.imageView.frame = CGRectMake(0.0,
                                      0.0,
                                      image.size.width,
                                      image.size.height);
    
    self.scrollView.contentSize = self.imageView.frame.size;
    self.firstLayout = YES;
    [self layoutIfNeeded];
}

- (UIImage *)image
{
    return self.imageView.image;
}

- (void)setCropSize:(CGSize)cropSize
{
    _cropSize = cropSize;
    [self setNeedsLayout];
}

- (void)setCropBoxMinimumEdgeInsets:(UIEdgeInsets)cropBoxMinimumEdgeInsets
{
    _cropBoxMinimumEdgeInsets = cropBoxMinimumEdgeInsets;
    [self setNeedsLayout];
}

- (void)setCurrentRotationAngle:(CGFloat)currentRotationAngle
{
    _currentRotationAngle = currentRotationAngle;
    [self setNeedsLayout];
}

#pragma mark - UIRotationGestureRecognizer

- (void)rotationGestureRecognized:(UIRotationGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.lastCompletedRotationAngle = self.currentRotationAngle;
        self.initialZoomScale = self.scrollView.zoomScale;
        self.rotating = YES;
    } else if (gestureRecognizer.state == UIGestureRecognizerStateCancelled ||
               gestureRecognizer.state == UIGestureRecognizerStateEnded ||
               gestureRecognizer.state == UIGestureRecognizerStateFailed) {
        self.rotating = NO;
    }
    self.currentRotationAngle = self.lastCompletedRotationAngle + gestureRecognizer.rotation;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

#pragma mark -

- (UIImage *)generateImage
{
    CGAffineTransform transform =  CGAffineTransformRotate(CGAffineTransformIdentity, -self.currentRotationAngle);

    CIImage* coreImage = [CIImage imageWithCGImage:self.image.CGImage];
    coreImage = [coreImage imageByApplyingTransform:transform];
    UIImage *rotatedImage = [UIImage imageWithCIImage:coreImage];
    
    UIGraphicsBeginImageContext(self.cropSize);
    
    CGFloat cropBoxScale = self.cropBoxView.frame.size.width/self.cropSize.width;
    
    CGRect targetRect = [self.cropBoxView convertRect:self.imageView.frame fromCoordinateSpace:self.scrollView];
    targetRect = CGRectApplyAffineTransform(targetRect, CGAffineTransformScale(CGAffineTransformIdentity, 1.0/cropBoxScale, 1.0/cropBoxScale));
    [rotatedImage drawInRect:targetRect];
    
    UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

@end
