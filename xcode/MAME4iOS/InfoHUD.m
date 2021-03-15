//
//  InfoHUD.m
//  Wombat
//
//  Created by Todd Laney on 6/4/20.
//  Copyright © 2020 Wombat. All rights reserved.
//

#import "InfoHUD.h"
#import <objc/runtime.h> // just for Associated Objects, I promise!

@interface UIImage()
+ (UIImage*)imageWithString:(NSString*)str withFont:(UIFont*)font;
+ (UIImage*)imageWithText:(NSString*)textLeft image:(UIImage*)image text:(NSString*)textRight font:(UIFont*)font;
@end

#define HUD_BLUR    TRUE

@implementation InfoHUD {
    UIStackView* _stack;
    NSMutableDictionary* _views;
    NSMutableDictionary* _format;
    NSMutableDictionary* _step;
    CGFloat _width;
    NSInteger _selected;    // currently "selected" item in the stack view, or -1 for nada
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    self.layoutMargins = UIEdgeInsetsMake(16, 16, 16, 16);
    self.insetsLayoutMarginsFromSafeArea = NO;
    
    _moveable = TRUE;
    _sizeable = TRUE;
    
    _views = [[NSMutableDictionary alloc] init];
    _format = [[NSMutableDictionary alloc] init];
    _step = [[NSMutableDictionary alloc] init];

    _stack = [[UIStackView alloc] init];
    _stack.axis = UILayoutConstraintAxisVertical;
    _stack.spacing = 4.0;
    _stack.distribution = UIStackViewDistributionEqualSpacing;
    _stack.alignment = UIStackViewAlignmentFill;
    
    _selected = -1;
    
    self.font = nil;
    
    if (@available(iOS 13.0, tvOS 13.0, *))
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    
    [self addSubview:_stack];
    
#if TARGET_OS_IOS
    UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    pan.delegate = (id<UIGestureRecognizerDelegate>)self;
    [self addGestureRecognizer:pan];

    UIPinchGestureRecognizer* pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    pinch.delegate = (id<UIGestureRecognizerDelegate>)self;
    pinch.delaysTouchesBegan = YES;
    [self addGestureRecognizer:pinch];
#endif

    self.backgroundColor = HUD_BLUR ? nil : [UIColor.darkGrayColor colorWithAlphaComponent:0.8];
    
    return self;
}

- (void)setBackgroundColor:(UIColor *)color {
    [super setBackgroundColor:color];
    
    for (UIView* view in self.subviews)
        [view removeFromSuperview];
    [self addSubview:_stack];

    if (color == nil) {
#if TARGET_OS_IOS
        if (@available(iOS 13.0, *))
            [self addBlur:UIBlurEffectStyleSystemUltraThinMaterialDark];
        else
            [self addBlur:UIBlurEffectStyleDark];
#else
        [self addBlur:UIBlurEffectStyleExtraDark];
#endif
    }
}

- (void)setSpacing:(CGFloat)spacing {
    _stack.spacing = spacing;
}
- (CGFloat)spacing {
    return _stack.spacing;
}
- (void)setFont:(UIFont *)font {
    _font = font ?: [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

- (void)addBlur:(UIBlurEffectStyle)style {
    UIBlurEffect* blur = [UIBlurEffect effectWithStyle:style];
    UIVisualEffectView* effectView = [[UIVisualEffectView alloc] initWithEffect:blur];
    effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    effectView.frame = self.bounds;
//    for (UIView* view in self.subviews)
//        [effectView.contentView addSubview:view];
    [self addSubview:effectView];
    [self sendSubviewToBack:effectView];
}

#if TARGET_OS_IOS
// called before touchesBegan:withEvent: is called on the gesture recognizer for a new touch. return NO to prevent the gesture recognizer from seeing this touch
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer.view == self && [touch.view isKindOfClass:[UISlider class]]) {
        UISlider* slider = (UISlider*)touch.view;
        CGRect rect = [slider thumbRectForBounds:slider.bounds trackRect:[slider trackRectForBounds:slider.bounds] value:slider.value];
        if (CGRectContainsPoint(CGRectInset(rect, -8, -8), [touch locationInView:slider]))
            return NO;
    }
    return YES;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return gestureRecognizer.view == otherGestureRecognizer.view;
}
- (void)pan:(UIPanGestureRecognizer*)pan {
    if (!_moveable)
        return;
    CGPoint translation = [pan translationInView:self.superview];
    [pan setTranslation:CGPointZero inView:self.superview];
    
    CGPoint center = self.center;
    center.x += translation.x;
    center.y += translation.y;
    self.center = center;
}
- (void)pinch:(UIPinchGestureRecognizer*)pinch {
    if (!_sizeable)
        return;
    self.transform = CGAffineTransformScale(self.transform, pinch.scale, pinch.scale);
    pinch.scale = 1.0;
}

- (void)slide:(UISlider*)slider {
    NSString* key = (__bridge NSString*)(void*)slider.tag;
    [self setValue:@(slider.value) forKey:key];
    _changedKey = key;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
- (void)switch:(UISwitch*)sender {
    NSString* key = (__bridge NSString*)(void*)sender.tag;
    [self setValue:@(sender.isOn ? 1.0 : 0.0) forKey:key];
    _changedKey = key;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
#endif

- (void)setLayoutMargins:(UIEdgeInsets)layoutMargins {
    [super setLayoutMargins:layoutMargins];
    self.layer.cornerRadius = MIN(self.layoutMargins.top, self.layoutMargins.left);
    self.layer.masksToBounds = self.layer.cornerRadius != 0.0;
}

- (NSArray<NSString*>*)allKeys {
    return [_views allKeys];
}

- (void)removeAll {
    [_views removeAllObjects];
    for (UIView* view in _stack.subviews)
        [view removeFromSuperview];
    _width = 0.0;
    _selected = -1;
}

- (UIImage*)dotWithColor:(UIColor*)color size:(CGSize)size
{
    return [[[UIGraphicsImageRenderer alloc] initWithSize:size] imageWithActions:^(UIGraphicsImageRendererContext * context) {
        [color setFill];
        CGContextFillEllipseInRect(context.CGContext, CGRectMake(0, 0, size.width, size.height));
    }];
}

- (UIView*)separatorViewWithHeight:(CGFloat)height color:(UIColor*)color {
    UIView* view = [[UIView alloc] init];
    view.backgroundColor = color;
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:height]];
    return view;
}

- (void)addValue:(id)value forKey:(NSString *)key format:(NSString*)format min:(id)min max:(id)max step:(id)step {

    key = key ?: @"";
    
    if (format.length == 0) {
        if ([step floatValue] >= 1)
            format = @"%0.0f";
        else if ([step floatValue] >= 0.1)
            format = @"%0.1f";
        else if ([step floatValue] >= 0.01)
            format = @"%0.2f";
        else
            format = @"%0.3f";
    }
    
    if ([format hasPrefix:@"%"] && key.length != 0)
        format = [NSString stringWithFormat:@"%@: %@", key, format];

    if ([value isKindOfClass:[NSString class]] && [value isEqualToString:@"---"]) {
        value = [self separatorViewWithHeight:1.0 color:UIColor.clearColor];
        [_stack addArrangedSubview:value];
        value = [self separatorViewWithHeight:1.0 color:UIColor.darkGrayColor];
        [_stack addArrangedSubview:value];
        value = [self separatorViewWithHeight:1.0 color:UIColor.clearColor];
    }
    if ([value isKindOfClass:[NSString class]] && [value isEqualToString:@" "]) {
        value = [self separatorViewWithHeight:3.0 color:UIColor.clearColor];
    }
    if ([value isKindOfClass:[UIImage class]]) {
        value = [[UIImageView alloc] initWithImage:value];
        [value setContentMode:UIViewContentModeScaleAspectFit];
    }

    if ([value isKindOfClass:[UIView class]]) {
        _views[key] = value;
        [_stack addArrangedSubview:value];
        return;
    }

    UILabel* label = [[UILabel alloc] init];
    label.font = _font;
    label.textColor = [UIColor.whiteColor colorWithAlphaComponent:0.75];
    _views[key] = label;
    _format[key] = format;
    _step[key] = step;
    [_stack addArrangedSubview:label];

    if ([value isKindOfClass:[NSString class]] && [value hasPrefix:@"**"] && [value hasSuffix:@"**"]) {
        value = [value substringWithRange:NSMakeRange(2, [value length]-4)];
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    }
    
    if ([value isKindOfClass:[NSString class]])
        _width = MAX(_width, ceil([value sizeWithAttributes:@{NSFontAttributeName:label.font}].width));
    
#if TARGET_OS_IOS
    if ([value isKindOfClass:[NSNumber class]] && [min floatValue] == 0.0 && [max floatValue] == 1.0 && [step floatValue] == 1.0) {
        _format[key] = nil;
        label.text = key;
        UISwitch* sw = [[UISwitch alloc] init];
        [sw addTarget:self action:@selector(switch:) forControlEvents:UIControlEventValueChanged];
        CGFloat h = _font.lineHeight;
        CGFloat scale =  h / [sw sizeThatFits:CGSizeZero].height;
        sw.transform = CGAffineTransformMakeScale(scale, scale);
        sw.tag = (NSUInteger)(__bridge void*)key;
        sw.onTintColor = self.tintColor;
        label.tag = (NSUInteger)(__bridge void*)sw;
        [_stack.subviews.lastObject removeFromSuperview];
        UIStackView* stack = [[UIStackView alloc] initWithArrangedSubviews:@[label, sw]];
        [_stack addArrangedSubview:stack];
    }
    else if ([value isKindOfClass:[NSNumber class]] && min != nil && max != nil) {
        UISlider* slider = [[UISlider alloc] init];
        CGFloat h = _font.lineHeight;
        [slider addConstraint:[NSLayoutConstraint constraintWithItem:slider attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:h]];
        [slider addTarget:self action:@selector(slide:) forControlEvents:UIControlEventValueChanged];
        slider.minimumValue = [min floatValue];
        slider.maximumValue = [max floatValue];
        slider.tag = (NSUInteger)(__bridge void*)key;
        label.tag = (NSUInteger)(__bridge void*)slider;
         [_stack addArrangedSubview:slider];
        
        for (NSNumber* num in @[min,max,value])
            _width = MAX(_width, ceil([[NSString stringWithFormat:format, [num floatValue], key] sizeWithAttributes:@{NSFontAttributeName:label.font}].width));
        
        if ([key hasSuffix:@"_r"] || [key hasSuffix:@"_red"]   || [key hasSuffix:@"-r"] || [key hasSuffix:@"-red"])
            slider.tintColor = UIColor.systemRedColor;
        if ([key hasSuffix:@"_g"] || [key hasSuffix:@"_green"] || [key hasSuffix:@"-g"] || [key hasSuffix:@"-green"])
            slider.tintColor = UIColor.systemGreenColor;
        if ([key hasSuffix:@"_b"] || [key hasSuffix:@"_blue"]  || [key hasSuffix:@"-b"] || [key hasSuffix:@"-blue"])
            slider.tintColor = UIColor.systemBlueColor;
        if ([key hasSuffix:@"_a"] || [key hasSuffix:@"_alpha"]  || [key hasSuffix:@"-a"] || [key hasSuffix:@"-alpha"])
            slider.minimumTrackTintColor = UIColor.darkGrayColor;

        [slider setThumbImage:[self dotWithColor:(slider.minimumTrackTintColor ?: slider.tintColor) size:CGSizeMake(12,12)] forState:UIControlStateNormal];
    }
#endif
    
    [self setValue:value forKey:key];
}
- (void)addValue:(id)value forKey:(NSString *)key format:(NSString*)format min:(id)min max:(id)max {
    [self addValue:value forKey:key format:format min:min max:max step:nil];
}
- (void)addValue:(id)value forKey:(NSString *)key format:(NSString*)format {
    [self addValue:value forKey:key format:format min:nil max:nil];
}
- (void)addValue:(id)value forKey:(NSString *)key {
    [self addValue:value forKey:key format:nil min:nil max:nil];
}
- (void)addValue:(id)value {
    [self addValue:value forKey:nil format:nil min:nil max:nil];
}
- (void)addValues:(NSDictionary*)values {
    for (NSString* key in [values allKeys])
        [self addValue:values[key] forKey:key];
}
- (void)addText:(NSString*)str {
    [self addValue:str];
}
- (void)addImage:(UIImage*)image {
    [self addValue:image];
}
- (void)addView:(UIView*)view {
    [self addValue:view];
}
- (void)addSeparator {
    [self addValue:@"---"];
}
- (void)addTitle:(NSString*)str {
    [self addValue:str];
    UILabel* label = (UILabel*)_stack.subviews.lastObject;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    label.textAlignment = NSTextAlignmentCenter;
}

- (NSArray*)convertItems:(NSArray*)_items {
    
    if (![[UIImage class] respondsToSelector:@selector(imageWithString:withFont:)])
        return _items;
        
    NSMutableArray* items = [_items mutableCopy];
    for (NSUInteger idx=0; idx<items.count; idx++) {
        id item = items[idx];
        if ([item isKindOfClass:[NSString class]] && ([item hasPrefix:@":"] || [item hasSuffix:@":"]))
            items[idx] = [UIImage imageWithString:item withFont:self.font];
    }
    return [items copy];
}

- (void)buttonPress:(UISegmentedControl*)seg {
    void (^handler)(NSUInteger) = objc_getAssociatedObject(seg, @selector(buttonPress:));
    handler(seg.selectedSegmentIndex);
}
- (UISegmentedControl*)makeSegmentedControl:(NSArray*)items handler:(void (^)(NSUInteger button))handler {
    UISegmentedControl* seg = [[UISegmentedControl alloc] initWithItems:[self convertItems:items]];
    seg.momentary = YES;
    [seg setTitleTextAttributes:@{NSFontAttributeName:_font} forState:UIControlStateNormal];
    
    CGFloat h = _font.lineHeight * 1.5;
    [seg addConstraint:[NSLayoutConstraint constraintWithItem:seg attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:h]];

    [seg addTarget:self action:@selector(buttonPress:) forControlEvents:UIControlEventValueChanged];
    objc_setAssociatedObject(seg, @selector(buttonPress:), handler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 13.0, tvOS 13.0, *))
         seg.selectedSegmentTintColor = self.tintColor;
    if (items.firstObject == (id)@"")
        seg.alpha = 0.0;
    return seg;
}

- (void)addToolbar:(NSArray*)items handler:(void (^)(NSUInteger button))handler {
    UISegmentedControl* seg = [self makeSegmentedControl:items handler:handler];
    seg.apportionsSegmentWidthsByContent = YES;
    [self addView:seg];
}
- (void)addButtons:(NSArray*)items color:(UIColor*)color handler:(void (^)(NSUInteger button))handler {
    UIStackView* stack = [[UIStackView alloc] init];
    stack.spacing = self.spacing;
    stack.distribution = UIStackViewDistributionFillEqually;

    for (NSUInteger i = 0; i<items.count; i++) {
        id item = items[i];
        if (![item isKindOfClass:[UIView class]]) {
            UISegmentedControl* seg = item = [self makeSegmentedControl:@[item] handler:^(NSUInteger button) {
                handler(i);
            }];
            seg.backgroundColor = color;
            if (@available(iOS 13.0, tvOS 13.0, *))
                seg.selectedSegmentTintColor = (color == nil || color == UIColor.clearColor) ? self.tintColor : color;
            if (color == UIColor.clearColor)
                [seg setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        }
        [stack addArrangedSubview:item];
    }
    [self addView:stack];
}
- (void)addButtons:(NSArray*)items handler:(void (^)(NSUInteger button))handler {
    [self addButtons:items color:nil handler:handler];
}

- (void)addButton:(id)item color:(UIColor*)color handler:(void (^)(void))handler {
    NSParameterAssert([item isKindOfClass:[NSString class]] || [item isKindOfClass:[UIImage class]]);
    [self addButtons:@[item] color:color handler:^(NSUInteger button) {
        handler();
    }];
}
- (void)addButton:(id)item handler:(void (^)(void))handler {
    [self addButton:item color:nil handler:handler];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    UILabel* label = _views[key];
    
    if (![label isKindOfClass:[UILabel class]])
        return;

    if ([value isKindOfClass:[NSNumber class]]) {
        float val = [value floatValue];
        NSString* format = _format[key];
        float step = [_step[key] floatValue];
        if (step != 0.0)
            val = round(val / step) * step;
        if (format != nil)
            label.text = [NSString stringWithFormat:format, val];
#if TARGET_OS_IOS
        UISlider* slider = (__bridge UISlider*)(void*)label.tag;
        if ([slider isKindOfClass:[UISlider class]] && !slider.isTracking)
            slider.value = val;
        if ([slider isKindOfClass:[UISwitch class]])
            [(UISwitch*)slider setOn:val != 0.0];
#endif
    }
    else if ([value isKindOfClass:[NSString class]]) {
        label.text = value;
    }
    else {
        label.text = [value description];
    }
}
- (void)setValues:(NSDictionary*)values {
    for (NSString* key in [values allKeys])
        [self setValue:values[key] forKey:key];
}
- (id)valueForKey:(NSString *)key {
    if ([key length] == 0)
        return nil;
    UILabel* label = _views[key];
    if (![label isKindOfClass:[UILabel class]])
        return label;
#if TARGET_OS_IOS
    UISlider* slider = (__bridge UISlider*)(void*)label.tag;
    float step = [_step[key] floatValue];
    if (([slider isKindOfClass:[UISlider class]]))
        return @((step != 0.0) ? round(slider.value / step) * step : slider.value);
    else if (([slider isKindOfClass:[UISwitch class]]))
        return [(UISwitch*)slider isOn] ? @(1) : @(0);
#endif
    if ([label.text containsString:@": "])
        return @([label.text componentsSeparatedByString:@": "].lastObject.floatValue);
    else
        return label.text;
}
- (NSDictionary*)getValues {
    NSMutableDictionary* values = [[NSMutableDictionary alloc] init];
    for (NSString* key in self.allKeys)
        values[key] = [self valueForKey:key];
    return values;
}

- (CGSize)sizeThatFits:(CGSize)size {
    size = [_stack systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    size.width = MAX(_width, size.width);
    if (size.width != 0 && size.height != 0) {
        size.width = ceil(size.width) + self.layoutMargins.left + self.layoutMargins.right;
        size.height = ceil(size.height) + self.layoutMargins.top + self.layoutMargins.bottom;
    }
    return size;
}

- (void)layoutSubviews {
    _stack.frame = UIEdgeInsetsInsetRect(self.bounds, self.layoutMargins);
}

#pragma mark - selection

- (NSArray*)getSelectableItems {
    NSMutableArray* items = [[NSMutableArray alloc] init];
    
    for (UIView* view in _stack.subviews) {
        if ([view isKindOfClass:[UISegmentedControl class]])
            [items addObject:view];
        if ([view isKindOfClass:[UIStackView class]] && [view.subviews.firstObject isKindOfClass:[UISegmentedControl class]])
            [items addObject:view];
    }
    
    return items;
}

- (NSUInteger)getNumberOfSegments:(UIView*)view {
    if ([view isKindOfClass:[UISegmentedControl class]])
        return [(UISegmentedControl*)view numberOfSegments];
    else
        return view.subviews.count;
}

- (NSInteger)getSelectedSegmentIndex:(UIView*)view {
    
    if ([view isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl* seg = (UISegmentedControl*)view;
        return seg.selectedSegmentIndex;
    }
    
    if ([view isKindOfClass:[UIStackView class]]) {
        UIStackView* stack = (UIStackView*)view;
        for (NSInteger i=0; i<stack.subviews.count; i++) {
            UISegmentedControl* seg = (UISegmentedControl*)stack.subviews[i];
            if ([seg isKindOfClass:[UISegmentedControl class]] && seg.selectedSegmentIndex != UISegmentedControlNoSegment) {
                return i;
            }
        }
    }
    
    return UISegmentedControlNoSegment;
}

- (void)setSelectedSegmentIndex:(UIView*)view index:(NSInteger)index {
    
    if ([view isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl* seg = (UISegmentedControl*)view;
        seg.selectedSegmentIndex = index;
    }
    
    if ([view isKindOfClass:[UIStackView class]]) {
        UIStackView* stack = (UIStackView*)view;
        for (NSInteger i=0; i<stack.subviews.count; i++) {
            UISegmentedControl* seg = (UISegmentedControl*)stack.subviews[i];
            if ([seg isKindOfClass:[UISegmentedControl class]]) {
                seg.selectedSegmentIndex = (i == index) ? 0 : UISegmentedControlNoSegment;
                if (seg.backgroundColor == UIColor.clearColor)
                    [seg setBackgroundImage:((i == index) ? nil : [[UIImage alloc] init]) forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            }
        }
    }
}

// move current selection and perfom action, used with input from a game controller, keyboard, or remote.
- (void)handleButtonPress:(UIPressType)type {
    NSArray* items = [self getSelectableItems];
    UIView* item = (_selected >= 0 && _selected < items.count) ? items[_selected] : nil;
    
    switch (type) {
        case UIPressTypeUpArrow:
        case UIPressTypeDownArrow:
        {
            NSInteger dir = (type == UIPressTypeUpArrow) ? -1 : +1;
            NSInteger n = _selected + dir;
            
            if (n >= 0 && n < items.count) {
                NSInteger index = MAX(0, [self getSelectedSegmentIndex:item]) * [self getNumberOfSegments:items[n]] / MAX(1, [self getNumberOfSegments:item]);
                [self setSelectedSegmentIndex:items[n] index:index];
                [self setSelectedSegmentIndex:item index:UISegmentedControlNoSegment];
                _selected = n;
            }
            break;
        }
        case UIPressTypeLeftArrow:
        case UIPressTypeRightArrow:
        {
            NSInteger dir = (type == UIPressTypeLeftArrow) ? -1 : +1;
            if (item == nil && items.count != 0) {
                _selected = 0;
                item = items[_selected];
            }
            NSInteger n = [self getSelectedSegmentIndex:item] + dir;
            n = MIN(MAX(0,n), [self getNumberOfSegments:item]-1);
            [self setSelectedSegmentIndex:item index:n];
            break;
        }
        case UIPressTypeSelect:
            if ([item isKindOfClass:[UISegmentedControl class]])
                [self buttonPress:(UISegmentedControl*)item];
            if ([item isKindOfClass:[UIStackView class]]) {
                NSInteger n = [self getSelectedSegmentIndex:item];
                if (n >= 0 && n < item.subviews.count)
                    [self buttonPress:(UISegmentedControl*)item.subviews[n]];
            }
            break;
        default:
            break;
    }
}
@end

#pragma mark - InfoHUD ViewController

#if TARGET_OS_TV
#define UIModalPresentationPopover ((UIModalPresentationStyle)7)
#endif

@implementation HUDViewController {
    InfoHUD* _hud;
    void (^_cancelHandler)(void);
    void (^_dismissHandler)(void);
}

- (instancetype)init {
    self = [super init];
    
    _blurBackground = YES;
    _dimBackground = 0.5;
    
    _hud = [[InfoHUD alloc] init];
    _hud.moveable = NO;
    _hud.sizeable = NO;

    return self;
}

- (void)setTitle:(NSString*)title {
    [super setTitle:title];
    if (self.title.length != 0) {
        [_hud addTitle:self.title];
        [_hud addSeparator];
    }
}

- (void)setModalPresentationStyle:(UIModalPresentationStyle)style {

    if (style == UIModalPresentationFullScreen)
        style = UIModalPresentationOverFullScreen;
    
#if TARGET_OS_TV
    if (style == UIModalPresentationOverFullScreen && _blurBackground)
        style = UIModalPresentationBlurOverFullScreen;
#endif
    
    [super setModalPresentationStyle:style];

    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

#if TARGET_OS_IOS
    if (style == UIModalPresentationPopover) {
        // remove the background from the InfoHUD
        _hud.backgroundColor = UIColor.clearColor;
        self.popoverPresentationController.delegate = (id<UIPopoverPresentationControllerDelegate>)self;

        if (@available(iOS 13.0, tvOS 13.0, *))
            self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
        else
            self.popoverPresentationController.backgroundColor = [UIColor colorWithWhite:0.111 alpha:1.0];
    }
#endif
}

- (void)addButtons:(NSArray*)items style:(HUDButtonStyle)style handler:(void (^)(NSUInteger button))handler {
    
    UIColor* color = nil;
    
    if (style == HUDButtonStyleDestructive)
        color = UIColor.systemRedColor;
    if (style == HUDButtonStylePlain)
        color = UIColor.clearColor;

    // we want to dismiss the ViewController *before* we call any button callbacks
    __unsafe_unretained typeof(self) _self = self;
    [_hud addButtons:items color:color handler:^(NSUInteger button) {
        _self->_cancelHandler = nil;    // no need to call cancel handler now.
        [_self.presentingViewController dismissViewControllerAnimated:YES completion:^{
            handler(button);
        }];
    }];
}

- (void)addButton:(id)item style:(HUDButtonStyle)style handler:(void (^)(void))handler {
    if (style == HUDButtonStyleCancel) {
        [self onCancel:handler];
        [_hud addText:@" "];
    }
    [self addButtons:@[item] style:style handler:^(NSUInteger button) {
        handler();
    }];
}

- (void)onCancel:(void (^)(void))handler {
    _cancelHandler = handler;
}

- (void)onDismiss:(void (^)(void))handler {
    _dismissHandler = handler;
}

- (void)tap {
    [self.presentingViewController dismissViewControllerAnimated:TRUE completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
#if TARGET_OS_IOS
    if (self.modalPresentationStyle != UIModalPresentationPopover && _blurBackground) {
        UIBlurEffectStyle style = UIBlurEffectStyleDark;

        if (@available(iOS 13.0, *))
            style = UIBlurEffectStyleSystemUltraThinMaterialDark;

        UIBlurEffect* blur = [UIBlurEffect effectWithStyle:style];
        UIVisualEffectView* effectView = [[UIVisualEffectView alloc] initWithEffect:blur];
        effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        effectView.frame = self.view.bounds;
        [self.view addSubview:effectView];
    }
#endif
    [self.view addSubview:_hud];
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)]];
}

- (CGSize)preferredContentSize {
    return [_hud sizeThatFits:CGSizeZero];
}

- (void)viewWillAppear:(BOOL)animated {
    CGSize size = self.preferredContentSize;
    self.preferredContentSize = size;

    if (self.modalPresentationStyle != UIModalPresentationPopover) {

        // TODO: change the font on tvOS instead
        CGFloat scale = TARGET_OS_TV ? 1.5 : 1.0;
        
        if (size.width * scale > self.view.bounds.size.width * 0.95)
            scale = self.view.bounds.size.width * 0.95 / size.width;

        if (size.height * scale > self.view.bounds.size.height * 0.95)
            scale = self.view.bounds.size.height * 0.95 / size.height;
        
        _hud.transform = CGAffineTransformMakeScale(0.001, 0.001);
        [UIView animateWithDuration:0.200 animations:^{
            if (!self->_blurBackground && self->_dimBackground != 0.0)
                self.view.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:self->_dimBackground];
            self->_hud.transform = CGAffineTransformMakeScale(scale, scale);
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    
    if (_cancelHandler)
        _cancelHandler();
    if (_dismissHandler)
        _dismissHandler();

    if (self.modalPresentationStyle == UIModalPresentationPopover) {
        [UIView animateWithDuration:0.200 animations:^{
            if (!self->_blurBackground && self->_dimBackground != 0.0)
                self.view.backgroundColor = UIColor.clearColor;
            self->_hud.transform = CGAffineTransformMakeScale(0.001, 0.001);
        }];
    }
}
- (void)viewWillLayoutSubviews {
    UIEdgeInsets safe = self.view.safeAreaInsets;
    [_hud sizeToFit];
    _hud.center = CGPointMake(safe.left + (self.view.bounds.size.width - safe.left - safe.right)/2 ,
                              safe.top + (self.view.bounds.size.height - safe.top - safe.bottom)/2);
}

#pragma mark - handleButtonPress

// move current selection and perfom action, used with input from a game controller, keyboard, or remote.
- (void)handleButtonPress:(UIPressType)type {
    
    // MENU => CANCEL
    if (type == UIPressTypeMenu)
        return [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    return [_hud handleButtonPress:type];
}

#pragma mark - UIPopoverPresentationControllerDelegate

#if TARGET_OS_IOS

// Returning UIModalPresentationNone will indicate that an adaptation should not happen.
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}
// -popoverPresentationController:willRepositionPopoverToRect:inView: is called on your delegate when the
// popover may require a different view or rectangle.
- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect*)rect inView:(inout UIView**)view {
    NSLog(@"willRepositionPopoverToRect:%@ view:%@", NSStringFromCGRect(*rect), *view);
    
    popoverPresentationController.permittedArrowDirections = 0;
    *view = self.presentingViewController.view;
    *rect = CGRectMake(self.presentingViewController.view.bounds.size.width/2, self.presentingViewController.view.bounds.size.height/2, 0, 0);
}
#endif

@end

#pragma mark - InfoHUD AlertController

@implementation HUDAlertController {
    NSMutableArray* _actions;
}

+ (instancetype)alertControllerWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(UIAlertControllerStyle)preferredStyle {
    NSParameterAssert(preferredStyle == UIAlertControllerStyleActionSheet);
    NSParameterAssert(message == nil);
    HUDAlertController* alert = [[HUDAlertController alloc] init];
    alert.title = title;
    return alert;
}

- (void)addAction:(UIAlertAction *)action {
    _actions = _actions ?: [[NSMutableArray alloc] init];

    id item = action.title;
    if ([action respondsToSelector:@selector(image)] && [action valueForKey:@"image"] != nil)
         item = [UIImage imageWithText:nil image:[action valueForKey:@"image"] text:action.title font:nil];
    
    void (^handler)(UIAlertAction *) = nil;
    if ([action respondsToSelector:@selector(handler)])
        handler = [action valueForKey:@"handler"];

    [_actions addObject:action];
    [self addButton:item style:(HUDButtonStyle)action.style handler:^{
        if (handler != nil)
            handler(action);
    }];
}

- (NSArray<UIAlertAction *> *)actions {
    return [_actions copy];
}

@end

