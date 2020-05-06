/********* PDFViewer.m Cordova Plugin Implementation *******/

#import "PDFViewer.h"

@implementation PDFViewer

- (void)viewPDF:(CDVInvokedUrlCommand*)command
{
    self.command = command;
 
    @try {
        /* input arguments **/
        NSString* base64Str = [command.arguments objectAtIndex:0];
        NSString* pageNoStr = [command.arguments objectAtIndex:1];
        NSString* mode = [command.arguments objectAtIndex:2];
        NSString* direction = [command.arguments objectAtIndex:3];
        NSString* fileName = [command.arguments objectAtIndex:4];
        NSString* pdfBackgroundColour = [command.arguments objectAtIndex:16];
        NSString* disableCopy = [command.arguments objectAtIndex:17];
        
        self.base64Str = base64Str;
        self.fileName = fileName;
        BOOL isCopyDisabled = [disableCopy boolValue];
        
        self.pdfDocument = [[PDFDocument alloc] initWithData:[self getBase64Data]];
        
        [self setToolbar];
       
        self.pdfView = [[PDFView alloc] initWithFrame:CGRectMake(0, 50, self.webView.bounds.size.width, self.webView.bounds.size.height - 50)];
        self.pdfView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.pdfView.displayMode = [mode integerValue];
        self.pdfView.displayDirection = [direction  isEqual: @"vertical"] ? kPDFDisplayDirectionVertical : kPDFDisplayDirectionHorizontal;
        self.pdfView.minScaleFactor = self.pdfView.scaleFactor;
        self.pdfView.maxScaleFactor = self.pdfView.scaleFactorForSizeToFit;
        self.pdfView.backgroundColor = [self colorWithHexString:pdfBackgroundColour alpha:1];
        self.pdfView.autoScales = true;
        [self.pdfView sizeToFit];
        
        if(isCopyDisabled) {
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
            [self.pdfView addGestureRecognizer:longPress];
        }
    
        self.pdfView.document = self.pdfDocument;
        
        if(![pageNoStr isEqual:[NSNull null]]) {
            PDFPage* page = [self.pdfDocument pageAtIndex: [pageNoStr integerValue]];
            [self.pdfView goToPage: page];
        }
        
        if(!self.pdfView.document.pageCount) {
            @throw @"pages not found in pdf document";
        }
        
        [self.webView addSubview:self.pdfView];
        [self.webView bringSubviewToFront: self.pdfView];
        
       [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(viewWillTransitionToSizeNotification:)
        name:CDVViewWillTransitionToSizeNotification
        object:nil];
     
    } @catch(NSException* exception) {
        [self sendPluginResult: exception.reason];
    }
}

-(void)sharePDF:(CDVInvokedUrlCommand*)command {
    self.command = command;
    
    @try {
        NSString* base64Str = [command.arguments objectAtIndex:0];
        NSString* fileName = [command.arguments objectAtIndex:1];
        NSString* shareText = [command.arguments objectAtIndex:2];
        
        self.base64Str = base64Str;
        self.fileName = fileName;
        
        NSData* data = [self getBase64Data];
        
        [self shareFn:nil base64:data shareText:shareText callback:^(BOOL handler) {
            NSString* msg = handler ? nil: @"failed";
            [self sendPluginResult:msg];
        }];
    } @catch(NSException* exception) {
        [self sendPluginResult: exception.reason];
    }
}

-(void)printPDF:(CDVInvokedUrlCommand*)command {
    self.command = command;
    
    @try {
        NSString* base64Str = [command.arguments objectAtIndex:0];
        NSString* fileName = [command.arguments objectAtIndex:1];
        
        self.base64Str = base64Str;
        self.fileName = fileName;
        
        NSData* data = [self getBase64Data];
        
        [self printFn:data callback:^(BOOL handler) {
            NSString* msg = handler ? nil: @"failed";
            [self sendPluginResult:msg];
        }];
    } @catch(NSException* exception) {
        [self sendPluginResult: exception.reason];
    }
}

-(NSData *)getBase64Data {
    NSData* data = [[NSData alloc] initWithBase64EncodedString:self.base64Str options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return data;
}

- (UILongPressGestureRecognizer *)handleLongPress:(UILongPressGestureRecognizer *) recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        recognizer.enabled = false;
    }
    
    return recognizer;
}

- (void) viewWillTransitionToSizeNotification:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:CDVViewWillTransitionToSizeNotification]) {
        NSLog (@"Successfully received the test notification!");
        NSLog(@"%f", self.webView.bounds.size.width);
        self.pdfView.autoScales = true;
        [self.webView layoutSubviews];
    }
}


-(UIColor *)colorWithHexString:(NSString *)str_HEX  alpha:(CGFloat)alpha_range{
    int red = 0;
    int green = 0;
    int blue = 0;
    sscanf([str_HEX UTF8String], "#%02X%02X%02X", &red, &green, &blue);
    return  [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha_range];
}

-(void)setToolbar {

    NSString* toolbarColour = [self.command.arguments objectAtIndex:5];
    NSString* doneBtnColour = [self.command.arguments objectAtIndex:6];
    NSString* doneBtnText = [self.command.arguments objectAtIndex:7];
    NSString* titleColour = [self.command.arguments objectAtIndex:8];
    NSString* titleText = [self.command.arguments objectAtIndex:9];
    NSString* shareBtnColour = [self.command.arguments objectAtIndex:10];
    NSString* shareBtnText = [self.command.arguments objectAtIndex:11];
    NSString* printBtnColour = [self.command.arguments objectAtIndex:12];
    NSString* printBtnText = [self.command.arguments objectAtIndex:13];
    NSString* showShareBtn = [self.command.arguments objectAtIndex:14];
    NSString* showPrintBtn = [self.command.arguments objectAtIndex:15];
    
    BOOL isShareBtnEnabled = [showShareBtn boolValue];
    BOOL isPrintBtnEnabled = [showPrintBtn boolValue];
    
    /* toolbar */
   self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.webView.frame.size.width, 0)];
   self.toolbar.barTintColor = [self colorWithHexString:toolbarColour alpha:1];
   [self.toolbar sizeToFit];
   
   /* title */
   self.titleLabel = [[UILabel alloc] initWithFrame: CGRectZero];
   [self.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:18]];
   [self.titleLabel setBackgroundColor:[UIColor clearColor]];
   [self.titleLabel setTextColor:[self colorWithHexString:titleColour alpha:1]];
   [self.titleLabel setText:titleText];
   [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
    self.titleLabel.frame = CGRectZero;
   [self.titleLabel sizeToFit];
   
   /* close button */
   self.closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
   [self.closeBtn addTarget:self action:@selector(closePDF:) forControlEvents:UIControlEventTouchUpInside];
   [self.closeBtn setTitle:doneBtnText forState:UIControlStateNormal];
   [self.closeBtn setTitleColor:[self colorWithHexString:doneBtnColour alpha:1] forState:UIControlStateNormal];
   self.closeBtn.frame = CGRectZero;
   [self.closeBtn sizeToFit];
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    UIBarButtonItem* flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* fixedItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedItem.width = 30.0f;
    
    UIBarButtonItem* title = [[UIBarButtonItem alloc] initWithCustomView:self.titleLabel];
    UIBarButtonItem* closeBtn = [[UIBarButtonItem alloc] initWithCustomView:self.closeBtn];
    
    [items addObject:closeBtn];
    [items addObject:flexibleItem];
    [items addObject:title];
    [items addObject:flexibleItem];
   
    if(isShareBtnEnabled) {
       /* share button */
       self.shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
       [self.shareBtn addTarget:self action:@selector(share:) forControlEvents:UIControlEventTouchUpInside];
       [self.shareBtn setTitle:shareBtnText forState:UIControlStateNormal];
       [self.shareBtn setTitleColor:[self colorWithHexString:shareBtnColour alpha:1] forState:UIControlStateNormal];
       self.shareBtn.frame = CGRectZero;
       [self.shareBtn sizeToFit];
        
        UIBarButtonItem* shareBtn = [[UIBarButtonItem alloc] initWithCustomView:self.shareBtn];
        
        [items addObject:shareBtn];
        
        if(isPrintBtnEnabled) {
            [items addObject:fixedItem];
        }
    }
    
    if(isPrintBtnEnabled) {
        /* print button */
        self.printBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.printBtn addTarget:self action:@selector(print:) forControlEvents:UIControlEventTouchUpInside];
        [self.printBtn setTitle:printBtnText forState:UIControlStateNormal];
        [self.printBtn setTitleColor:[self colorWithHexString:printBtnColour alpha:1] forState:UIControlStateNormal];
        self.printBtn.frame = CGRectZero;
        [self.printBtn sizeToFit];
        
        UIBarButtonItem* printBtn = [[UIBarButtonItem alloc] initWithCustomView:self.printBtn];
         
        [items addObject:printBtn];
    }
   
   
   [self.toolbar setItems: items];
   [self.webView addSubview:self.toolbar];
   [self.webView bringSubviewToFront: self.toolbar];

}

-(NSString*)getPath {
    @try {
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* rootPath = paths[0];
        return rootPath;
    } @catch(NSException* exception) {
        @throw exception;
    }
}

-(NSURL*)writeFileTo:(NSData *)data {
    @try {
        NSString* path = [self getPath];
        NSString* nameWithoutExtension = [self.fileName stringByDeletingPathExtension];
        NSString* ext = [self.fileName pathExtension];
        path = [path stringByAppendingPathComponent:nameWithoutExtension];
        path = [path stringByAppendingPathExtension:ext];
        NSURL *url = [NSURL fileURLWithPath:path];
        
        BOOL completion = [data writeToURL:url atomically:YES];
        
        if(completion) {
            return url;
        } else {
            @throw @"Unexcepted error: write file failed";
        }
    } @catch(NSException* exception) {
        NSLog(@"%@", exception.reason);
        @throw exception;
   }
}

-(void)removeFile:(NSURL* )url {
    @try {
        NSError* error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
        if(error != nil) {
            @throw error.localizedDescription;
        }
    } @catch(NSException* exception) {
         @throw exception;
    }
}

-(void)closePDF:(UIButton* )sender {
    NSString* msg = nil;
    
    @try {
        [self.toolbar removeFromSuperview];
        [self.pdfView removeFromSuperview];
    } @catch(NSException* exception) {
        msg = exception.reason;
    }
    
   [self sendPluginResult: msg];
}

-(void)sendPluginResult:(NSString* )msg {
    if(msg != nil) {
        self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:msg];
   } else {
       self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"success"];
   }

   [self.commandDelegate sendPluginResult:self.pluginResult callbackId:self.command.callbackId];
}


-(void)share:(UIButton* )sender {
    NSData* data = [self getBase64Data];
    NSString* shareText = [self.command.arguments objectAtIndex:18];
    [self shareFn:sender base64:data shareText:shareText callback:nil];
}

-(void)shareFn:(UIButton* _Nullable)sender base64:(NSData *)data shareText:(NSString* _Nullable)text callback:(nullable void(^)(BOOL))handler {
    @try {
        NSURL* fileURL = [self writeFileTo: data];
        
        NSMutableArray *activityItems = [[NSMutableArray alloc] init];
        
        if([text length] != 0) {
            [activityItems addObject:text];
        }
        
        [activityItems addObject:fileURL];
        
        UIActivityViewController* activityViewControntroller = [[UIActivityViewController alloc] initWithActivityItems:activityItems  applicationActivities:nil];
        activityViewControntroller.excludedActivityTypes = @[
              UIActivityTypeAssignToContact,
              UIActivityTypePrint,
              UIActivityTypeAddToReadingList,
              UIActivityTypeSaveToCameraRoll,
              UIActivityTypeOpenInIBooks,
              @"com.apple.mobilenotes.SharingExtension",
              @"com.apple.reminders.RemindersEditorExtension"
        ];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            if(sender != nil) {
                activityViewControntroller.popoverPresentationController.sourceView = sender;
                activityViewControntroller.popoverPresentationController.sourceRect = sender.bounds;
            } else {
                activityViewControntroller.popoverPresentationController.sourceView = self.webView;
                activityViewControntroller.popoverPresentationController.sourceRect = CGRectMake(self.webView.bounds.size.width/2, self.webView.bounds.size.height/4, 0, 0);
            }
           
        }
        
        [activityViewControntroller setCompletionWithItemsHandler:^(UIActivityType activityType, BOOL completed, NSArray *returnedItems, NSError *error) {
            if(activityType == nil && handler != NULL) {
                 [self removeFile:fileURL];
                handler(completed);
            }
        }];
        
        [self.viewController presentViewController:activityViewControntroller animated:YES completion:nil];
    } @catch(NSException* exception) {
        @throw exception;
    }
}

-(void)print:(UIButton* )sender {
    NSData* data = [self getBase64Data];
    [self printFn:data callback:nil];
}

-(void)printFn:(NSData *)data callback:(nullable void(^)(BOOL))handler {
    @try {
        NSURL* fileURL = [self writeFileTo: data];
        
        UIPrintInteractionController* printController = [UIPrintInteractionController sharedPrintController];
        BOOL canPrint = [UIPrintInteractionController canPrintURL:fileURL];
        if(canPrint) {
            printController.printingItem = fileURL;
            printController.showsPaperSelectionForLoadedPapers = YES;
            printController.showsNumberOfCopies = NO;

            UIPrintInfo* printInfo = [UIPrintInfo printInfo];
            printInfo.outputType = UIPrintInfoOutputGeneral;
            printController.printInfo = printInfo;

            UIPrintInteractionCompletionHandler completionHandler = ^(UIPrintInteractionController * printConroller, BOOL completed, NSError *error) {
                [self removeFile:fileURL];
                if(handler != NULL) {
                    handler(completed);
                }
            };

            [printController presentAnimated:YES completionHandler: completionHandler];
        } else {
            @throw @"Unexcepted error: cannot print this file";
        }
    } @catch(NSException* exception) {
        @throw exception;
    }
}

@end
