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
  context('details pane is visible', function() {
    before(function() {
      var page = new WorkPackageDetailsPane(819, 'overview');
      page.get();
    });

    it('should show work packages details pane', function() {
      expect($('.work-packages--details').isPresent()).to.eventually.be.true;
    });
  });

  describe('editable', function() {
    context('subject', function() {
      context('work package with updateImmediately link', function() {
        before(function() {
          var page = new WorkPackageDetailsPane(819, 'overview');
          page.get();
        });
        it('should render an editable subject', function() {
          expect($('h2 .inplace-editor').isPresent()).to.eventually.be.true;
        });
      });
      context('work package without updateImmediately link', function() {
        before(function() {
          var page = new WorkPackageDetailsPane(820, 'overview');
          page.get();
        });
        it('should show work packages details pane', function() {
          expect($('.work-packages--details').isPresent()).to.eventually.be.true;
        });
        it('should not render an editable subject', function() {
          expect($('h2 .inplace-editor').isPresent()).to.eventually.be.false;
        });
      });
      context('work package with a wrong version', function() {
        before(function() {
          var page = new WorkPackageDetailsPane(821, 'overview');
          page.get();
          $('h2 .inplace-editor .ined-read-value').then(function(e) {
            e.click();
            $('h2 .ined-edit-save a').click();
          });
        });
        it('should render an error', function() {
          expect($('h2 .ined-errors').isDisplayed()).to.eventually.be.true;
        });
      });
    });
    context('description', function() {
      beforeEach(function() {
        var page = new WorkPackageDetailsPane(819, 'overview');
        page.get();
      });
      describe('read state', function() {
        it('should render the link to another work package', function() {
          expect($('.detail-panel-description .inplace-editor .ined-read-value a.work_package').isDisplayed()).to.eventually.be.true;
        });
        it('should render the textarea', function() {
          $('.detail-panel-description .inplace-editor .ined-read-value').then(function(e) {
            e.click();
            expect($('.detail-panel-description .ined-edit textarea').isDisplayed())
              .to.eventually.be.true;
            });
        });
        it('should not render the textarea if click is on the link', function() {
          $('.detail-panel-description .inplace-editor .ined-read-value  a.work_package')
            .then(function(e) {
              e.click();
              expect($('.detail-panel-description .ined-edit textarea').isPresent()).to.eventually.be.false;
            });
        });
      });
      describe('preview', function() {
        beforeEach(function() {
          $('.detail-panel-description .inplace-editor .ined-read-value').then(function(e) {
            e.click();
          });
        });
        it('should render the button', function() {
          expect($('.detail-panel-description .btn-preview').isDisplayed()).to.eventually.be.true;
        });
        it('should render the preview block on click', function() {
          $('.detail-panel-description .btn-preview').then(function(btn) {
            btn.click();
            expect($('.detail-panel-description .preview-wrapper').isDisplayed()).to.eventually.be.true;
          });
        });
      });
    });
    context('status', function() {
      beforeEach(function() {
        var page = new WorkPackageDetailsPane(819, 'overview');
        page.get();
      });
      describe('read state', function() {
        it('should render a span with value', function() {
          expect($('.status-inline-editor .inplace-editor span.read-value-wrapper').getText())
            .to.eventually.equal('specified');
        });
      });
      describe('edit state', function() {
        beforeEach(function() {
          $('.status-inline-editor .inplace-editor .ined-read-value').then(function(e) {
            e.click();
          });
        });
        context('dropdown', function() {
          it('should be rendered', function() {
            expect($('.status-inline-editor select.focus-input').isDisplayed())
              .to.eventually.be.true;
          });
          it('should have the correct value', function() {
            expect(
              $('.status-inline-editor select.focus-input option:checked').getAttribute('value')
            ).to.eventually.equal('1');
          });
        });
      });
    });
    context('user field', function() {
      beforeEach(function() {
        var page = new WorkPackageDetailsPane(822, 'overview');
        page.get();
      });
      context('read state', function() {
        context('with null assignee', function() {
          beforeEach(function() {
            $('.panel-toggler').click();
          });
          /*jshint multistr: true */
          it('should render a span with placeholder', function() {
            expect($('.user-inline-editor[ined-attribute=\'assignee\'] \
              .inplace-editor \
              span.read-value-wrapper span').getText())
              .to.eventually.equal('-');
          });
        });
        /*jshint multistr: true */
        context('with set responsible', function() {
          it('should render a link to user\'s profile', function() {
            expect($('.user-inline-editor[ined-attribute=\'responsible\'] \
              .inplace-editor \
              span.read-value-wrapper a').getText())
              .to.eventually.equal('OpenProject Admin');
          });
        });
      });

      describe('edit state', function() {
        beforeEach(function() {
          /*jshint multistr: true */
          $('.user-inline-editor[ined-attribute=\'responsible\'] \
              .inplace-editor \
              .ined-read-value').then(function(e) {
            e.click();
          });
        });
        context('select2', function() {
          it('should be rendered', function() {
            /*jshint multistr: true */
            expect($('.user-inline-editor[ined-attribute=\'responsible\'] \
              .select2-container').isDisplayed())
              .to.eventually.be.true;
          });
          it('should have the correct value', function() {
            /*jshint multistr: true */
            expect(
              $('.user-inline-editor[ined-attribute=\'responsible\'] \
                .select2-container \
                .select2-choice span').getText()
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
