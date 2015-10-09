//
//  This is free and unencumbered software released into the public domain.
//
//  Anyone is free to copy, modify, publish, use, compile, sell, or
//  distribute this software, either in source code form or as a compiled
//  binary, for any purpose, commercial or non-commercial, and by any
//  means.
//
//  In jurisdictions that recognize copyright laws, the author or authors
//  of this software dedicate any and all copyright interest in the
//  software to the public domain. We make this dedication for the benefit
//  of the public at large and to the detriment of our heirs and
//  successors. We intend this dedication to be an overt act of
//  relinquishment in perpetuity of all present and future rights to this
//  software under copyright law.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
//  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
//  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//
//  For more information, please refer to <http://unlicense.org/>
//

#import <UIKit/UIKit.h>

@interface RAPDFImageOptions : NSObject

@property (nonatomic, assign) CGFloat scale;				 //	screen scale, defaults to 0, the current screen scale
@property (nonatomic, copy) UIColor *tintColor;				 //	solid color of the image, defaults to nil, original color
@property (nonatomic, assign) CGSize size;					 //	size of the image
@property (nonatomic, assign) UIViewContentMode contentMode; //	defaults to UIViewContentModeScaleToFill

//	Convience method for simply spitting out a sized version
+ (instancetype)optionsWithSize:(CGSize)size;

- (CGRect)contentBoundsForContentSize:(CGSize)contentSize;

//	Proportionally scaled up or down by a whole number to fit the contentSize in the self.size
- (CGSize)wholeProportionalFitForContentSize:(CGSize)contentSize;

@end