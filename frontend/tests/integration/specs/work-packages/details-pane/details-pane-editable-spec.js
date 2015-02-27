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
    detailsPaneHelper = require('./work-package-details-pane-helper.js');

/*jshint expr: true*/
describe('OpenProject', function(){
  describe('editable', function() {
    function behaveLikeEmbeddedDropdown(name, correctValue) {
      context('behaviour', function() {
        var editor = $('[ined-attribute=\'' + name + '\'] .inplace-editor');

        beforeEach(function() {
          detailsPaneHelper.loadPane(819, 'overview');
        });

        describe('read state', function() {
          it('should render a span with value', function() {
            expect(
              editor
                .$('.read-value-wrapper')
                .getText()
            ).to.eventually.equal(correctValue);
          });
        });

        describe('edit state', function() {
          beforeEach(function() {
            editor.$('.ined-read-value').click();
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
                  .$('.select2-choice .select2-chosen span')
                  .getText()
              ).to.eventually.equal(correctValue);
            });
          });
        });
      });
    }

    describe('subject', function() {
      var subjectEditor = $('.wp-subject .inplace-editor');

      context('work package with updateImmediately link', function() {
        beforeEach(function() {
          detailsPaneHelper.loadPane(819, 'overview');
        });

        it('should render an editable subject', function() {
          expect(subjectEditor.$('.editable').isPresent()).to.eventually.be.true;
        });
      });

      context('work package without updateImmediately link', function() {
        beforeEach(function() {
          detailsPaneHelper.loadPane(820, 'overview');
        });

        it('should not render an editable subject', function() {
          expect(subjectEditor.$('.editable').isPresent()).to.eventually.be.false;
        });
      });

      context('work package with a wrong version', function() {
        beforeEach(function() {
          detailsPaneHelper.loadPane(821, 'overview');
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
      var descriptionEditor = $('.inplace-editor.attribute-description');

      beforeEach(function() {
        detailsPaneHelper.loadPane(819, 'overview');
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

        xit('should not render the textarea if click is on the link', function() {
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
      behaveLikeEmbeddedDropdown('status.name', 'specified');
    });
    describe('priority', function() {
      behaveLikeEmbeddedDropdown('priority.name', 'High');
    });
    describe('version', function() {
      var name = 'version.name';
      var editor = $('[ined-attribute=\'' + name + '\'] .inplace-editor');

      behaveLikeEmbeddedDropdown(name, 'alpha');

      context('when work package version link is present', function() {
        beforeEach(function() {
          detailsPaneHelper.loadPane(819, 'overview');
        });

        it('should render a link to the version', function() {
            expect(
              editor
              .$('span.read-value-wrapper a')
              .getText()
            ).to.eventually.equal('alpha');

            expect(
              editor
              .$('span.read-value-wrapper a')
              .getAttribute('href')
            ).to.eventually.match(/\/versions\/1/);
        });
      });

      context('when work package link is missing', function() {
        beforeEach(function() {
          detailsPaneHelper.loadPane(822, 'overview');
        });

        it('should not render an anchor', function() {
          expect(
            editor
            .$('span.read-value-wrapper a')
            .isPresent()
          ).to.eventually.be.false;
        });
      });
    });
    context('user field', function() {
      var assigneeEditor = $('[ined-attribute=\'assignee\'] .inplace-editor'),
          responsibleEditor = $('[ined-attribute=\'responsible\'] .inplace-editor');

      beforeEach(function() {
        detailsPaneHelper.loadPane(822, 'overview');
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
});