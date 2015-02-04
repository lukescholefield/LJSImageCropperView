//
//  LJSImageResultViewController.m
//  LJSImageCropperDemo
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

#import "LJSImageResultViewController.h"

@interface LJSImageResultViewController ()

@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIImageView *imageView;

@end

@implementation LJSImageResultViewController

- (instancetype)initWithImage:(UIImage *)image
{
    self = [self init];
    if (self) {
        self.image = image;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.image = self.image;
    [self.view addSubview:self.imageView];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    self.imageView.frame = CGRectMake(20.0,
                                      [self topLayoutGuide].length + 20.0,
                                      self.view.frame.size.width - 20.0 * 2,
                                      self.view.frame.size.height - [self topLayoutGuide].length - 20.0 * 2);
}


@end
