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
        NSString* signPDF = [command.arguments objectAtIndex:19];
        
        self.base64Str = base64Str;
        self.fileName = fileName;
        BOOL isCopyDisabled = [disableCopy boolValue];
        BOOL isSignPDFEnabled = [signPDF boolValue];
        
        self.pdfDocument = [[PDFDocument alloc] initWithData:[self getBase64Data]];
        
        self.pdfWebview = [[WKWebView alloc] initWithFrame: self.webView.bounds];
        
        [self setToolbar];
       
        self.pdfView = [[PDFView alloc] initWithFrame:CGRectMake(0, 50, self.pdfWebview.bounds.size.width, self.pdfWebview.bounds.size.height - 50)];
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
            @throw [NSException exceptionWithName:@"ExceptionalCircumstances" reason:@"pages not found in pdf document" userInfo:nil];
        }
        
        [self.pdfWebview addSubview:self.pdfView];
        [self.pdfWebview bringSubviewToFront: self.pdfView];
        
        [self.webView addSubview:self.pdfWebview];
        [self.webView bringSubviewToFront: self.pdfWebview];
        
       [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(viewWillTransitionToSizeNotification:)
        name:CDVViewWillTransitionToSizeNotification
        object:nil];

        if(isSignPDFEnabled) {
             if (@available(iOS 13.0, *)) {
                [self drawSignPlaceHolderBox];
                
                UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(didTapAnnotation:)];
                [self.pdfView addGestureRecognizer:tapGesture];
             } else {
                 @throw @"sign pdf won't support lower than ios 13";
             }
        }
     
    } @catch(NSException* exception) {
        [self sendPluginResult: exception.reason success:nil];
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
            [self sendPluginResult:msg success:nil];
        }];
    } @catch(NSException* exception) {
        [self sendPluginResult: exception.reason success:nil];
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
            [self sendPluginResult:msg success:nil];
        }];
    } @catch(NSException* exception) {
        [self sendPluginResult: exception.reason success:nil];
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
        self.pdfView.autoScales = true;
        [self.pdfWebview layoutSubviews];
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
   UIToolbar* toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.pdfWebview.frame.size.width, 0)];
   toolbar.barTintColor = [self colorWithHexString:toolbarColour alpha:1];
   [toolbar sizeToFit];
   
   /* title */
   UILabel* titleLabel = [[UILabel alloc] initWithFrame: CGRectZero];
   [titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:18]];
   [titleLabel setBackgroundColor:[UIColor clearColor]];
   [titleLabel setTextColor:[self colorWithHexString:titleColour alpha:1]];
   [titleLabel setText:titleText];
   [titleLabel setTextAlignment:NSTextAlignmentCenter];
    titleLabel.frame = CGRectZero;
   [titleLabel sizeToFit];
   
   /* close button */
   UIButton* closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
   [closeBtn addTarget:self action:@selector(closePDF:) forControlEvents:UIControlEventTouchUpInside];
   [closeBtn setTitle:doneBtnText forState:UIControlStateNormal];
   [closeBtn setTitleColor:[self colorWithHexString:doneBtnColour alpha:1] forState:UIControlStateNormal];
   closeBtn.frame = CGRectZero;
   [closeBtn sizeToFit];
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    UIBarButtonItem* flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* fixedItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedItem.width = 30.0f;
    
    UIBarButtonItem* title = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
    UIBarButtonItem* close = [[UIBarButtonItem alloc] initWithCustomView:closeBtn];
    
    [items addObject:close];
    [items addObject:flexibleItem];
    [items addObject:title];
    [items addObject:flexibleItem];
   
    if(isShareBtnEnabled) {
       /* share button */
       UIButton* shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
       [shareBtn addTarget:self action:@selector(share:) forControlEvents:UIControlEventTouchUpInside];
       [shareBtn setTitle:shareBtnText forState:UIControlStateNormal];
       [shareBtn setTitleColor:[self colorWithHexString:shareBtnColour alpha:1]forState:UIControlStateNormal];
       shareBtn.frame = CGRectZero;
       [shareBtn sizeToFit];
        
        UIBarButtonItem* share = [[UIBarButtonItem alloc] initWithCustomView:shareBtn];
        [items addObject:share];
        
        if(isPrintBtnEnabled) {
            [items addObject:fixedItem];
        }
    }
    
    if(isPrintBtnEnabled) {
        /* print button */
        UIButton* printBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [printBtn addTarget:self action:@selector(print:) forControlEvents:UIControlEventTouchUpInside];
        [printBtn setTitle:printBtnText forState:UIControlStateNormal];
        [printBtn setTitleColor:[self colorWithHexString:printBtnColour alpha:1] forState:UIControlStateNormal];
        printBtn.frame = CGRectZero;
        [printBtn sizeToFit];
        
        UIBarButtonItem* print = [[UIBarButtonItem alloc] initWithCustomView:printBtn];
        [items addObject:print];
    }
   
   
   [toolbar setItems: items];
   [self.pdfWebview addSubview:toolbar];
   [self.pdfWebview bringSubviewToFront: toolbar];

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
            @throw [NSException exceptionWithName:@"ExceptionalCircumstances" reason:@"Unexcepted error: write file failed" userInfo:nil];
        }
    } @catch(NSException* exception) {
        @throw exception;
   }
}

-(void)removeFile:(NSURL* )url {
    @try {
        NSError* error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
        if(error != nil) {
            @throw [NSException exceptionWithName:@"ExceptionalCircumstances" reason:error.localizedDescription userInfo:nil];
        }
    } @catch(NSException* exception) {
         @throw exception;
    }
}

-(void)closePDF:(UIButton* )sender {
   [self sendPluginResult: nil success:nil];
}

-(void)sendPluginResult:(NSString* _Nullable)msg success:(NSString* _Nullable)res {
    [self.pdfWebview removeFromSuperview];
    [self.signView removeFromSuperview];
    [self.completeView removeFromSuperview];
    
    self.pdfWebview = nil;
    self.pdfView = nil;
    self.pdfDocument = nil;
    self.signView = nil;
    self.completeView = nil;
    self.canvas = nil;
    res = res ? res : @"success";
    
    if(msg != nil) {
        self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:msg];
    } else {
       self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: res];
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
                activityViewControntroller.popoverPresentationController.sourceRect = CGRectMake(self.pdfWebview.bounds.size.width/2, self.pdfWebview.bounds.size.height/4, 0, 0);
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
            @throw [NSException exceptionWithName:@"ExceptionalCircumstances" reason:@"Unexcepted error: cannot print this file" userInfo:nil];
        }
    } @catch(NSException* exception) {
        @throw exception;
    }
}

-(void)drawSignPlaceHolderBox {
    @try {
        self.signaturePlaceHolders = [self.command.arguments objectAtIndex:20];
        
        if(!self.signaturePlaceHolders) {
            @throw @"signature placeholders not found";
        } else {
            for(NSDictionary* item in self.signaturePlaceHolders) {
                NSString* sid = [item objectForKey:@"sid"];
                NSNumber* index = [item objectForKey:@"page"];
                NSNumber* x = [item objectForKey:@"x"];
                NSNumber* y = [item objectForKey:@"y"];
                NSNumber* dx = [item objectForKey:@"dx"];
                NSNumber* dy = [item objectForKey:@"dy"];
                NSNumber* width = [item objectForKey:@"width"];
                NSNumber* height = [item objectForKey:@"height"];
                NSString* title = [item objectForKey:@"signatureTitle"];
                [item setValue:@"false" forKey:@"signed"];
                
                PDFPage* page = [self.pdfDocument pageAtIndex: [index intValue] - 1];
                
                PDFAnnotation* annotation = [[PDFAnnotation alloc] initWithBounds:CGRectMake([x floatValue], [y floatValue], [width floatValue], [height floatValue]) forType:PDFAnnotationSubtypeFreeText withProperties:nil];
                PDFBorder* border = [[PDFBorder alloc] init];
                border.lineWidth = 2;
                annotation.border = border;
                annotation.widgetFieldType = PDFAnnotationSubtypeFreeText;
                annotation.interiorColor = UIColor.redColor;
                annotation.color = UIColor.clearColor;
                annotation.fieldName = sid;
                annotation.accessibilityActivationPoint = CGPointMake([dx floatValue], [dy floatValue]);
                if (@available(iOS 13.0, *)) {
                    annotation.accessibilityTextualContext = title;
                }
                
                [page addAnnotation:annotation];
            }
        }
    } @catch (NSException* exception) {
        @throw exception;
    }
}

-(void)didTapAnnotation:(UITapGestureRecognizer*)sender {
    CGPoint touchLocation = [sender locationInView: self.pdfView];
    PDFPage* page = [self.pdfView pageForPoint:touchLocation nearest:YES];
    CGPoint locationOnPage = [self.pdfView convertPoint:touchLocation toPage:page];
    PDFAnnotation* currencySelectedAnnotation = [page annotationAtPoint:locationOnPage];
    
    if(currencySelectedAnnotation != nil) {
        if (@available(iOS 13.0, *)) {
            [self drawSignBox:currencySelectedAnnotation.accessibilityTextualContext annotationKey: currencySelectedAnnotation.fieldName];
        }
    }
}

-(void)drawSignBox:(NSString*)titleText annotationKey:(NSString*)fieldName {
    if (@available(iOS 13.0, *)) {
        self.signView = [[WKWebView alloc] initWithFrame: CGRectMake(20, 100, self.pdfWebview.bounds.size.width - 35, self.pdfWebview.bounds.size.height / 1.5)];
     
        [self setSignViewToolbar:titleText annotationKey: fieldName];
        
        self.canvas = [[PKCanvasView alloc] initWithFrame:CGRectMake(0, 55, self.signView.bounds.size.width, self.signView.bounds.size.height - 65)];
        
        PKInkingTool* tool = [[PKInkingTool alloc] initWithInkType:PKInkTypePen color:UIColor.blackColor width:10];
        
        [self.canvas setTool:tool];
        
        [self.signView addSubview:self.canvas];
        [self.signView bringSubviewToFront: self.canvas];

        [self.webView addSubview:self.signView];
        [self.webView bringSubviewToFront: self.signView];

    } else {
        // Fallback on earlier versions
        @throw @"sign pdf option is supported from ios 13 and above";
    }
}

-(void)setSignViewToolbar:(NSString*)titleText annotationKey:(NSString*)fieldName {
    
    /* toolbar */
   UIToolbar* headerBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.signView.frame.size.width, 0)];
   headerBar.barTintColor = [self colorWithHexString:@"#ffffff" alpha:1];
   [headerBar sizeToFit];
    
    UIToolbar* footerBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.signView.frame.size.height, self.signView.frame.size.width, 0)];
    footerBar.barTintColor = [self colorWithHexString:@"#ffffff" alpha:1];
    [footerBar sizeToFit];
   
   /* title */
   UILabel* titleLabel = [[UILabel alloc] initWithFrame: CGRectZero];
   [titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:18]];
   [titleLabel setBackgroundColor:[UIColor clearColor]];
   [titleLabel setTextColor:[self colorWithHexString:@"#000000" alpha:1]];
   [titleLabel setText:titleText];
   [titleLabel setTextAlignment:NSTextAlignmentCenter];
   [titleLabel sizeToFit];
   
   /* cancel button */
   UIButton* cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
   [cancelBtn addTarget:self action:@selector(cancelSignView:) forControlEvents:UIControlEventTouchUpInside];
   [cancelBtn setTitle:@"Cancel" forState:UIControlStateNormal];
   [cancelBtn setTitleColor:[self colorWithHexString:@"#ff0000" alpha:1] forState:UIControlStateNormal];
   [cancelBtn sizeToFit];
    
    /* clear button */
    UIButton* clearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [clearBtn addTarget:self action:@selector(clearSignView:) forControlEvents:UIControlEventTouchUpInside];
    [clearBtn setTitle:@"Clear" forState:UIControlStateNormal];
    [clearBtn setTitleColor:[self colorWithHexString:@"#ff0000" alpha:1] forState:UIControlStateNormal];
    [clearBtn sizeToFit];
    
    /* proceed button */
    UIButton* proceedBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [proceedBtn addTarget:self action:@selector(proceedSignView:) forControlEvents:UIControlEventTouchUpInside];
    [proceedBtn.layer setValue:fieldName forKey:@"signatureKey"];
    [proceedBtn setTitle:@"Proceed" forState:UIControlStateNormal];
    [proceedBtn setTitleColor:[self colorWithHexString:@"#ff0000" alpha:1] forState:UIControlStateNormal];
    [proceedBtn sizeToFit];
    
    /* line */
    UIView* headerLine = [[UIView alloc] initWithFrame:CGRectMake(0, 50, self.signView.bounds.size.width, 1)];
    headerLine.backgroundColor = [self colorWithHexString:@"#d3d3d3" alpha:1];
   
    UILabel *footerLabel = [[UILabel alloc] initWithFrame: CGRectZero];
    [footerLabel setFont:[UIFont fontWithName:@"Helvetica" size:18]];
    [footerLabel setBackgroundColor:[UIColor clearColor]];
    [footerLabel setTextColor:[self colorWithHexString:@"#000000" alpha:1]];
    [footerLabel setText:@"Please sign"];
    [footerLabel setTextAlignment:NSTextAlignmentCenter];
    [footerLabel sizeToFit];
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    UIBarButtonItem* flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* fixedItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedItem.width = 30.0f;
    
    UIBarButtonItem* title = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
    UIBarButtonItem* cancel = [[UIBarButtonItem alloc] initWithCustomView:cancelBtn];
    UIBarButtonItem* clear = [[UIBarButtonItem alloc] initWithCustomView:clearBtn];
    UIBarButtonItem* proceed = [[UIBarButtonItem alloc] initWithCustomView:proceedBtn];
    UIBarButtonItem* footer = [[UIBarButtonItem alloc] initWithCustomView:footerLabel];
    
    [items addObject:cancel];
    [items addObject:fixedItem];
    [items addObject:clear];
    [items addObject:flexibleItem];
    [items addObject:title];
    [items addObject:flexibleItem];
    [items addObject:proceed];
   
   [headerBar setItems: items];
   [self.signView addSubview:headerBar];
   [self.signView bringSubviewToFront: headerBar];
    
    [items removeAllObjects];
    [items addObject:footer];
    [items addObject:flexibleItem];
    
    [footerBar setItems: items];
    [self.signView addSubview:footerBar];
    [self.signView bringSubviewToFront: footerBar];
    
    [self.signView addSubview:headerLine];
    [self.signView bringSubviewToFront: headerLine];

    [self.signView addSubview:footerLabel];
    [self.signView bringSubviewToFront: footerLabel];

}

-(void)cancelSignView:(UIButton* )sender {
    [self.signView removeFromSuperview];
}

-(void)createCompleteView {
    
    self.completeView = [[WKWebView alloc] initWithFrame: CGRectMake(0, self.pdfWebview.bounds.size.height - 50, self.pdfWebview.bounds.size.width, 50)];
    
    UIToolbar* footerBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.completeView.frame.size.width, 0)];
    footerBar.barTintColor = [self colorWithHexString:@"#dcdcdc" alpha:1];
    [footerBar sizeToFit];
    
    UIButton* completeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [completeBtn addTarget:self action:@selector(completeSign:) forControlEvents:UIControlEventTouchUpInside];
    [completeBtn setBackgroundColor:[self colorWithHexString:@"#000000" alpha:1]];
    [completeBtn setTitle:@"Complete Form" forState:UIControlStateNormal];
    [completeBtn setHighlighted: YES];
    [completeBtn setTitleColor:[self colorWithHexString:@"#ffffff" alpha:1] forState:UIControlStateNormal];
    completeBtn.contentEdgeInsets = UIEdgeInsetsMake(5, 10, 5, 10);
    [completeBtn sizeToFit];
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    UIBarButtonItem* flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* complete = [[UIBarButtonItem alloc] initWithCustomView:completeBtn];
    
    [items addObject:flexibleItem];
    [items addObject:complete];
    [items addObject:flexibleItem];
    
    [footerBar setItems: items];
    [self.completeView addSubview:footerBar];
    [self.completeView bringSubviewToFront: footerBar];
    
    [self.webView addSubview:self.completeView];
    [self.webView bringSubviewToFront: self.completeView];
}

-(void)completeSign:(UIButton* )sender {
    NSString* msg = nil;
    NSString* res = nil;
    
    @try {
        int pageCount = (int)[self.pdfDocument pageCount];
        for(int i=0; i< pageCount; i++) {
            PDFPage* page = [self.pdfDocument pageAtIndex:i];
           if(page.annotations != nil) {
               NSArray* annotations = page.annotations.copy;
               for(PDFAnnotation* annotation in annotations) {
                   [page removeAnnotation:annotation];
               }
           }
        }
        res = [self.pdfDocument.dataRepresentation base64EncodedStringWithOptions:0];
    } @catch (NSException *exception) {
        msg = exception.reason;
    }
    
    [self sendPluginResult:msg success:res];
    
}

-(void)clearSignView:(UIButton* )sender {
    if (@available(iOS 13.0, *)) {
        PKDrawing* drawing = [[PKDrawing alloc] init];
        [self.canvas setDrawing:drawing];
    }
}

-(void)proceedSignView:(UIButton* )sender {
    if (@available(iOS 13.0, *)) {
        PKDrawing* drawing = self.canvas.drawing;
        PDFPage* page = [self.pdfView currentPage];
        NSUInteger pageIndex = [self.pdfDocument indexForPage:page];
        NSString* signatureFieldName = (NSString *)[sender.layer valueForKey:@"signatureKey"];
        PDFAnnotation* matchedAnnotation = nil;
        NSArray* annotations = page.annotations.copy;
        
        for(PDFAnnotation* annotation in annotations) {
            if([annotation.fieldName isEqualToString:signatureFieldName]) {
                matchedAnnotation = annotation;
            }
            
            [page removeAnnotation:annotation];
        }
      
        if(matchedAnnotation != nil) {
            CGRect bounds = [page boundsForBox:kPDFDisplayBoxCropBox];
            UIGraphicsImageRenderer* renderer = [[UIGraphicsImageRenderer alloc] initWithBounds:bounds format:UIGraphicsImageRendererFormat.defaultFormat];
            UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
                CGContextRef contextRef = context.CGContext;
                CGContextSaveGState(contextRef);
                CGContextTranslateCTM(contextRef, 0, bounds.size.height);
                CGContextConcatCTM(contextRef, CGAffineTransformMakeScale(1, -1));
                [page drawWithBox:kPDFDisplayBoxMediaBox toContext:contextRef];
                CGContextRestoreGState(contextRef);
                UIImage* signImage = [drawing imageFromRect:self.canvas.bounds scale:1.0];
                CGRect rect = CGRectMake(matchedAnnotation.accessibilityActivationPoint.x, matchedAnnotation.accessibilityActivationPoint.y, matchedAnnotation.bounds.size.width, matchedAnnotation.bounds.size.height);
                [signImage drawInRect:rect];
                
                NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"dd MMM yyyy h:mm a"];
                NSString* dateString = [dateFormatter stringFromDate:[NSDate date]];
                NSDictionary* attributes = @{NSFontAttributeName: [UIFont fontWithName:@"Helvetica" size:5]};
                CGSize stringSize = [dateString sizeWithAttributes:attributes];
                [dateString drawInRect:CGRectMake(rect.origin.x + 15, rect.origin.y + 35, stringSize.width, stringSize.height) withAttributes:attributes];
            }];
            
            PDFPage* newPage = [[PDFPage alloc] initWithImage:image];
            for(PDFAnnotation* annotation in annotations) {
                [newPage addAnnotation:annotation];
            }
            
            if([self.pdfDocument pageCount] == pageIndex + 1) {
                [self.pdfDocument removePageAtIndex:pageIndex];
                [self.pdfDocument insertPage:newPage atIndex:pageIndex];
            } else {
                [self.pdfDocument insertPage:newPage atIndex:pageIndex];
                [self.pdfDocument removePageAtIndex:pageIndex + 1];
            }
            self.pdfView.document = self.pdfDocument;
          
            [self cancelSignView: sender];

            BOOL signedStatus = YES;
            for(NSDictionary* item in self.signaturePlaceHolders) {
                if([[item objectForKey:@"sid"] isEqualToString:matchedAnnotation.fieldName]) {
                    [item setValue:@"true" forKey:@"signed"];
                }
                
                if([[item objectForKey:@"optional"] isEqualToString:@"false"]) {
                    if([[item objectForKey:@"signed"] isEqualToString:@"false"]) {
                        signedStatus = NO;
                        break;
                    }
                }
            }
            
            if(signedStatus) {
                [self createCompleteView];
            }
        }
    }
}

@end
