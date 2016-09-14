//
//  LSYReadPageViewController.m
//  LSYReader
//
//  Created by Labanotation on 16/5/30.
//  Copyright © 2016年 okwei. All rights reserved.
//

#import "LSYReadPageViewController.h"
#import "LSYReadViewController.h"
#import "LSYChapterModel.h"
#import "LSYMenuView.h"
#import "LSYCatalogViewController.h"
#import "UIImage+ImageEffects.h"
#import "LSYNoteModel.h"
#import "LSYMarkModel.h"
#import "GDataXMLNode.h"
#define AnimationDelay 0.3

@interface LSYReadPageViewController ()<UIPageViewControllerDelegate,UIPageViewControllerDataSource,LSYMenuViewDelegate,UIGestureRecognizerDelegate,NSXMLParserDelegate,LSYCatalogViewControllerDelegate,LSYReadViewControllerDelegate>
{
    NSUInteger _chapter;    //当前显示的章节
    NSUInteger _page;       //当前显示的页数
    NSUInteger _chapterChange;  //将要变化的章节
    NSUInteger _pageChange;     //将要变化的页数
    NSInteger  _count;
    BOOL _isTransition;     //是否开始翻页
}
@property (nonatomic,strong) UIPageViewController * pageViewController;
@property (nonatomic,getter = isShowBar) BOOL showBar; //是否显示状态栏
@property (nonatomic,strong) LSYMenuView *menuView; //菜单栏
@property (nonatomic,strong) LSYCatalogViewController *catalogVC;   //侧边栏
@property (nonatomic,strong) UIView * catalogView;  //侧边栏背景
@property (nonatomic,strong) LSYReadViewController *readView;   //当前阅读视图
@property (nonatomic,copy) NSString * eleString;
@property (nonatomic, strong) NSMutableArray * Arr;
@property (nonatomic, copy) NSString *string;
@property (nonatomic,copy) NSString * zmStr;
@property (nonatomic,retain) NSMutableArray *epubArray;

@end

@implementation LSYReadPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addChildViewController:self.pageViewController];
    [_pageViewController setViewControllers:@[[self readViewWithChapter:_model.record.chapter page:_model.record.page]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    
    _chapter = _model.record.chapter;
    _page = _model.record.page;
    [self.view addGestureRecognizer:({
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showToolMenu)];
        tap.delegate = self;
        tap;
    })];
    [self.view addSubview:self.menuView];
    
    [self addChildViewController:self.catalogVC];
    [self.view addSubview:self.catalogView];
    [self.catalogView addSubview:self.catalogVC.view];
    //添加笔记
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addNotes:) name:LSYNoteNotification object:nil];

}

-(void)addNotes:(NSNotification *)no
{
    LSYNoteModel *model = no.object;
    model.recordModel = [_model.record copy];
    [[_model mutableArrayValueForKey:@"notes"] addObject:model];    //这样写才能KVO数组变化
    [LSYReadUtilites showAlertTitle:nil content:@"保存笔记成功"];
}

-(BOOL)prefersStatusBarHidden
{
    return !_showBar;
}
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}
-(void)showToolMenu
{
    [_readView.readView cancelSelected];
    [self.menuView showAnimation:YES];
    
}

#pragma mark - init
-(LSYMenuView *)menuView
{
    if (!_menuView) {
        _menuView = [[LSYMenuView alloc] init];
        _menuView.hidden = YES;
        _menuView.delegate = self;
        _menuView.recordModel = _model.record;
    }
    return _menuView;
}
-(UIPageViewController *)pageViewController
{
    if (!_pageViewController) {
        _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
        _pageViewController.delegate = self;
        _pageViewController.dataSource = self;
        [self.view addSubview:_pageViewController.view];
    }
    return _pageViewController;
}
-(LSYCatalogViewController *)catalogVC
{
    if (!_catalogVC) {
        _catalogVC = [[LSYCatalogViewController alloc] init];
        _catalogVC.readModel = _model;
        _catalogVC.catalogDelegate = self;
    }
    return _catalogVC;
}
-(UIView *)catalogView
{
    if (!_catalogView) {
        _catalogView = [[UIView alloc] init];
        _catalogView.backgroundColor = [UIColor clearColor];
        _catalogView.hidden = YES;
        [_catalogView addGestureRecognizer:({
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hiddenCatalog)];
            tap.delegate = self;
            tap;
        })];
    }
    return _catalogView;
}
#pragma mark - CatalogViewController Delegate
-(void)catalog:(LSYCatalogViewController *)catalog didSelectChapter:(NSUInteger)chapter page:(NSUInteger)page
{
     [_pageViewController setViewControllers:@[[self readViewWithChapter:chapter page:page]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    [self updateReadModelWithChapter:chapter page:page];
    [self hiddenCatalog];
    
}
#pragma mark -  UIGestureRecognizer Delegate
//解决TabView与Tap手势冲突
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]) {
        return NO;
    }
    return  YES;
}
#pragma mark - Privite Method
-(void)catalogShowState:(BOOL)show
{
    show?({
        _catalogView.hidden = !show;
        [UIView animateWithDuration:AnimationDelay animations:^{
            _catalogView.frame = CGRectMake(0, 0,2*ViewSize(self.view).width, ViewSize(self.view).height);
            
        } completion:^(BOOL finished) {
            [_catalogView insertSubview:[[UIImageView alloc] initWithImage:[self blurredSnapshot]] atIndex:0];
        }];
    }):({
        if ([_catalogView.subviews.firstObject isKindOfClass:[UIImageView class]]) {
            [_catalogView.subviews.firstObject removeFromSuperview];
        }
        [UIView animateWithDuration:AnimationDelay animations:^{
             _catalogView.frame = CGRectMake(-ViewSize(self.view).width, 0, 2*ViewSize(self.view).width, ViewSize(self.view).height);
        } completion:^(BOOL finished) {
            _catalogView.hidden = !show;
            
        }];
    });
}
-(void)hiddenCatalog
{
    [self catalogShowState:NO];
}
- (UIImage *)blurredSnapshot {
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)), NO, 1.0f);
    [self.view drawViewHierarchyInRect:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)) afterScreenUpdates:NO];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage = [snapshotImage applyLightEffect];
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}
#pragma mark - Menu View Delegate
-(void)menuViewDidHidden:(LSYMenuView *)menu
{
     _showBar = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}
-(void)menuViewDidAppear:(LSYMenuView *)menu
{
    _showBar = YES;
    [self setNeedsStatusBarAppearanceUpdate];
    
}
-(void)menuViewInvokeCatalog:(LSYBottomMenuView *)bottomMenu
{
    [_menuView hiddenAnimation:NO];
    [self catalogShowState:YES];
    
}

-(void)menuViewJumpChapter:(NSUInteger)chapter page:(NSUInteger)page
{
    [_pageViewController setViewControllers:@[[self readViewWithChapter:chapter page:page]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [self updateReadModelWithChapter:chapter page:page];
}
-(void)menuViewFontSize:(LSYBottomMenuView *)bottomMenu
{

    [_model.record.chapterModel updateFont];
    //分页
    [_pageViewController setViewControllers:@[[self readViewWithChapter:_model.record.chapter page:(_model.record.page>_model.record.chapterModel.pageCount-1)?_model.record.chapterModel.pageCount-1:_model.record.page]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [self updateReadModelWithChapter:_model.record.chapter page:(_model.record.page>_model.record.chapterModel.pageCount-1)?_model.record.chapterModel.pageCount-1:_model.record.page];
}
-(void)menuViewMark:(LSYTopMenuView *)topMenu
{

    LSYMarkModel *model = [[LSYMarkModel alloc] init];
    model.date = [NSDate date];
    model.recordModel = [_model.record copy];
    [[_model mutableArrayValueForKey:@"marks"] addObject:model];

}
#pragma mark - Create Read View Controller

-(LSYReadViewController *)readViewWithChapter:(NSUInteger)chapter page:(NSUInteger)page{

    
    if (_model.record.chapter != chapter) {
        [_model.record.chapterModel updateFont];
    }
    _readView = [[LSYReadViewController alloc] init];
    _readView.recordModel = _model.record;
    //提取文本
    NSString * content = [_model.chapters[chapter] stringOfPage:page];
    NSArray * contArray = [content componentsSeparatedByString:@" "];
    NSMutableArray * nsarr = [[NSMutableArray alloc]initWithArray:contArray];
    for (int i = 0; i < nsarr.count; i++)
    {
        if ([nsarr[i] isEqualToString:@"\n"]||[nsarr[i] isEqualToString:@"\n\n"]||[nsarr[i] isEqualToString:@""]) {
            [nsarr removeObject:nsarr[i]];
        }
    }
    NSString * contStr = [nsarr componentsJoinedByString:@""];
    
    NSLog(@"contStr----'%@",contStr);
    NSLog(@"contArray - -- - - -%@",contArray
          );
    //_readView.content = [_model.chapters[chapter] stringOfPage:page];
    NSLog(@"page------%ld",page);
       _Arr = [[NSMutableArray alloc]init];
    NSURL * url = [NSURL fileURLWithPath:[_model.chapters objectAtIndex:chapter].spinePath];
    
    
    NSData * data = [NSData dataWithContentsOfURL:url options:NSUTF8StringEncoding error:nil];
    NSXMLParser *parser = [[NSXMLParser alloc]initWithData:data];
   // NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    
    //设置代理
    parser.delegate = self;
    //开始解析
    [parser parse];
    NSLog(@"content---%@",content);
    //NSLog(@"------解析xhtml数组---%@",_Arr);
    NSInteger count = nsarr.count;
    NSMutableArray * tt = [[NSMutableArray alloc]init];
    for (int i = _count; i< _Arr.count; i ++)
    {
        if (i<count)
        {
            
            [tt addObject:_Arr[i]];
        }
      
    }
   
    _count = count;
    NSString * str = [_Arr componentsJoinedByString:@""];
    
    _readView.content = str;
   // NSString *string = [_model.chapters[chapter] spinePath];
    NSLog(@"章节数组%@",url);
    NSLog(@"是否显示全部本章内容----%@",str);
    
   // NSString* html = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path]] encoding:NSUTF8StringEncoding];
   // NSLog(@"html-----%@",html);
  //  NSLog(@"章节%@",_model.chapters[chapter]);
    _readView.delegate = self;
  //  NSLog(@"_readGreate");
    
    return _readView;
}
-(void)updateReadModelWithChapter:(NSUInteger)chapter page:(NSUInteger)page
{
    _chapter = chapter;
    _page = page;
    _model.record.chapterModel = _model.chapters[chapter];
    _model.record.chapter = chapter;
    _model.record.page = page;
    [LSYReadModel updateLocalModel:_model url:_resourceURL];
    NSLog(@"%@",_resourceURL);
}
#pragma mark - Read View Controller Delegate
-(void)readViewEndEdit:(LSYReadViewController *)readView
{
    for (UIGestureRecognizer *ges in self.pageViewController.view.gestureRecognizers) {
        if ([ges isKindOfClass:[UIPanGestureRecognizer class]]) {
            ges.enabled = YES;
            break;
        }
    }
}
-(void)readViewEditeding:(LSYReadViewController *)readView
{
    for (UIGestureRecognizer *ges in self.pageViewController.view.gestureRecognizers) {
        if ([ges isKindOfClass:[UIPanGestureRecognizer class]]) {
            ges.enabled = NO;
            break;
        }
    }
}
#pragma mark -PageViewController DataSource
- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{

    _pageChange = _page;
    _chapterChange = _chapter;

    if (_chapterChange==0 &&_pageChange == 0) {
        return nil;
    }
    if (_pageChange==0) {
        _chapterChange--;
        _pageChange = _model.chapters[_chapterChange].pageCount-1;
    }
    else{
        _pageChange--;
    }
    
    
    return [self readViewWithChapter:_chapterChange page:_pageChange];
    
}
- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{

    _pageChange = _page;//当前的页数
    _chapterChange = _chapter;
    if (_pageChange == _model.chapters.lastObject.pageCount-1 && _chapterChange == _model.chapters.count-1) {
        NSLog(@"%lu",_model.chapters.lastObject.pageCount-1);
        return nil;
    }
    if (_pageChange == _model.chapters[_chapterChange].pageCount-1) {
        _chapterChange++;
        _pageChange = 0;
    }
    else{
        _pageChange++;
    }
    return [self readViewWithChapter:_chapterChange page:_pageChange];
}
#pragma mark -PageViewController Delegate
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (!completed) {
        LSYReadViewController *readView = previousViewControllers.firstObject;
        _readView = readView;
        _page = readView.recordModel.page;
        _chapter = readView.recordModel.chapter;
    }
    else{
        [self updateReadModelWithChapter:_chapter page:_page];
    }
}
- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers
{
    _chapter = _chapterChange;
    _page = _pageChange;
}
-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    _pageViewController.view.frame = self.view.frame;
    _menuView.frame = self.view.frame;
    _catalogView.frame = CGRectMake(-ViewSize(self.view).width, 0, 2*ViewSize(self.view).width, ViewSize(self.view).height);
    _catalogVC.view.frame = CGRectMake(0, 0, ViewSize(self.view).width-100, ViewSize(self.view).height);
    [_catalogVC reload];
}

#define mark - 解析xml
-(void)parserDidStartDocument:(NSXMLParser *)parser
{
    // NSLog(@"开始解析文档");
    self.epubArray = [NSMutableArray arrayWithCapacity:0];
}
-(void)parser:(NSXMLParser *)parser didStartElement:(nonnull NSString *)elementName namespaceURI:(nullable NSString *)namespaceURI qualifiedName:(nullable NSString *)qName attributes:(nonnull NSDictionary<NSString *,NSString *> *)attributeDict
{
    // NSLog(@"遇到开始标签%@",elementName);
    _eleString = elementName;
}
-(void)parser:(NSXMLParser *)parser foundCharacters:(nonnull NSString *)string
{
    // NSLog(@"遇到内容:%@",string );
    //  self.epubString = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    //    const long gb30= 0x80000632;
    //    const long gbKK= 0x80000631;
    //    char* ansiStr = (char *)string;
    //    NSString* nsStr= [NSString stringWithCString:ansiStr encoding: gb30];
    //
    //NSLog(@"%@",_eleString);
    if ([_eleString isEqualToString:@"a"]||[_eleString isEqualToString:@"div"]||[_eleString isEqualToString:@"title"])
    {
        
        if ([string rangeOfString:@"\n"].location == NSNotFound )
        {
            [_Arr addObject:string];
        }
    
    }    else if  ([_eleString isEqualToString:@"ruby"]||[_eleString isEqualToString:@"rt"]||[_eleString isEqualToString:@"p"])
    {
        
        if ([self PureLetters:string])
        {
            
            self.zmStr = string;
            // NSLog(@"前面的字符是：%@",self.zmStr);
        }
        else
        {
            self.string = string;
            
            self.string = [NSString  stringWithFormat:@"%@%@",self.zmStr,self.string];
            self.zmStr = @"";
            if ([self.string rangeOfString:@"\n"].location == NSNotFound )
            {
                [_Arr addObject:[NSString stringWithFormat:@"%@\n",self.string]];
                
                if ([_eleString isEqualToString:@"rt"])
                {
                    //NSLog(@"rt-------------  %@",self.string);
                }
            }
            
            
            
        }
        //
        
    }
    
    
}
//是否是纯字母

-(BOOL)PureLetters:(NSString*)str{
    
    for(int i=0;i<str.length;i++){
        
        unichar c=[str characterAtIndex:i];
        
        if((c<'A'||c>'Z')&&(c<'a'||c>'z'))
            
            return NO;
        
    }
    
    return YES;
    
}
-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    // NSLog(@"遇到结束标签:%@",elementName);
    if ([elementName isEqualToString:@"ruby"]) {
        
        //[_epubArray addObject:self.epubString];
        
        
        //   [_epubArray addObject:self.epubString];
    }
    
    
}
@end
