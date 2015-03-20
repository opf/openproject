var chai = require('chai');
var chaiAsPromised = require('chai-as-promised');

chai.use(chaiAsPromised);
var expect = chai.expect;


var WorkPackageDetailsPane = require('./pages/work-package-details-pane.js');

describe('OpenProject', function() {
  function loadPane(workPackageId) {
    var page = new WorkPackageDetailsPane(workPackageId, 'relations');
    page.get();
    browser.waitForAngular();
  }

  describe('details pane', function() {
    beforeEach(function() {
      loadPane(819);
    });

    it('opens relations tab', function() {
      $('[ui-sref="work-packages.list.details.relations({})"]')
      .getAttribute('class')
      .then(function(classes) {
        expect(classes.split(' ')).to.contain('selected');
      });
    });

    describe('relations tab', function() {
      var toggleAccordeon = function(titleName) {
        getAccordeon(titleName).click();
      },
      getAccordeon = function(titleName) {
        return $('.relation[title="' + titleName + '"]');
      };

      beforeEach(function(){
        toggleAccordeon('Parent');
      });

      it('focuses on disabled button', function() {
        $('.relation[title="Parent"] button')
        .getAttribute('disabled')
        .then(function(disabled){
          expect(disabled).to.be.equal('true');
        });
      });
    });
  });
});
