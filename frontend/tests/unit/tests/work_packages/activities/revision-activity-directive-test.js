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

describe('revisionActivity Directive', function() {
    var compile, element, rootScope, scope;

    beforeEach(angular.mock.module('openproject.workPackages.activities'));
    beforeEach(function() {
      module(
        'ng-context-menu',
        'openproject.api',
        'openproject.workPackages',
        'openproject.models',
        'openproject.services',
        'openproject.config',
        'openproject.templates'
      );
    });

    beforeEach(inject(function($rootScope, $compile) {
      var html;
      html = '<revision-activity work-package="workPackage" activity="activity" activity-no="activityNo" is-initial="isInitial"></revision-activity>';

      rootScope = $rootScope;
      scope = $rootScope.$new();

      compile = function() {
        element = angular.element(html);
        $compile(element)(scope);
        scope.$digest();
      };
    }));

    describe('with a valid revision', function(){
      beforeEach(function() {
        scope.workPackage = {
          links: {
            revisions: true
          },
          embedded: {},
          props: {}
        };
        scope.activity = {
          links: {
            showRevision: '/project/foo/repository/revision/1234',
          },
          props: {
            'id': 1,
            'identifier': '11f4b07dff4f4ce9548a52b7d002daca7cd63ec6',
            'formattedIdentifier': '11f4b07',
            'authorName': 'some developer',
            'message': {
                'format': 'plain',
                'raw': 'This revision provides new features\n\nAn elaborate description',
                'html': '<p>This revision provides new features<br><br>An elaborate description</p>'
            },
            'createdAt': '2015-07-21T13:36:59Z'
          }
        };
        compile();
      });

      it('should not render an image', function() {
        expect(element.find('.avatar')).to.have.length(0);
      });

      it('should have the author name, but no link', function() {
        expect(element.find('.user').html()).to.equal('some developer');
        expect(element.find('.user > a')).to.have.length(0);
      });

      describe('with linked author', function() {
        beforeEach(function() {
          scope.activity.links.author = {
            fetch: function() {
              return {
                then: function(cb) {
                  cb({
                    props: {
                      id: 1,
                      name: 'Some Dude',
                      avatar: 'avatar.png',
                      status: 'active'
                    }
                  });
                }
              };
            }
          };
          compile();
        });

        it('should render a user profile', function() {
          expect(element.find('.avatar').attr('alt')).to.equal('Avatar');
          expect(element.find('span.user > a').text()).to.equal('Some Dude');
        });
      });

      describe('message', function() {
        it('should render commit message', function() {
          var message = element.find('span.user-comment > span.message').html();

          expect(message).to.eq(scope.activity.props.message.html);
        });
      });
    });
});
