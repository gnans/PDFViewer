#import <Cordova/CDV.h>
#import <PDFKit/PDFKit.h>
#import <WebKit/WebKit.h>
#import <PencilKit/PencilKit.h>

API_AVAILABLE(ios(11.0))
@interface PDFViewer : CDVPlugin

@property(nonatomic, strong) CDVInvokedUrlCommand* command;
@property(nonatomic, strong) CDVPluginResult* pluginResult;
@property(nonatomic, strong) WKWebView* pdfWebview;
@property(nonatomic, strong) PDFView* pdfView;
@property(nonatomic, strong) PDFDocument* pdfDocument;
@property(nonatomic, strong) NSString* fileName;
@property(nonatomic, strong) NSString* base64Str;
@property(nonatomic, strong) WKWebView* signView;
@property(nonatomic, strong) WKWebView* completeView;
@property(nonatomic, strong) PKCanvasView* canvas;
@property(nonatomic, strong) NSArray* signaturePlaceHolders;

- (void)viewPDF:(CDVInvokedUrlCommand*)command;
- (void)sharePDF:(CDVInvokedUrlCommand*)command;
- (void)printPDF:(CDVInvokedUrlCommand*)command;
@end



