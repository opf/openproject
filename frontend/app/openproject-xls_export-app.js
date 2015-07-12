// load all js locales
var localeFiles = require.context('../../config/locales', false, /js-[\w|-]{2,5}\.yml$/);
localeFiles.keys().forEach(function(localeFile) {
  var locale = localeFile.match(/js-([\w|-]{2,5})\.yml/)[1];
  I18n.addTranslations(locale, localeFiles(localeFile)[locale]);
});
