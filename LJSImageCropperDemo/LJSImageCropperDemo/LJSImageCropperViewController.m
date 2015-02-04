//
//  LJSImageCropperViewController.m
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

#import "LJSImageCropperViewController.h"
#import "LJSImageCropperView.h"
#import "LJSImageResultViewController.h"

@interface LJSImageCropperViewController ()

@property (strong, nonatomic) LJSImageCropperView *imageCropperView;

@end

@implementation LJSImageCropperViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO; // this matters a lot
    self.imageCropperView = [[LJSImageCropperView alloc]  initWithFrame:self.view.bounds];
    self.imageCropperView.cropSize = CGSizeMake(300.0, 200.0);
    self.imageCropperView.cropBoxMinimumEdgeInsets = UIEdgeInsetsMake(84.0, 20.0, 20.0, 20.0);
    self.imageCropperView.image = [UIImage imageNamed:@"image"];
    [self.view addSubview:self.imageCropperView];
    
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped:)];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    self.imageCropperView.frame = self.view.bounds;
}


- (void)doneButtonTapped:(id)sender
{
    LJSImageResultViewController *finalImageViewController = [[LJSImageResultViewController alloc] initWithImage:[self.imageCropperView generateImage]];
    [self.navigationController pushViewController:finalImageViewController animated:YES];
}

@end
