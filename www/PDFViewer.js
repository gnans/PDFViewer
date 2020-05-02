var exec = require("cordova/exec");

function opts(options) {
  options.page = options.page || null;
  options.fitToPage = options.fitToPage || null;
  options.mode = options.mode || "1";
  options.autoResize = options.autoResize || true;
  options.fileName = options.fileName || "";
  options.direction = options.direction || "vertical";

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
      options.fitToPage,
      options.mode,
      options.autoResize,
      options.direction,
      options.fileName,
    ]);
  });
};
