# PDFViewer

This plugin allows you to view pdf file base64 using ios native library PDFKit and it has print, digital signature and share functionality also.

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
  direction: "vertical",
  fileName: "dummy.pdf",
  toolbarColour: "#ababab",
  doneBtnColour: "#ababab",
  doneBtnText: "done",
  titleColour: "#000000",
  titleText: "dummy",
  shareBtnColour: "#000000",
  shareBtnText: "share",
  printBtnColour: "#000000",
  printBtnText: "print",
  showShareBtn: "true",
  showPrintBtn: "true",
  pdfBackgroundColour: "#ababab",
  disableCopy: "true",
  shareText: "Hello, World",
  signPDF: "false",
  signaturePlaceHolders: []
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

##### fileName

- Its take name of the file with extension like this ```dummy.pdf```

##### toolbarColour

- Its take toolbar colour code in hexadecimal format

##### doneBtnColour

- Its take done button colour code in hexadecimal format

##### doneBtnText

- Its take done button text which is visible to user instead of button

##### titleColour

- Its take title text colour code in hexadecimal format

##### titleText

- Its take title text which is visible in toolbar center

##### shareBtnColour

- Its take share button colour code in hexadecimal format

##### shareBtnText

- Its take share button text which is visible to user instead of button

##### printBtnColour

- Its take print button colour code in hexadecimal format

##### printBtnText

- Its take print button text which is visible to user instead of button

##### pdfBackgroundColour

- Its take background colour code in hexadecimal format

##### disableCopy

- Its take values as ```"true" or "false"``` to disable or enable copy text from pdf

#### shareText

- Its take values to share with pdf file like title or description

##### showShareBtn

- Its take values as ```"true" or "false"``` to show or hide share button 

##### showPrintBtn

- Its take values as ```"true" or "false"``` to show or hide print button 

##### signPDF

- Its take values as ```"true" or "false"``` to enable or disable digital signature in pdf

#### signaturePlaceHolders

- Its take values as 

```js
[{
  sid: "Signature1",
  page: 4, //page no
  x: 420.0, // coordinate for placeholder box
  y: 600.0, // coordinate for placeholder box
  width: 100, // width for placeholder box and signature
  height: 30, // height for placeholder box and signature
  dx: 420.0, // coordinate for signature
  dy: 150.0, // coordinate for signature
  optional: "false",
  signatureTitle: "Signature of Application"
}]
```
