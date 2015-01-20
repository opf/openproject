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

  beforeEach(module('openproject.templates', function($provide) {
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
        expect(element.find('.activity-comment').length).to.equal(0);
      });
    });

    describe('with comment link in work package', function() {
      var commentSection, commentField;

      beforeEach(function() {
        compile();

        commentSection  = element.find('.activity-comment');
        commentField    = commentSection.find('textarea');
      });

      it('should display the comments form', function() {
        expect(commentSection.length).to.equal(1);
      });

      it('should provide a label next to the comments field', function() {
        var label = commentSection.find('label[for=' + commentField.attr('id') + ']');

        expect(label.text().trim()).to.equal('trans_title');
      });

      it('should display a placeholder in the comments field', function() {
        expect(commentField.attr('placeholder')).to.equal('trans_title');
      });

      it('does not allow sending comment with an empty message', function() {
        var saveButton = commentSection.find('button');

        commentField.val('');
        commentField.change();
        expect(saveButton.prop('disabled')).to.be.true;

        commentField.val('a useful comment');
        commentField.change();
        expect(saveButton.prop('disabled')).to.be.false;
      });

      it('does prevent double posts', function() {
        var saveButton = commentSection.find('button');

        // comments can be saved when there is text to post
        commentField.val('a useful comment');
        commentField.change();
        expect(saveButton.prop('disabled')).to.be.false;

        // while sending the comment, one cannot send another comment
        saveButton.click();
        expect(saveButton.scope().$parent.processingComment).to.be.true;
        expect(saveButton.scope().$parent.activity.comment).to.equal('a useful comment');
        expect(commentField.prop('disabled')).to.be.true;
        expect(saveButton.prop('disabled')).to.be.true;

        // after sending, we can send comments again
        commentCreation.resolve();
        scope.$digest();
        expect(saveButton.scope().$parent.processingComment).to.be.false;
        expect(saveButton.scope().$parent.activity.comment).to.equal('');
        expect(commentField.val()).to.equal('');
        expect(commentField.prop('disabled')).to.be.false;
      });
    });
  });
});
