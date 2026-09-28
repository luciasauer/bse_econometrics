// Reveal.js lazy-loads images via data-src, only swapping to src when a
// slide becomes the active one. A hidden panel-tabset pane (e.g. "Output")
// is never "active" via a click during ?print-pdf export, so its images
// stay unloaded and print blank. This forces every image to load eagerly,
// but only in print-pdf mode — normal live presentations are unaffected.
(function () {
  function fixLazyImages() {
    document.querySelectorAll("img[data-src]").forEach(function (img) {
      img.src = img.getAttribute("data-src");
    });
  }
  if (window.location.search.indexOf("print-pdf") !== -1) {
    fixLazyImages();
    window.addEventListener("load", fixLazyImages);
    setTimeout(fixLazyImages, 500);
    setTimeout(fixLazyImages, 2000);
  }
})();
