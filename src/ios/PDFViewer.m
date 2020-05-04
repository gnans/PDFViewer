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
        
        self.fileName = fileName;
        
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
    
        NSData* data = [[NSData alloc] initWithBase64EncodedString:base64Str options: NSDataBase64DecodingIgnoreUnknownCharacters];
        self.pdfDocument = [[PDFDocument alloc] initWithData:data];
        
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
       [self.shareBtn addTarget:self action:@selector(sharePDF:) forControlEvents:UIControlEventTouchUpInside];
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
        [self.printBtn addTarget:self action:@selector(printPDF:) forControlEvents:UIControlEventTouchUpInside];
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

-(NSString*)writeFileTo {
    @try {
        NSString* path = [self getPath];
        NSString* nameWithoutExtension = [self.fileName stringByDeletingPathExtension];
        NSString* ext = [self.fileName pathExtension];
        path = [path stringByAppendingPathComponent:nameWithoutExtension];
        path = [path stringByAppendingPathExtension:ext];
        
        BOOL completion = [self.pdfDocument writeToFile:path];
        
        if(completion) {
            return path;
        } else {
            @throw @"Unexcepted error: write file failed";
        }
    } @catch(NSException* exception) {
        NSLog(@"%@", exception.reason);
        @throw exception;
   }
}

-(void)removeFile:(NSString* )path {
    @try {
        NSError* error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
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

-(void)printPDF:(UIButton* )sender {
    @try {
        NSString* path = [self writeFileTo];
      
        NSData* pdfData = [NSData dataWithContentsOfFile:path];
        UIPrintInteractionController* printController = [UIPrintInteractionController sharedPrintController];
        BOOL canPrint = [UIPrintInteractionController canPrintData:pdfData];
        if(canPrint) {
            printController.printingItem = pdfData;
            printController.showsPaperSelectionForLoadedPapers = YES;
            printController.showsNumberOfCopies = NO;
            
            UIPrintInfo* printInfo = [UIPrintInfo printInfo];
            printInfo.outputType = UIPrintInfoOutputGeneral;
            printController.printInfo = printInfo;
            
            UIPrintInteractionCompletionHandler completionHandler = ^(UIPrintInteractionController * printConroller, BOOL completed, NSError *error) {
                [self removeFile:path];
            };
            
            [printController presentAnimated:YES completionHandler: completionHandler];
        } else {
            @throw @"Unexcepted error: cannot print this file";
        }
    } @catch(NSException* exception) {
        @throw exception;
    }
}

-(void)sharePDF:(UIButton* )sender {
    @try {
        NSString* path = [self writeFileTo];
        
        NSData* pdfData = [NSData dataWithContentsOfFile:path];
        NSArray* activityItems = @[pdfData];
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
            activityViewControntroller.popoverPresentationController.sourceView = sender;
            activityViewControntroller.popoverPresentationController.sourceRect = sender.bounds;
        }
        
        [self.viewController presentViewController:activityViewControntroller animated:YES completion:^{
            [self removeFile:path];
        }];
    } @catch(NSException* exception) {
        @throw exception;
    }
}

-(void)sendPluginResult:(NSString* )msg {
    if(msg != nil) {
        self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:msg];
   } else {
       self.pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"success"];
   }

   [self.commandDelegate sendPluginResult:self.pluginResult callbackId:self.command.callbackId];
}

@end
