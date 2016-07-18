//
//  MainViewController.m
//  BarCodeDemo
//
//  Created by Zilu.Ma on 16/7/18.
//  Copyright © 2016年 Zilu.Ma. All rights reserved.
//

#import "MainViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

@interface MainViewController ()<AVCaptureMetadataOutputObjectsDelegate>

{
    BOOL _isReading;
    AVCaptureSession *_captureSession;
    AVCaptureVideoPreviewLayer *_videoPreviewLayer;
    
    NSTimer *_timer;
    CALayer *_centerLayer;///扫描区域
    CAGradientLayer *_newShadow;//扫描区域循环移动的横线
    NSString *_result;//扫描结果
}

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self startReading];
    
    //    [self setInterface:self.view.layer];
}

- (void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    
    if (_captureSession != nil) {
        [self stopReading];
    }
}

- (void)startReading {
    _isReading = YES;
    NSError *error;
    //获取摄像设备
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    //输出流
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    
    //设置扫描区域:rect的四个值的范围都是(0~1),按比例计算
    //和平常的rect不太一样
    //x,y调换,width和height调换
    output.rectOfInterest = CGRectMake(0.33, 0.2, 0.33, 0.6);//0.6, 0.33
    
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        return ;
    }
    
    //初始化链接对象
    _captureSession = [[AVCaptureSession alloc] init];
    
    [_captureSession addInput:input];
    [_captureSession addOutput:output];
    //高质量采集率
    [_captureSession setSessionPreset:AVCaptureSessionPresetHigh];
    
    
    // Create a new serial dispatch queue.
    
    dispatch_queue_t dispatchQueue;
    //    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    dispatchQueue = dispatch_get_main_queue();
    //设置代理,在主线程中刷新
    [output setMetadataObjectsDelegate:self queue:dispatchQueue];
    
    //设置扫描支持的编码格式
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeCode128Code];
    
    //        [output setMetadataObjectTypes:[NSArray arrayWithObjects:AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeQRCode, nil]];
    
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:self.view.layer.bounds];
    [self setInterface:_videoPreviewLayer];
    [self.view.layer addSublayer:_videoPreviewLayer];
    
    [_captureSession startRunning];
}

-(void)stopReading{
    [_captureSession stopRunning];
    _captureSession = nil;
    [_videoPreviewLayer removeFromSuperlayer];
    
    [_timer invalidate];
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects
      fromConnection:(AVCaptureConnection *)connection
{
    if (!_isReading) return;
    
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        
        _result = metadataObj.stringValue;
        _VC.messge = _result;
        NSLog(@"%@",metadataObj.stringValue);
        //        NSLog(@"%@",metadataObjects);
        
        [self stopReading];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

//设置界面显示的图层
- (void)setInterface:(CALayer *)layer{
    
    CGFloat width = layer.bounds.size.width/5;
    CGFloat height = layer.bounds.size.height/3;
    UIColor *color = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    
    CALayer *topLayer = [CALayer layer];
    topLayer.position = CGPointMake(layer.bounds.size.width/2, height/2);
    topLayer.bounds = CGRectMake(0, 0, layer.bounds.size.width, height);
    topLayer.backgroundColor = color.CGColor;
    [layer addSublayer:topLayer];
    
    CALayer *leftLayer = [CALayer layer];
    leftLayer.position = CGPointMake(width/2, height + height/2);
    leftLayer.bounds = CGRectMake(0, 0, width, height);
    leftLayer.backgroundColor = color.CGColor;
    [layer addSublayer:leftLayer];
    
    CALayer *bottomLayer = [CALayer layer];
    bottomLayer.position = CGPointMake(layer.bounds.size.width/2, 2*height + height/2);
    bottomLayer.bounds = CGRectMake(0, 0, layer.bounds.size.width, height);
    bottomLayer.backgroundColor = color.CGColor;
    [layer addSublayer:bottomLayer];
    
    CALayer *rightLayer = [CALayer layer];
    rightLayer.position = CGPointMake(width*4 + width/2, height + height/2);
    rightLayer.bounds = CGRectMake(0, 0, width, height);
    rightLayer.backgroundColor = color.CGColor;
    [layer addSublayer:rightLayer];
    
    _centerLayer = [CALayer layer];
    _centerLayer.position = CGPointMake(layer.bounds.size.width/2, layer.bounds.size.height/2);
    _centerLayer.bounds = CGRectMake(0, 0, width*3, height);
    for (int i = 0; i < 4; i ++) {
        [self drawRightAngle:_centerLayer tag:i];
    }
    [layer addSublayer:_centerLayer];
    
    [self drawLine:_centerLayer];
}

//扫描框的小直角
- (void)drawRightAngle:(CALayer *)layer tag:(int)tag{
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(20, 0)];
    [path addLineToPoint:CGPointMake(20, 5)];
    [path addLineToPoint:CGPointMake(5, 5)];
    [path addLineToPoint:CGPointMake(5, 20)];
    [path addLineToPoint:CGPointMake(0, 20)];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.fillColor = [UIColor colorWithRed:141/255.0 green:196/255.0 blue:31/255.0 alpha:1].CGColor;
    shapeLayer.path = path.CGPath;
    [layer addSublayer:shapeLayer];
    
    switch (tag) {
        case 0:
            break;
        case 1:
        {
            CGAffineTransform transform = CGAffineTransformMakeTranslation(layer.bounds.size.width, 0);
            shapeLayer.affineTransform = CGAffineTransformRotate(transform, M_PI/2);
        }
            break;
        case 2:
        {
            CGAffineTransform transform = CGAffineTransformMakeTranslation(layer.bounds.size.width, layer.bounds.size.height);
            shapeLayer.affineTransform = CGAffineTransformRotate(transform, M_PI);
        }
            break;
        case 3:
        {
            CGAffineTransform transform = CGAffineTransformMakeTranslation(0, layer.bounds.size.height);
            shapeLayer.affineTransform = CGAffineTransformRotate(transform, M_PI/2*3);
        }
            break;
            
        default:
            break;
    }
}

- (void)drawLine:(CALayer *)layer{
    
    _newShadow = [[CAGradientLayer alloc] init];
    _newShadow.position = CGPointMake(layer.bounds.size.width/2, 5);
    _newShadow.bounds = CGRectMake(0, 0, layer.bounds.size.width-20, 5);
    //添加渐变的颜色组合（颜色透明度的改变）
    UIColor *topColor = [UIColor colorWithRed:141/255.0 green:196/255.0 blue:31/255.0 alpha:0.5];
    UIColor *centerColor = [UIColor colorWithRed:141/255.0 green:196/255.0 blue:31/255.0 alpha:1.0];
    UIColor *bottomColor = [UIColor colorWithRed:141/255.0 green:196/255.0 blue:31/255.0 alpha:0.5];
    _newShadow.colors = [NSArray arrayWithObjects:
                         (id)[topColor CGColor] ,(id)[centerColor CGColor] ,
                         (id)[bottomColor CGColor],
                         nil];
    
    //startPoint:开始变化的位置(按比例计算)
    //endPoint:结束变化的位置(按比例计算)
    _newShadow.startPoint = CGPointMake(0, 0.5);
    _newShadow.endPoint = CGPointMake(1, 0.5);
    
    [layer addSublayer:_newShadow];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [_timer fire];
}

- (void)onTimer:(NSTimer *)timer{
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    CGPoint position = _newShadow.position;
    animation.fromValue = [NSValue valueWithCGPoint:position];
    position.y = position.y + _centerLayer.bounds.size.height - 10;
    animation.toValue = [NSValue valueWithCGPoint:position];
    animation.duration = 2.9;
    [_newShadow addAnimation:animation forKey:@"position"];
}

/*
 IOS--CALayer实现，界限、透明度、位置、旋转、缩放组合动画（转）
 
 
 首先引入框架：QuartzCore.framework
 在头文件声明：CALayer *logoLayer
 {
 //界限
 
 CABasicAnimation *boundsAnimation = [CABasicAnimationanimationWithKeyPath:@"bounds"];
 boundsAnimation.fromValue = [NSValue valueWithCGRect: logoLayer.bounds];
 boundsAnimation.toValue = [NSValue valueWithCGRect:CGRectZero];
 
 
 //透明度变化
 CABasicAnimation *opacityAnimation = [CABasicAnimationanimationWithKeyPath:@"opacity"];
 opacityAnimation.fromValue = [NSNumber numberWithFloat:1.0];
 opacityAnimation.toValue = [NSNumber numberWithFloat:0.5];
 //位置移动
 
 CABasicAnimation *animation  = [CABasicAnimation animationWithKeyPath:@"position"];
 animation.fromValue =  [NSValue valueWithCGPoint: logoLayer.position];
 CGPoint toPoint = logoLayer.position;
 toPoint.x += 180;
 animation.toValue = [NSValue valueWithCGPoint:toPoint];
 //旋转动画
 CABasicAnimation* rotationAnimation =
 [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];//"z"还可以是“x”“y”，表示沿z轴旋转
 rotationAnimation.toValue = [NSNumber numberWithFloat:(2 * M_PI) * 3];
 // 3 is the number of 360 degree rotations
 // Make the rotation animation duration slightly less than the other animations to give it the feel
 // that it pauses at its largest scale value
 rotationAnimation.duration = 2.0f;
 rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]; //缓入缓出
 
 
 //缩放动画
 
 CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
 scaleAnimation.fromValue = [NSNumber numberWithFloat:0.0];
 scaleAnimation.toValue = [NSNumber numberWithFloat:1.0];
 scaleAnimation.duration = 2.0f;
 scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
 
 CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
 animationGroup.duration = 2.0f;
 animationGroup.autoreverses = YES;   //是否重播，原动画的倒播
 animationGroup.repeatCount = NSNotFound;//HUGE_VALF;     //HUGE_VALF,源自math.h
 [animationGroup setAnimations:[NSArray arrayWithObjects:rotationAnimation, scaleAnimation, nil]];
 
 
 //将上述两个动画编组
 [logoLayer addAnimation:animationGroup forKey:@"animationGroup"];
 }
 //去掉所有动画
 [logoLayer removeAllAnimations];
 //去掉key动画
 
 [logoLayer removeAnimationForKey:@"animationGroup"];
 
 */


/*
 几种系统的Layer类
 
 前边说过，和UIView相似，CALayer也很据功能衍生出许多子类，系统系统给我们可以使用的有如下几种：
 
 1.CAEmitterLayer
 
 CoreAnimation框架中的CAEmitterLayer是一个粒子发射器系统，负责粒子的创建和发射源属性。通过它，我们可以轻松创建出炫酷的粒子效果。
 
 2.CAGradientLayer
 
 CAGradientLayer可以创建出色彩渐变的图层效果，如下：
 
 
 
 3.CAEAGLLayer
 
 CAEAGLLayer可以通过OpenGL ES来进行界面的绘制。
 
 4.CAReplicatorLayer
 
 CAReplicatorLayer是一个layer容器，会对其中的subLayer进行复制和属性偏移，通过它，可以创建出类似倒影的效果，也可以进行变换复制，如下：
 
 
 
 5.CAScrollLayer
 
 CAScrollLayer可以支持其上管理的多个子层进行滑动，但是只能通过代码进行管理，不能进行用户点按触发。
 
 6.CAShapeLayer
 
 CAShapeLayer可以让我们在layer层是直接绘制出自定义的形状。
 
 7.CATextLayer
 
 CATextLayer可以通过字符串进行文字的绘制。
 
 8.CATiledLayer
 
 CATiledLayer类似瓦片视图，可以将绘制分区域进行，常用于一张大的图片的分不分绘制。
 
 9.CATransformLayer
 
 CATransformLayer用于构建一些3D效果的图层。
 
 
 
 
 1、创建与初始化layer相关
 
 //通过类方法创建并初始化一个layer
 + (instancetype)layer;
 //初始化方法
 - (instancetype)init;
 //通过一个layer创建一个副本
 - (instancetype)initWithLayer:(id)layer;
 2、渲染层layer与模型层layer
 
 在CALayer中，有如下两个属性，他们都返回一个CALayer的对象：
 
 //渲染层layer
 - (nullable id)presentationLayer;
 //模型层layer
 - (id)modelLayer;
 对于presentationLayer，这个属性不一定总会返回一个实体对象，只有当进行动画或者其他渲染的操作时，这个属性会返回一个在当前屏幕上的layer，不且每一次执行，这个对象都会不同，它是原layer的一个副本presentationLayer的modelLayer就是其实体layer层。
 
 对于modelLayer，它会返回当前的存储信息的Layer，也是当前的layer对象，始终唯一。
 
 3.一些属性与方法
 
 + (nullable id)defaultValueForKey:(NSString *)key;
 
 上面这个属性用于设置layer中默认属性的值，我们可以在子类中重写这个方法来改变默认创建的layer的一些属性，例如如下代码，我们创建出来的layer就默认有红色的背景颜色：
 
 +(id)defaultValueForKey:(NSString *)key{
 if ([key isEqualToString:@"backgroundColor"]) {
 return (id)[UIColor redColor].CGColor;
 }
 return [super defaultValueForKey:key];
 }
 //这个方法也只使用在子类中重写，用于设置在某些属性改变时是否进行layer重绘
 + (BOOL)needsDisplayForKey:(NSString *)key;
 //子类重写这个方法设置属性是否可以被归档
 - (BOOL)shouldArchiveValueForKey:(NSString *)key;
 //设置layer尺寸
 @property CGRect bounds;
 //设置layer位置
 @property CGPoint position;
 //设置其在父layer中的层次，默认为0，这个值越大，层次越靠上
 @property CGFloat zPosition;
 //锚点
 @property CGPoint anchorPoint;
 //在Z轴上的锚点位置 3D变换时会有很大影响
 @property CGFloat anchorPointZ;
 //进行3D变换
 @property CATransform3D transform;
 //获取和设置CGAffineTransform变换
 - (CGAffineTransform)affineTransform;
 - (void)setAffineTransform:(CGAffineTransform)m;
 //设置layer的frame
 @property CGRect frame;
 //设置是否隐藏
 @property(getter=isHidden) BOOL hidden;
 //每个layer层有两面，这个属性确定是否两面都显示
 @property(getter=isDoubleSided) BOOL doubleSided;
 //是否进行y轴的方向翻转
 @property(getter=isGeometryFlipped) BOOL geometryFlipped;
 //获取当前layer内容y轴方向是否被翻转了
 - (BOOL)contentsAreFlipped;
 //父layer视图
 @property(nullable, readonly) CALayer *superlayer;
 //从其父layer层上移除
 - (void)removeFromSuperlayer;
 //所有子layer数组
 @property(nullable, copy) NSArray<CALayer *> *sublayers;
 //添加一个字layer
 - (void)addSublayer:(CALayer *)layer;
 //插入一个子layer
 - (void)insertSublayer:(CALayer *)layer atIndex:(unsigned)idx;
 //将一个子layer插入到最下面
 - (void)insertSublayer:(CALayer *)layer below:(nullable CALayer *)sibling;
 //将一个子layer插入到最上面
 - (void)insertSublayer:(CALayer *)layer above:(nullable CALayer *)sibling;
 //替换一个子layer
 - (void)replaceSublayer:(CALayer *)layer with:(CALayer *)layer2;
 //对其子layer进行3D变换
 @property CATransform3D sublayerTransform;
 //遮罩层layer
 @property(nullable, strong) CALayer *mask;
 //舍否进行bounds的切割，在设置圆角属性时会设置为YES
 @property BOOL masksToBounds;
 //下面这些方法用于坐标转换
 - (CGPoint)convertPoint:(CGPoint)p fromLayer:(nullable CALayer *)l;
 - (CGPoint)convertPoint:(CGPoint)p toLayer:(nullable CALayer *)l;
 - (CGRect)convertRect:(CGRect)r fromLayer:(nullable CALayer *)l;
 - (CGRect)convertRect:(CGRect)r toLayer:(nullable CALayer *)l;
 //返回包含某一点的最上层的子layer
 - (nullable CALayer *)hitTest:(CGPoint)p;
 //返回layer的bounds内是否包含某一点
 - (BOOL)containsPoint:(CGPoint)p;
 //设置layer的内容，一般会设置为CGImage的对象
 @property(nullable, strong) id contents;
 //获取内容的rect尺寸
 @property CGRect contentsRect;
 //设置内容的填充和对其方式，具体上面有说
 @property(copy) NSString *contentsGravity;
 //设置内容的缩放
 @property CGFloat contentsScale;
 下面这个属性和内容拉伸相关：
 
 @property CGRect contentsCenter;
 这个属性确定一个矩形区域，当内容进行拉伸或者缩放的时候，这一部分的区域是会被形变的，例如默认设置为(0,0,1,1)，则整个内容区域都会参与形变。如果我们设置为(0.25,0.25,0.5,0.5),那么只有中间0.5*0.5比例宽高的区域会被拉伸，四周都不会。
 
 下面这两个属性用来设置缩放或拉伸的模式：
 
 //设置缩小的模式
 @property(copy) NSString *minificationFilter;
 //设置放大的模式
 @property(copy) NSString *magnificationFilter;
 //缩放因子
 @property float minificationFilterBias;
 //模式参数如下
 //临近插值
 NSString * const kCAFilterNearest;
 //线性拉伸
 NSString * const kCAFilterLinear;
 //瓦片复制拉伸
 NSString * const kCAFilterTrilinear;
 //设置内容是否完全不透明
 @property(getter=isOpaque) BOOL opaque;
 //重新加载绘制内容
 - (void)display;
 //设置内容为需要重新绘制
 - (void)setNeedsDisplay;
 //设置某一区域内容需要重新绘制
 - (void)setNeedsDisplayInRect:(CGRect)r;
 //获取是否需要重新绘制
 - (BOOL)needsDisplay;
 //如果需要，进行内容重绘
 - (void)displayIfNeeded;
 //这个属性设置为YES，当内容改变时会自动调用- (void)setNeedsDisplay函数
 @property BOOL needsDisplayOnBoundsChange;
 //绘制与读取内容
 - (void)drawInContext:(CGContextRef)ctx;
 - (void)renderInContext:(CGContextRef)ctx;
 //设置背景颜色
 @property(nullable) CGColorRef backgroundColor;
 //设置圆角半径
 @property CGFloat cornerRadius;
 //设置边框宽度
 @property CGFloat borderWidth;
 //设置边框颜色
 @property(nullable) CGColorRef borderColor;
 //设置透明度
 @property float opacity;
 //设置阴影颜色
 @property(nullable) CGColorRef shadowColor;
 //设置阴影透明度
 @property float shadowOpacity;
 //设置阴影偏移量
 @property CGSize shadowOffset;
 //设置阴影圆角半径
 @property CGFloat shadowRadius;
 //设置阴影路径
 @property(nullable) CGPathRef shadowPath;
 //添加一个动画对象 key值起到id的作用，通过key值，可以取到这个动画对象
 - (void)addAnimation:(CAAnimation *)anim forKey:(nullable NSString *)key;
 //移除所有动画对象
 - (void)removeAllAnimations;
 //移除某个动画对象
 - (void)removeAnimationForKey:(NSString *)key;
 //获取所有动画对象的key值
 - (nullable NSArray<NSString *> *)animationKeys;
 //通过key值获取动画对象
 - (nullable CAAnimation *)animationForKey:(NSString *)key;
 
 */

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
