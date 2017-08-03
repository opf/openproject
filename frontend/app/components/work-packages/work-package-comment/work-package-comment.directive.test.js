// -- copyright
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
// ++

/*jshint expr: true*/

describe('workPackageCommentDirectiveTest', function() {
  var I18n, ActivityService, compile, scope, element, stateParams, q, commentCreation;
  var workPackageFieldService = {};
  var html = "<work-package-comment work-package='workPackage' activities='activities'></work-package-comment>";
  stateParams = {};

  beforeEach(angular.mock.module('ui.router',
                    'openproject',
                    'openproject.api',
                    'openproject.models',
                    'openproject.layout',
                    'openproject.services',
                    'openproject.uiComponents',
                    'openproject.inplace-edit',
                    'openproject.workPackages.tabs',
                    'openproject.workPackages.directives',
                    'openproject.workPackages.models'));

  beforeEach(angular.mock.module('openproject.templates', function($provide) {
    var configurationService = {
      commentsSortedInDescendingOrder: function() { return []; }
    };

    $provide.constant('$stateParams', stateParams);
    $provide.constant('ConfigurationService', configurationService);
  }));

  beforeEach(angular.mock.module('openproject.services', function($provide) {
    $provide.constant('WorkPackageFieldService', workPackageFieldService);
    $provide.constant('WorkPackageService', {});
  }));

  beforeEach(inject(function($rootScope, $compile, $q, _I18n_, _ActivityService_) {
    I18n = _I18n_;
    q = $q;
    scope = $rootScope.$new();

    compile = function() {
      workPackageFieldService.isEmpty = sinon.stub().returns(true);
      element = $compile(html)(scope);
      scope.$digest();
    };

    workPackageFieldService.isEmpty = sinon.stub().returns(true);

    ActivityService = _ActivityService_;
    var createComments = sinon.stub(ActivityService, 'createComment');
    commentCreation = q.defer();
    createComments.returns(commentCreation.promise);

    var stub = sinon.stub(I18n, 't');
    stub.withArgs('js.label_add_comment_title').returns('trans_title');
    stub.withArgs('js.label_add_comment').returns('trans_add_comment');
    stub.withArgs('js.button_cancel').returns('trans_cancel');
  }));

  afterEach(function() {
    I18n.t.restore();
    ActivityService.createComment.restore();
  });

  beforeEach(function() {
    var workPackage = {
      addComment: {
        $link: {
          href: 'addComment'
        }
      },
      $plain: function() { return {}; }
    };

    scope.workPackage = workPackage;
  });


  describe('activity comments', function() {
    describe('without comment link in work package', function() {
      beforeEach(function() {
        scope.workPackage.addComment = undefined;
        compile();
      });

      it('should not display the comments form', function() {
        expect(element.find('.work-packages--activity--add-comment').length).to.equal(0);
      });
    });

    describe('with comment link in work package', function() {
      var commentSection, commentField;

      beforeEach(function() {
        compile();

        commentSection  = element.find('.work-packages--activity--add-comment');
      });

      it('should display the comments form', function() {
        expect(commentSection.length).to.equal(1);
      });

      it('should display a placeholder in the comments field', function() {
        var readvalue = commentSection.find('.inplace-edit--read-value > span');
        expect(readvalue.text().trim()).to.equal('trans_title');
      });

      describe('when clicking the inplace edit', function() {
        beforeEach(function() {
          commentSection.find('.inplace-editing--trigger-link').click();
        });

        it('does not allow sending comment with an empty message', function() {
          var saveButton = commentSection.find('.inplace-edit--control--save');
          var commentField = commentSection.find('textarea').click();

          expect(saveButton.attr('disabled')).to.eq('disabled');

          commentField.val('a useful comment');
          commentField.trigger('change');
          expect(saveButton.attr('disabled')).to.be.undefined;
        });
      });
    });
  });
});
