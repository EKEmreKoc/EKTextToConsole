//
//  ViewController.m
//  EKTextToConsole
//
//  Created by Emre on 12/12/14.
//  Copyright (c) 2014 Emre Koc. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *myImageView;
@property (nonatomic, weak) IBOutlet UILabel *myLabel;
@property (nonatomic, weak) IBOutlet UITextField *myTextField;


@property (nonatomic, strong) UIImage *myImage;
@property (nonatomic, strong) NSMutableArray *col;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)renderAction:(id)sender
{
    if (self.myTextField.text.length < 1) return;
    
    self.myLabel.adjustsFontSizeToFitWidth = YES;
    self.myLabel.text = self.myTextField.text;
    
    self.myImage = [self captureView:self.myLabel];
    
    self.myImageView.image = self.myImage;
    self.myImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [self imageToConsole:self.myImage];
    
}

- (void)imageToConsole:(UIImage *)image {
    
    if (self.col) {
        [self.col removeAllObjects];
        self.col = nil;
    }
    
    self.col = [[NSMutableArray alloc]init];
    for (int i = 0; i < image.size.height; i++) {
        NSMutableArray *row = [[NSMutableArray alloc]init];
        for (int j = 0; j < image.size.width; j++) {
            CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
            UIColor *pixelColor = [self getColorInPixelWithLocation:CGPointMake(j, i) image:image];
            const CGFloat *componentss = CGColorGetComponents(pixelColor.CGColor);
            red = componentss[0];
            green = componentss[1];
            blue = componentss[2];
            alpha = componentss[3];
            
            if (red > 0.5 && green > 0.5 && blue > 0.5) {
                [row addObject:@"1"];
                //printf("1");
            }
            else {
                [row addObject:@"0"];
                //printf("0");
            }
        }
        if ([row containsObject:@"0"])
            [self.col addObject:row];
        
        //printf("\n");
    }
    
    [self writeToConsoleWithStep:@0];
}

- (void)writeToConsoleWithStep:(NSNumber *)step
{
    
    for (NSArray *row in self.col) {
        for (NSString *val in row) {
            if ([val isEqualToString:@"1"])
                printf(" ");
            else
                printf("0");
        }
        printf("\n");
    }
    printf("\n\n\n");
    
    //marquee
    
//    if ([step integerValue] > 0) {
//        [self.col enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//            NSMutableArray *row = (NSMutableArray *)obj;
//            [row insertObject:@"1" atIndex:0];
//            [self.col replaceObjectAtIndex:idx withObject:row];
//        }];
//    }
//    [self performSelector:@selector(writeToLogWithStep:) withObject:@1 afterDelay:1.0f];
    
}

- (UIImage *)captureView:(UIView *)view{
    CGRect rect = [view bounds];
    UIGraphicsBeginImageContextWithOptions(rect.size,YES,1.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [view.layer renderInContext:context];
    UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return capturedImage;
}

- (CGContextRef)createARGBBitmapContextFromImage:(CGImageRef)inImage {
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    void*           bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    
    // Get image width, height. We'll use the entire image.
    size_t pixelsWide = CGImageGetWidth(inImage);
    size_t pixelsHigh = CGImageGetHeight(inImage);
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow   = (pixelsWide * 4);
    bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
    
    // Use the generic RGB color space.
    colorSpace = CGColorSpaceCreateDeviceRGB();//CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    if (colorSpace == NULL)
    {
        fprintf(stderr, "Error allocating color space\n");
        return NULL;
    }
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL)
    {
        fprintf (stderr, "Memory not allocated!");
        CGColorSpaceRelease( colorSpace );
        return NULL;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    context = CGBitmapContextCreate (bitmapData,
                                     pixelsWide,
                                     pixelsHigh,
                                     8,      // bits per component
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);
    if (context == NULL)
    {
        free (bitmapData);
        fprintf (stderr, "Context not created!");
    }
    
    // Make sure and release colorspace before returning
    //CGColorSpaceRelease( colorSpace );
    
    return context;
}

- (UIColor *)getColorInPixelWithLocation:(CGPoint)point image:(UIImage *)image {
    UIColor* color = nil;
    
    CGImageRef inImage;
    
    inImage = image.CGImage;
    
    
    // Create off screen bitmap context to draw the image into. Format ARGB is 4 bytes for each pixel: Alpa, Red, Green, Blue
    CGContextRef cgctx = [self createARGBBitmapContextFromImage:inImage];
    if (cgctx == NULL) { return nil; /* error */ }
    
    size_t w = CGImageGetWidth(inImage);
    size_t h = CGImageGetHeight(inImage);
    CGRect rect = {{0,0},{w,h}};
    
    
    // Draw the image to the bitmap context. Once we draw, the memory
    // allocated for the context for rendering will then contain the
    // raw image data in the specified color space.
    CGContextDrawImage(cgctx, rect, inImage);
    
    // Now we can get a pointer to the image data associated with the bitmap
    // context.
    unsigned char* data = CGBitmapContextGetData (cgctx);
    if (data != NULL) {
        //offset locates the pixel in the data from x,y.
        //4 for 4 bytes of data per pixel, w is width of one row of data.
        int offset = 4*((w*round(point.y))+round(point.x));
        int alpha =  data[offset];
        int red = data[offset+1];
        int green = data[offset+2];
        int blue = data[offset+3];
        color = [UIColor colorWithRed:(red/255.0f) green:(green/255.0f) blue:(blue/255.0f) alpha:(alpha/255.0f)];
    }
    
    // When finished, release the context
    //CGContextRelease(cgctx);
    // Free image data memory for the context
    if (data) { free(data); }
    
    return color;
}

@end
