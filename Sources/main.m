#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#import <dlfcn.h>

typedef int CGSConnectionID;
typedef int CGSWindowID;
typedef int CGError;
typedef CGSConnectionID (*CGSMainConnectionIDFunc)(void);
typedef CGError (*CGSSetWindowAlphaFunc)(CGSConnectionID, CGSWindowID, float);

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property NSStatusItem *item;
@property NSWindow *panel;
@property NSSlider *slider;
@property NSTextField *label;
@property float alpha;
@property CGSConnectionID connection;
@property CGSSetWindowAlphaFunc setAlpha;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.alpha = 1.0;

    void *handle = dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_LAZY);
    if (handle) {
        CGSMainConnectionIDFunc mainConnection =
            (CGSMainConnectionIDFunc)dlsym(handle, "CGSMainConnectionID");
        self.setAlpha =
            (CGSSetWindowAlphaFunc)dlsym(handle, "CGSSetWindowAlpha");
        if (mainConnection) self.connection = mainConnection();
    }

    self.item = [[NSStatusBar systemStatusBar]
                 statusItemWithLength:NSVariableStatusItemLength];
    self.item.button.title = @"α";

    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Window Transparency"];

    NSMenuItem *control =
        [[NSMenuItem alloc] initWithTitle:@"Control de transparencia"
                                   action:@selector(showPanel:)
                            keyEquivalent:@""];
    control.target = self;
    [menu addItem:control];

    NSMenuItem *reset =
        [[NSMenuItem alloc] initWithTitle:@"Restaurar 100%"
                                   action:@selector(reset:)
                            keyEquivalent:@""];
    reset.target = self;
    [menu addItem:reset];

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *quit =
        [[NSMenuItem alloc] initWithTitle:@"Salir"
                                   action:@selector(quit:)
                            keyEquivalent:@""];
    quit.target = self;
    [menu addItem:quit];

    self.item.menu = menu;

    self.panel =
        [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,390,160)
                                    styleMask:(NSTitledWindowMask |
                                               NSClosableWindowMask)
                                      backing:NSBackingStoreBuffered
                                        defer:NO];

    self.panel.title = @"Window Transparency";
    self.panel.level = NSFloatingWindowLevel;

    NSTextField *title =
        [[NSTextField alloc] initWithFrame:NSMakeRect(25,115,340,22)];
    title.stringValue = @"Transparencia de Chrome / Firefox";
    title.editable = NO;
    title.bezeled = NO;
    title.drawsBackground = NO;
    [self.panel.contentView addSubview:title];

    self.slider =
        [[NSSlider alloc] initWithFrame:NSMakeRect(25,75,340,24)];
    self.slider.minValue = 0.20;
    self.slider.maxValue = 1.0;
    self.slider.doubleValue = 1.0;
    self.slider.target = self;
    self.slider.action = @selector(sliderChanged:);
    [self.panel.contentView addSubview:self.slider];

    self.label =
        [[NSTextField alloc] initWithFrame:NSMakeRect(25,42,340,22)];
    self.label.stringValue = @"100%";
    self.label.alignment = NSTextAlignmentCenter;
    self.label.editable = NO;
    self.label.bezeled = NO;
    self.label.drawsBackground = NO;
    [self.panel.contentView addSubview:self.label];

    NSTextField *hint =
        [[NSTextField alloc] initWithFrame:NSMakeRect(25,15,340,18)];
    hint.stringValue = @"Selecciona Chrome o Firefox antes de ajustar";
    hint.font = [NSFont systemFontOfSize:10];
    hint.textColor = [NSColor grayColor];
    hint.editable = NO;
    hint.bezeled = NO;
    hint.drawsBackground = NO;
    hint.alignment = NSTextAlignmentCenter;
    [self.panel.contentView addSubview:hint];

    NSDictionary *options =
        @{(__bridge id)kAXTrustedCheckOptionPrompt : @YES};
    AXIsProcessTrustedWithOptions(
        (__bridge CFDictionaryRef)options);
}

- (void)showPanel:(id)sender {
    [self.panel center];
    [NSApp activateIgnoringOtherApps:YES];
    [self.panel makeKeyAndOrderFront:nil];
}

- (void)sliderChanged:(NSSlider *)sender {
    self.alpha = sender.floatValue;
    self.label.stringValue =
        [NSString stringWithFormat:@"%.0f%%", self.alpha * 100.0];
    [self applyAlpha];
}

- (void)reset:(id)sender {
    self.alpha = 1.0;
    self.slider.doubleValue = 1.0;
    self.label.stringValue = @"100%";
    [self applyAlpha];
}

- (pid_t)targetPID {
    NSRunningApplication *app =
        [NSWorkspace.sharedWorkspace frontmostApplication];
    if (!app) return 0;

    NSString *name = app.localizedName.lowercaseString;
    if ([name containsString:@"chrome"] ||
        [name containsString:@"firefox"]) {
        return app.processIdentifier;
    }
    return 0;
}

- (void)applyAlpha {
    if (!self.setAlpha || !self.connection) return;

    pid_t pid = [self targetPID];
    if (!pid) return;

    AXUIElementRef app = AXUIElementCreateApplication(pid);
    if (!app) return;

    CFTypeRef window = NULL;
    AXError error =
        AXUIElementCopyAttributeValue(app,
                                      kAXFocusedWindowAttribute,
                                      &window);

    if (error != kAXErrorSuccess || !window) {
        CFRelease(app);
        return;
    }

    CFTypeRef number = NULL;
    error =
        AXUIElementCopyAttributeValue(
            (AXUIElementRef)window,
            CFSTR("AXWindowNumber"),
            &number);

    if (error == kAXErrorSuccess && number) {
        int windowID = 0;
        if (CFGetTypeID(number) == CFNumberGetTypeID()) {
            CFNumberGetValue((CFNumberRef)number,
                             kCFNumberIntType,
                             &windowID);
        }

        if (windowID > 0) {
            self.setAlpha(self.connection,
                          (CGSWindowID)windowID,
                          self.alpha);
        }

        CFRelease(number);
    }

    CFRelease(window);
    CFRelease(app);
}

- (void)quit:(id)sender {
    [NSApp terminate:nil];
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        app.delegate = delegate;
        [app run];
    }
    return 0;
}
