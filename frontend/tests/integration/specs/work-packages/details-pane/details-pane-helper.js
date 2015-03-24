var WorkPackageDetailsPane = require('../../../pages/work-package-details-pane.js'),
    expect = require('../../../spec_helper.js').expect;

function loadPane(workPackageId, paneName) {
  var page = new WorkPackageDetailsPane(workPackageId, paneName);
  page.get();
  browser.waitForAngular();
}

function behaveLikeEmbeddedDropdown(name, correctValue) {
  context('behaviour', function() {
    var editor = $('[ined-attribute=\'' + name + '\'] .inplace-edit');

    beforeEach(function() {
      loadPane(819, 'overview');
    });

    describe('read state', function() {
      it('should render a span with value', function() {
        expect(
          editor
          .$('.inplace-edit--read-value')
          .getText()
        ).to.eventually.equal(correctValue);
      });
    });

    describe('edit state', function() {
      beforeEach(function() {
        editor.$('.inplace-editing--trigger-link').click();
      });

      context('dropdown', function() {
        it('should be rendered', function() {
          expect(
            editor
            .$('.select2-container').isDisplayed()
            .isDisplayed()
          ).to.eventually.be.true;
        });

        it('should have the correct value', function() {
          expect(
            editor
            .$('.select2-choice > span.select2-chosen > span')
            .getText()
          ).to.eventually.equal(correctValue);
        });
      });
    });
  });
}

module.exports = {
  loadPane: loadPane,
  dropDownTest: behaveLikeEmbeddedDropdown
};
