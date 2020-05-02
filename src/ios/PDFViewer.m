/********* PDFViewer.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import <PDFKit/PDFKit.h>
#import <WebKit/WebKit.h>

@interface PDFViewer : CDVPlugin <PDFViewDelegate>
@property(nonatomic, strong) CDVInvokedUrlCommand* command;
@property(nonatomic, strong) CDVPluginResult* pluginResult;
@property(nonatomic, strong) PDFView* pdfView;
@property(nonatomic, strong) UIToolbar* toolbar;
@property(nonatomic, strong) UILabel* label;
@property(nonatomic, strong) UIButton* button;
- (void)viewPDF:(CDVInvokedUrlCommand*)command;
@end

@implementation PDFViewer

- (void)viewPDF:(CDVInvokedUrlCommand*)command
{
    self.command = command;
    NSString* msg = nil;
    
    if (@available(iOS 11.0, *)) {
        @try {
            NSString* base64Str = [command.arguments objectAtIndex:0];
            NSString* pageNoStr = [command.arguments objectAtIndex:1];
            NSString* fitToPage = [command.arguments objectAtIndex:2];
            NSString* mode = [command.arguments objectAtIndex:3];
            NSString* autoResize = [command.arguments objectAtIndex:4];
            NSString* direction = [command.arguments objectAtIndex:5];
            NSString* fileName = [command.arguments objectAtIndex:6];
            
            self.pdfView = [[PDFView alloc] initWithFrame:CGRectMake(0, 55, self.webView.bounds.size.width, self.webView.bounds.size.height)];
            self.pdfView.displayMode = [mode integerValue];
            self.pdfView.displayDirection = [direction  isEqual: @"vertical"] ? kPDFDisplayDirectionVertical : kPDFDisplayDirectionHorizontal;
            self.pdfView.minScaleFactor = self.pdfView.scaleFactor;
            self.pdfView.maxScaleFactor = self.pdfView.scaleFactorForSizeToFit;
            self.pdfView.backgroundColor = [UIColor colorWithRed:243/255.0 green:241/255.0 blue:238/255.0 alpha:1.0];
            
            if(![fitToPage isEqual:[NSNull null]]) {
                [self.pdfView sizeToFit];
            }
            
            if(autoResize) {
                self.pdfView.autoScales = true;
            }
            
            self.pdfView.delegate = self;
          
            NSData* data = [[NSData alloc] initWithBase64EncodedString:base64Str options: NSDataBase64DecodingIgnoreUnknownCharacters];
            PDFDocument* pdfDocument = [[PDFDocument alloc] initWithData:data];
            
            self.pdfView.document = pdfDocument;
            
            if(![pageNoStr isEqual:[NSNull null]]) {
                PDFPage* page = [pdfDocument pageAtIndex: [pageNoStr integerValue]];
                [self.pdfView goToPage: page];
            }
            
            if(!self.pdfView.document.pageCount) {
                msg = @"pages not found in pdf document";
                return;
            }
            
            [self.webView addSubview:self.pdfView];
            [self.webView bringSubviewToFront: self.pdfView];
        
            self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0,        self.webView.bounds.size.width, 50)];
            self.toolbar.barTintColor =[UIColor colorWithRed:243/255.0 green:241/255.0 blue:238/255.0 alpha:1.0];
            [self.toolbar sizeToFit];
            [self.webView addSubview:self.toolbar];
            [self.webView bringSubviewToFront: self.toolbar];
            
              
            // toolbar title
            self.label = [[UILabel alloc] initWithFrame:CGRectMake((self.webView.bounds.size.width/2) - 100, 15, 50, 40)];
            self.label.text = fileName;
            self.label.font = [UIFont boldSystemFontOfSize:20.0];
            [self.label sizeToFit];
            [self.webView addSubview:self.label];
            [self.webView bringSubviewToFront: self.label];
            
            //toobar button
            self.button = [UIButton buttonWithType:UIButtonTypeCustom];
            [self.button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self.button setTitle:@"done" forState:UIControlStateNormal];
            [self.button setTitleColor:[UIColor colorWithRed:0/255.0 green:87/255.0 blue:128/255.0 alpha:1.0] forState:UIControlStateNormal];
            [self.button sizeToFit];
            self.button.frame = CGRectMake(20, 10, 50, 40.0);
            [self.webView addSubview:self.button];
            [self.webView bringSubviewToFront:self.button];
            
        } @catch(NSException* exception) {
            msg = exception.reason;
            [self sendPluginResult: msg];
        }
            
    } else {
        // Fallback on earlier versions
        msg = @"Below ios 11 is not supported";
       [self sendPluginResult: msg];
    }
}

-(void)buttonClicked:(UIButton* )sender {
    NSString* msg = nil;
    
    @try {
        [self.pdfView removeFromSuperview];
        [self.button removeFromSuperview];
        [self.label removeFromSuperview];
        [self.toolbar removeFromSuperview];
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

@end
