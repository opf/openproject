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

/*jshint expr: true*/

describe('activityCommentDirective', function() {
  var I18n, ActivityService, compile, scope, element, stateParams, q, commentCreation;
  var html = "<exclusive-edit><activity-comment work-package='workPackage' activities='activities'></activity-comment></exclusive-edit>";
  stateParams = {};

  beforeEach(module('ui.router',
                    'openproject.api',
                    'openproject.models',
                    'openproject.layout',
                    'openproject.services',
                    'openproject.uiComponents',
                    'openproject.workPackages.tabs',
                    'openproject.workPackages.directives',
                    'openproject.workPackages.models',
                    'openproject.workPackages.services'));

  beforeEach(module('templates', function($provide) {
    var configurationService = {
      commentsSortedInDescendingOrder: function() { return []; }
    };

    $provide.constant('$stateParams', stateParams);
    $provide.constant('ConfigurationService', configurationService);
  }));

  beforeEach(inject(function($rootScope, $compile, $q, _I18n_, _ActivityService_) {
    I18n = _I18n_;
    q = $q;
    scope = $rootScope.$new();

    compile = function() {
      element = $compile(html)(scope);
      scope.$digest();
    };

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
      links: {
        addComment: { href: 'addComment' },
      }
    };

    scope.workPackage = workPackage;
  });


  describe('activity comments', function() {
    describe('without comment link in work package', function() {
      beforeEach(function() {
        scope.workPackage.links.addComment = undefined;
        compile();
      });

      it('should not display the comments form', function() {
        expect(element.find('.activity-comment.ng-hide').length).to.equal(1);
      });
    });

    describe('with comment link in work package', function() {
      beforeEach(function() {
        compile();
      });

      it('should display the comments form', function() {
        expect(element.find('.activity-comment').length).to.equal(1);
      });

      it('does not allow sending comment with an emtpy message', function() {
        var comment       = element.find('.activity-comment textarea'),
            save_button   = element.find('.activity-comment button');

        comment.val('');
        comment.change();
        expect(save_button.attr('disabled')).to.equal('disabled');

        comment.val('a useful comment');
        comment.change();
        expect(save_button.attr('disabled')).to.equal(undefined);

      });

      it('does prevent double posts', function() {
        var comment       = element.find('.activity-comment textarea'),
            save_button   = element.find('.activity-comment button');

        // comments can be saved when there is text to post
        comment.val('a useful comment');
        comment.change();
        expect(save_button.attr('disabled')).to.equal(undefined);

        // while sending the comment, one cannot send another comment
        save_button.click();
        scope.$digest();
        expect(save_button.scope().processingComment).to.equal(true);
        expect(save_button.attr('disabled')).to.equal('disabled');

        // after sending, we can send comments again
        commentCreation.resolve();
        scope.$digest();
        expect(save_button.scope().processingComment).to.equal(false);

      });
    });
  });
});
