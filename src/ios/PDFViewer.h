#import <Cordova/CDV.h>
#import <PDFKit/PDFKit.h>
#import <WebKit/WebKit.h>

API_AVAILABLE(ios(11.0))
@interface PDFViewer : CDVPlugin

@property(nonatomic, strong) CDVInvokedUrlCommand* command;
@property(nonatomic, strong) CDVPluginResult* pluginResult;
@property(nonatomic, strong) PDFView* pdfView;
@property(nonatomic, strong) PDFDocument* pdfDocument;
@property(nonatomic, strong) NSString* fileName;
@property(nonatomic, strong) NSString* base64Str;
@property(nonatomic, strong) UIToolbar* toolbar;
@property(nonatomic, strong) UILabel* titleLabel;
@property(nonatomic, strong) UIButton* closeBtn;
@property(nonatomic, strong) UIButton* shareBtn;
@property(nonatomic, strong) UIButton* printBtn; 

- (void)viewPDF:(CDVInvokedUrlCommand*)command;
- (void)sharePDF:(CDVInvokedUrlCommand*)command;
- (void)printPDF:(CDVInvokedUrlCommand*)command;
@end



