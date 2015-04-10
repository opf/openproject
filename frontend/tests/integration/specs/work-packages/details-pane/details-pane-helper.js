var WorkPackageDetailsPane = require('../../../pages/work-package-details-pane.js');

function loadPane(workPackageId, paneName) {
  var page = new WorkPackageDetailsPane(workPackageId, paneName);
  page.get();
  browser.waitForAngular();
}

function showAll() {
  $('.panel-toggler a').click();
}

module.exports = {
  loadPane: loadPane,
  showAll: showAll
};
