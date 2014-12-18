//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

var chai = require('chai');
var chaiAsPromised = require('chai-as-promised');

chai.use(chaiAsPromised);
var expect = chai.expect;


var WorkPackageDetailsPane = require('./pages/work-package-details-pane.js');

/*jshint expr: true*/

describe('OpenProject', function() {
  function loadPane(workPackageId) {
    var page = new WorkPackageDetailsPane(workPackageId, 'overview');
    page.get();
  }

  context('pane itself', function() {
    beforeEach(function() {
      loadPane(819);
    });

    it('should be visible', function() {
      expect($('.work-packages--details').isPresent()).to.eventually.be.true;
    });
  });


  describe('editable', function() {
    describe('subject', function() {
      var subjectEditor = $('h2 .inplace-editor');

      context('work package with updateImmediately link', function() {
        beforeEach(function() {
          loadPane(819);
        });

        it('should render an editable subject', function() {
          expect(subjectEditor.$('.editable').isPresent()).to.eventually.be.true;
        });
      });

      context('work package without updateImmediately link', function() {
        beforeEach(function() {
          loadPane(820);
        });

        it('should not render an editable subject', function() {
          expect(subjectEditor.$('.editable').isPresent()).to.eventually.be.false;
        });
      });

      context('work package with a wrong version', function() {
        beforeEach(function() {
          loadPane(821);
          subjectEditor.$('.ined-read-value').click();
          subjectEditor.$('.ined-edit-save a').click();
        });

        it('should render an error', function() {
          expect(
            subjectEditor
              .$('.ined-errors')
              .isDisplayed()
          ).to.eventually.be.true;
        });
      });
    });

    describe('description', function() {
      var descriptionEditor = $('.detail-panel-description .inplace-editor');

      beforeEach(function() {
        loadPane(819);
      });

      describe('read state', function() {
        it('should render the link to another work package', function() {
          expect(
            descriptionEditor
              .$('.ined-read-value a.work_package')
              .isDisplayed()
          ).to.eventually.be.true;
        });

        it('should render the textarea', function() {
          descriptionEditor.$('.ined-read-value').click();
          expect(descriptionEditor.$('textarea').isDisplayed()).to.eventually.be.true;
        });

        it('should not render the textarea if click is on the link', function() {
          descriptionEditor.$('a.work_package').click();
          expect(descriptionEditor.$('textarea').isPresent()).to.eventually.be.false;
        });
      });
      describe('preview', function() {
        var previewButton = descriptionEditor.$('.btn-preview');

        beforeEach(function() {
          descriptionEditor.$('.ined-read-value').click();
        });

        it('should render the button', function() {
          expect(previewButton.isDisplayed()).to.eventually.be.true;
        });

        it('should render the preview block on click', function() {
          previewButton.click();
          expect(
            descriptionEditor
              .$('.preview-wrapper')
              .isDisplayed()
          ).to.eventually.be.true;
        });
      });
    });
    describe('status', function() {
      var statusEditor = $('[ined-attribute=\'status.name\'] .inplace-editor');

      beforeEach(function() {
        loadPane(819);
      });

      describe('read state', function() {
        it('should render a span with value', function() {
          expect(
            statusEditor
              .$('.read-value-wrapper')
              .getText()
          ).to.eventually.equal('specified');
        });
      });

      describe('edit state', function() {
        beforeEach(function() {
          statusEditor.$('.ined-read-value').click();
        });

        context('dropdown', function() {
          it('should be rendered', function() {
            expect(
              statusEditor
                .$('.select2-container').isDisplayed()
                .isDisplayed()
            ).to.eventually.be.true;
          });

          it('should have the correct value', function() {
            expect(
              statusEditor
                .$('.select2-choice .select2-chosen span')
                .getText()
            ).to.eventually.equal('specified');
          });
        });
      });
    });
    context('user field', function() {
      var assigneeEditor = $('[ined-attribute=\'assignee\'] .inplace-editor'),
          responsibleEditor = $('[ined-attribute=\'responsible\'] .inplace-editor')
          ;

      beforeEach(function() {
        loadPane(822);
      });

      context('read state', function() {
        context('with null assignee', function() {
          beforeEach(function() {
            $('.panel-toggler').click();
          });

          it('should render a span with placeholder', function() {
            expect(
              assigneeEditor
                .$('span.read-value-wrapper span')
                .getText()
            ).to.eventually.equal('-');
          });
        });
        context('with set responsible', function() {
          it('should render a link to user\'s profile', function() {
            expect(
              responsibleEditor
              .$('span.read-value-wrapper a')
              .getText()
            ).to.eventually.equal('OpenProject Admin');
          });
        });
      });

      describe('edit state', function() {
        beforeEach(function() {
          responsibleEditor.$('.ined-read-value').click();
        });

        context('select2', function() {
          it('should be rendered', function() {
            expect(
              responsibleEditor
                .$('.select2-container').isDisplayed()
            ).to.eventually.be.true;
          });

          it('should have the correct value', function() {
            expect(
              responsibleEditor
                .$('.select2-choice .select2-chosen span')
                .getText()
            ).to.eventually.equal('OpenProject Admin');
          });
        });
      });
    });
  });

  describe('activities', function() {
    describe('overview tab', function() {
      before(function() {
        var page = new WorkPackageDetailsPane(819, 'overview');
        page.get();
      });

      it('should render the last 3 activites', function() {
        expect(
          $('ul li:nth-child(1) div.comments-number').getText()
        ).to.eventually.equal('#59');

        expect(
          $('ul li:nth-child(2) div.comments-number').getText()
        ).to.eventually.equal('#58');

        expect(
          $('ul li:nth-child(3) div.comments-number').getText()
        ).to.eventually.equal('#57');
      });

      it('should contain the activities details', function() {
        expect(
          $('ul.work-package-details-activities-messages li:nth-child(1) .message').getText()
        ).to.eventually.equal('Status changed from tested to rejected');
      });
    });
  });
});
