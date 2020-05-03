# PDFViewer
cordova pdf viewer plugin

## Supported Platforms ##

* iOS 11+
* Cordova/Phonegap >=7.1.0

## Installation ##
```bash
cordova plugin add cordova-plugin-pdf-viewer-ios
```

## Removal ##

```bash
cordova plugin rm cordova-plugin-pdf-viewer-ios
```

## Using the plugin ##

The plugin creates the global object ```PDFViewer``` in the window scope.

### Open a Document file ###

```js
const options = {
  fileName: "dummy.pdf"
};
PDFViewer.viewPDF(base64, options);
```

### Options

```js
const options = {
  page: 1,
  mode: 0,
  direction: "vertical"
};
```

##### page

- Its take ```0, 1, 2``` this specify the index of the document page need to be visible

##### mode

- Its take ```0, 1, 2``` this specify the display mode of the document.

- kPDFDisplaySinglePage = 0, 
- kPDFDisplaySinglePageContinuous = 1, 
- kPDFDisplayTwoUp = 2, 
- kPDFDisplayTwoUpContinuous = 3

##### direction

- Its take ```vertical or horizontal``` this specify the display direction of the document.
