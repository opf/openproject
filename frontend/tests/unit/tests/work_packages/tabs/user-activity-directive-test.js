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

describe('userActivity Directive', function() {
    var compile, element, rootScope, scope;

    beforeEach(angular.mock.module('openproject.workPackages.tabs'));
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
      module(function ($provide) {
        $provide.value('$uiViewScroll', angular.noop);
      });
    });

    beforeEach(inject(function($rootScope, $compile, $uiViewScroll, $timeout, $location, I18n, PathHelper, ActivityService, UsersHelper) {
      var html;
      html = '<div exclusive-edit class="exclusive-edit"><user-activity work-package="workPackage" activity="activity" activity-no="activityNo" input-element-id="inputElementId"></user-activity></div>';

      rootScope = $rootScope;
      scope = $rootScope.$new();

      compile = function() {
        element = angular.element(html);
        $compile(element)(scope);
        scope.$digest();
      };
    }));

    describe('element', function() {
      describe('with a valid user', function(){
        beforeEach(function() {
          scope.workPackage = {
            links: {
              addComment: true
            }
          };
          scope.activity = {
            links: {
              update: true,
              user: {
                fetch: function() {
                  return {
                    then: function(cb) {
                      cb({
                        props: {
                          id: 1,
                          name: "John Doe",
                          avatar: 'avatar.png',
                          status: 1
                        }
                      }
                    );}
                  };
                }
              }
            },
            props: {
              comment: {
                format: 'textile',
                raw: 'This is my *comment* with _some_ markup.',
                html: '<p>This is my <strong>comment</strong> with <em>some</em> markup.</p>'
              },
              details: [
                {
                  format: 'textile',
                  raw: 'Status changed',
                  html: '<strong>Status</strong> changed'
                },
                {
                  format: 'textile',
                  raw: 'Type changed',
                  html: '<strong>Type</strong> changed'
                },
              ]
            },
          };
          compile();
        });

        context("user's avatar", function() {
          it('should have an alt attribute', function() {
            expect(element.find('.avatar').attr('alt')).to.equal('Avatar');
          });

          it("should have the title set to user's name", function() {
            expect(element.find('.avatar').attr('title')).to.equal('John Doe');
          });

          describe('when being empty', function() {
            beforeEach(function() {
              scope.activity.links.user.fetch = function() {
                return {
                  then: function(cb) {
                    cb({
                      props: {
                        id: 1,
                        name: "John Doe",
                        avatar: '',
                        status: 1
                      }
                    });
                  }
                };
              };
              compile();
            });

            it('should not be rendered', function() {
              expect(element.find('.avatar')).to.have.length(0);
            });
          });

        });

        describe('comment', function() {
          it('should render activity comment', function() {
            var comment = element.find('span.user-comment > span.message').html();

            expect(comment).to.eq(scope.activity.props.comment.html);
          });
        });

        describe('details', function() {
          it('should render activity details', function() {
            var list = element.find('ul.work-package-details-activities-messages');
            var detail1 = list.find(':nth-child(1) .message').html();
            var detail2 = list.find(':nth-child(2) .message').html();

            expect(detail1).to.eq(scope.activity.props.details[0].html);
            expect(detail2).to.eq(scope.activity.props.details[1].html);
          });
        });
      });
    });
});
