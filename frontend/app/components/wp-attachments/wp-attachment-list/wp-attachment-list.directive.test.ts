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

import {wpDirectivesModule, opTemplatesModule} from '../../../angular-modules';
import {WorkPackageAttachmentListController} from './wp-attachment-list.directive';
import IRootScopeService = angular.IRootScopeService;
import ICompileService = angular.ICompileService;
import IScope = angular.IScope;
import IAugmentedJQuery = angular.IAugmentedJQuery;
import IDirective = angular.IDirective;

describe('wpAttachmentList directive', () => {
  var scope: any;
  var element: IAugmentedJQuery;
  var controller: WorkPackageAttachmentListController;
  var workPackage: any;
  var compile:any;

  var template:any;

  beforeEach(angular.mock.module(
    wpDirectivesModule.name,
    opTemplatesModule.name,

    ($compileProvider:any) => {
      // Mock ngClick, because triggerHandler doesn't work on the delete button for some reason.
      $compileProvider.directive('ngClick', (): IDirective => ({
        restrict: 'A',
        priority: 100,
        scope: {
          ngClick: '&',
        },
        controller: angular.noop,
        controllerAs: '$ctrl',
        bindToController: true
      }));
    }
  ));
  beforeEach(angular.mock.inject(function ($rootScope: IRootScopeService,
                                           $compile: ICompileService,
                                           I18n:op.I18n) {
    const html = '<wp-attachment-list work-package="workPackage"></wp-attachment-list>';
    scope = $rootScope.$new();
    workPackage = {};
    scope.workPackage = workPackage;

    const t = sinon.stub(I18n, 't');
    t
      .withArgs('js.text_attachment_destroy_confirmation')
      .returns('confirm destruction');

    t
      .withArgs('js.label_remove_file')
      .returns('something fileName');

    compile = () => {
      element = $compile(html)(scope);
      scope.$apply();
      controller = element.controller('wpAttachmentList');

      const root = element.find('.work-package--attachments--files');
      const wrapper = root.children().first();
      const listItem = root.find('.inplace-edit--read');
      const fileName = listItem.find('.work-package--attachments--filename');
      const triggerLink = listItem.find('.inplace-editing--trigger-link');
      const deleteIcon = listItem.first().find('.inplace-edit--icon-wrapper').first();

      template = {root, wrapper, listItem, fileName, triggerLink, deleteIcon};
    };

    compile();
  }));

  afterEach(angular.mock.inject((I18n:any) => I18n.t.restore()));

  it('should not be empty', () => {
    expect(element.html()).to.be.ok;
  });

  it('should show no files', () => {
    expect(template.wrapper.children()).to.have.length(0);
  });

  describe('when the work package has attachments', () => {
    var attachment:any;
    var attachments:any;

    beforeEach(angular.mock.inject(($q:any) => {
      attachment = {
        name: 'name',
        fileName: 'fileName'
      };
      attachments = [attachment, attachment];

      workPackage.attachments = {
        elements: attachments,
        $load: sinon.stub(),
        updateElements: sinon.stub()
      };
      workPackage.pendingAttachments = attachments;
      workPackage.removeAttachment = sinon.stub();

      workPackage.attachments.$load.returns($q.when(workPackage.attachments));

      compile();
    }));

    it('should be rendered', () => {
      expect(template.root).to.have.length(1);
    });

    it('should update the elements of the attachments', () => {
      expect(workPackage.attachments.updateElements.calledOnce).to.be.true;
    });

    it('should show the existing and pending attachments', () => {
      expect(template.listItem).to.have.length(4);
    });

    it('should have an element that contains the file name', () => {
      expect(template.fileName.text()).to.contain(attachment.fileName);
    });

    it('should have a link that points nowhere', () => {
      expect(template.fileName.attr('href')).to.equal('#');
    });

    it('should have a delete icon with a title that contains the file name', () => {
      const icon = template.deleteIcon.find('[icon-title]');
      expect(icon.attr('icon-title')).to.contain(attachment.fileName);
    });

    it('should have a confirm-popup attribute with the destroyConfirmation text value', () => {
      expect(template.deleteIcon.attr('confirm-popup')).to.equal('confirm destruction');
    });

    describe('when using the delete button', () => {
      beforeEach(() => {
        template.deleteIcon.controller('ngClick').ngClick();
      });

      it('should call the removeAttachment method of the work package', () => {
        expect(workPackage.removeAttachment.called).to.be.true;
      });
    });

    describe('when the attachment has a download location', () => {
      beforeEach(() => {
        attachment.downloadLocation = {href: 'download'};
        compile();
      });

      it('should link to that location', () => {
        expect(template.fileName.attr('href')).to.equal(attachment.downloadLocation.href);
      });
    });

    describe('when the attachment has no file name', () => {
      beforeEach(() => {
        attachment.fileName = '';
        compile();
      });

      it('should contain an element that contains the attachment name', () => {
        expect(template.fileName.text()).to.contain(attachment.name);
      });
    });

    describe('when focusing an element', () => {
      var focusElement:any;

      const testFocus = (prepare:any) => {
        beforeEach(() => {
          prepare();
          focusElement.triggerHandler('focus');
        });

        it('should set the `-focus` class for that attachment', () => {
          expect(template.triggerLink.hasClass('-focus')).to.be.true;
        });

        it('should be focused', () => {
          expect(controller.isFocused(attachment)).to.be.true;
        });

        describe('when setting the focus somewhere else', () => {
          beforeEach(() => {
            focusElement.triggerHandler('blur');
          });

          it('should unset the `-focus` class for that attachment', () => {
            expect(template.triggerLink.hasClass('-focus')).to.be.false;
          });

          it('should not be focused', () => {
            expect(controller.isFocused(attachment)).to.be.false;
          });
        });
      };

      describe('when focusing the file name element', () => {
        testFocus(() => {
          focusElement = template.fileName;
        });
      });

      describe('when focusing the delete icon', () => {
        testFocus(() => {
          focusElement = template.deleteIcon;
        });
      });
    });
  });
});
