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

      element = angular.element(html);
      rootScope = $rootScope;
      scope = $rootScope.$new();

      compile = function() {
        $compile(element)(scope);
        scope.$apply();
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
            }
          };
          compile();
        });

        context("user's avatar", function() {
          it('should have an alt attribute', function() {
            expect(element.find('.avatar').attr('alt')).to.equal('Avatar');
          });

          it("should have the title set to user's name", function() {
            console.log(element);
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
      });

    });
});
