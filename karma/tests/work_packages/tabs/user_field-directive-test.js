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

describe('userField Directive', function() {
    var compile, element, rootScope, scope;

    beforeEach(angular.mock.module('openproject.workPackages.tabs'));
    beforeEach(module('templates', 'openproject.helpers'));

    beforeEach(inject(function($rootScope, $compile, PathHelper) {
      var html;
      html = '<user-field user="user"></user-field>';

      element = angular.element(html);
      rootScope = $rootScope;
      scope = $rootScope.$new();

      compile = function() {
        $compile(element)(scope);
        scope.$digest();
      };
    }));

    describe('element', function() {
      describe('with a valid user', function(){
        beforeEach(function() {
          scope.user = {
            props: {
              firstName: "John",
              lastName: "Doe",
              avatar: "avatar.png"
            }
          };
          compile();
          scope.$apply();
        });

        context("user's avatar", function() {
          it('should have an alt attribute', function() {
            expect(element.find('.user-avatar--avatar').attr('alt')).to.equal('Avatar');
          });

          it("should have the title set to user's name", function() {
            expect(element.find('.user-avatar--avatar').attr('title')).to.equal('John Doe');
          });

        });
      });


    });
});
