//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

var expect = require('../../../spec_helper.js').expect,
    detailsPaneHelper = require('./details-pane-helper.js');

/*jshint expr: true*/
describe('OpenProject', function(){
  describe('editable', function() {
    describe('subject', function() {

      var subjectEditor = function(paneNumber) {
        return detailsPaneHelper.loadPane(paneNumber, 'overview').then(function() {
          return element(by.css('.inplace-edit.attribute-subject'));
        });
      };

      context('work package with update link', function() {
        it('should render an editable subject', function() {
          subjectEditor(819).then(function(editor) {
            expect(editor.$('.inplace-editing--trigger-link').isPresent())
              .to.eventually.be.true;
          });
        });
      });

      context('work package without update link', function() {
        it('should not render an editable subject', function() {
          subjectEditor(820).then(function(editor) {
            expect(editor.$('.inplace-editing--trigger-link').isPresent())
              .to.eventually.be.false;
          });
        });
      });

      context('work package with a wrong version', function() {
        it('should render an error', function() {
          subjectEditor(821).then(function(editor) {
            editor.$('.inplace-editing--trigger-link').click();
            editor.$('.inplace-edit--control--save a').click();

            return editor;
          }).then(function(editor) {
            expect(editor.$('.inplace-edit--errors').isDisplayed())
              .to.eventually.be.true;
          });
        });
      });
    });

    describe('description', function() {
      var descriptionEditor = $('.inplace-edit.attribute-description');

      beforeEach(function() {
        detailsPaneHelper.loadPane(819, 'overview');
      });

      describe('read state', function() {
        it('should render the link to another work package in the text', function() {
          expect(
            descriptionEditor
              .$('.inplace-edit--read a.work_package')
              .isDisplayed()
          ).to.eventually.be.true;
        });

        it('should render the textarea after clicking on the trigger link', function() {
          descriptionEditor.$('.inplace-editing--trigger-link').click();
          expect(descriptionEditor.$('textarea').isDisplayed()).to.eventually.be.true;
        });

        xit('should not render the textarea if click is on the link', function() {
          // This needs to be disabled as clicking on the link would currently load
          // a new page that is not part of what we control with our mocks.
          //
          // It can be reenabled once clicking on the link would actually show the
          // clicked on work package in the already open details pane or something
          // similar.
          descriptionEditor.$('.inplace-edit--read a.work_package').click();
          expect(descriptionEditor.$('textarea').isPresent()).to.eventually.be.false;
        });
      });

      describe('preview', function() {
        var previewButton = descriptionEditor.$('.jstb_preview');

        beforeEach(function() {
          descriptionEditor.$('.inplace-editing--trigger-link').click();
        });

        it('should render the button', function() {
          expect(previewButton.isDisplayed()).to.eventually.be.true;
        });

        it('should render the preview block on click', function() {
          previewButton.click();
          expect(
            descriptionEditor
              .$('.inplace-edit--preview')
              .isDisplayed()
          ).to.eventually.be.true;
        });
      });
    });
    describe('status', function() {
      detailsPaneHelper.behaveLikeEmbeddedDropdown('status', 'new');
    });
    describe('priority', function() {
      detailsPaneHelper.behaveLikeEmbeddedDropdown('priority', 'Normal');
    });
    describe('version', function() {
      var editor = $('.inplace-edit.attribute-version');

      detailsPaneHelper.behaveLikeEmbeddedDropdown('version', 'v1');

      context('when work package version link is present', function() {
        beforeEach(function() {
          detailsPaneHelper.loadPane(819, 'overview');
        });

        it('should render a link to the version', function() {
            expect(
              editor
              .$('span.inplace-edit--read-value a')
              .getText()
            ).to.eventually.equal('v1');

            expect(
              editor
              .$('span.inplace-edit--read-value a')
              .getAttribute('href')
            ).to.eventually.match(/\/versions\/1/);
        });
      });

      context('when work package version link is missing', function() {
        before(function() {
          detailsPaneHelper.loadPane(820, 'overview');
        });

        it('should render a span', function() {
          expect(
            editor
            .$('span.inplace-edit--read-value .version-wrapper span')
            .getText()
          ).to.eventually.equal('v2');
        });

        it('should not render an anchor', function() {
          expect(
            editor
            .$('span.inplace-edit--read-value a')
            .isPresent()
          ).to.eventually.be.false;
        });
      });
    });
    context('user field', function() {
      var assigneeEditor = $('.inplace-edit.attribute-assignee'),
          responsibleEditor = $('.inplace-edit.attribute-responsible');

      beforeEach(function() {
        detailsPaneHelper.loadPane(819, 'overview');
      });

      context('read state', function() {
        context('with null assignee', function() {
          beforeEach(function() {
            detailsPaneHelper.showAll();
          });

          it('should render a span with placeholder', function() {
            expect(
              assigneeEditor
                .$('span.inplace-edit--read-value span')
                .getText()
            ).to.eventually.equal('-');
          });
        });
        context('with set responsible', function() {
          it('should render a link to user\'s profile', function() {
            expect(
              responsibleEditor
              .$('span.inplace-edit--read-value a')
              .getText()
            ).to.eventually.equal('OpenProject Admin');
          });
        });
      });

      describe('edit state', function() {
        beforeEach(function() {
          responsibleEditor.$('.inplace-editing--trigger-link').click();
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
});
