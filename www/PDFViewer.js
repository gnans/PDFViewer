var exec = require("cordova/exec");

function opts(options) {
  options.page = options.page || null;
  options.mode = options.mode || "1";
  options.direction = options.direction || "vertical";
  options.fileName = options.fileName || "";
  options.toolbarColour = options.toolbarColour || "#ababab";
  options.doneBtnColour = options.doneBtnColour || "#000000";
  options.doneBtnText = options.doneBtnText || "done";
  options.titleColour = options.titleColour || "#000000";
  options.titleText = options.titleText || options.fileName || "";
  options.shareBtnColour = options.shareBtnColour || "#000000";
  options.shareBtnText = options.shareBtnText || "share";
  options.printBtnColour = options.printBtnColour || "#000000";
  options.printBtnText = options.printBtnText || "print";
  options.showShareBtn = options.showShareBtn || true;
  options.showPrintBtn = options.showPrintBtn || true;
  options.pdfBackgroundColour = options.pdfBackgroundColour || "#ababab";

  return options;
}

function validate(param, message) {
  if (
    param === "" ||
    param === undefined ||
    param === null ||
    typeof param !== "string"
  )
    throw message;
}

exports.viewPDF = function (data, options) {
  return new Promise((resolve, reject) => {
    validate(data, "base64 string required");
    options = opts(options);

    cordova.exec(resolve, reject, "PDFViewer", "viewPDF", [
      data,
      options.page,
      options.mode,
      options.direction,
      options.fileName,
      options.toolbarColour,
      options.doneBtnColour,
      options.doneBtnText,
      options.titleColour,
      options.titleText,
      options.shareBtnColour,
      options.shareBtnText,
      options.printBtnColour,
      options.printBtnText,
      options.showShareBtn,
      options.showPrintBtn,
      options.pdfBackgroundColour
    ]);
  });
};
