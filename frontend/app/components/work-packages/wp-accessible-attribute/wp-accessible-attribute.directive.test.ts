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

describe('wpAccessibleAttributeDirective', function() {
  var html = '<div wp-accessible-attribute="field"></div>';
  var scope, element, $compile;

  beforeEach(angular.mock.module('openproject.workPackages.directives'));

  beforeEach(inject(function(_$compile_,
                             $rootScope){
    scope = $rootScope.$new();

    $compile = _$compile_;
  }));

  describe('on noneditable fields', function() {
    beforeEach(function() {
      scope.field = {
        isEditable: function() {
          return false;
        },
        getKeyValue: function() {
          return 'myKeyValue';
        }
      };

      element = $compile(html)(scope);
      scope.$apply();
    });

    it('has a tabindex of 0', function() {
      expect(element.attr('tabindex')).to.eq('0');
    });

    it('has an aria-label with the keyValue', function() {
      expect(element.attr('aria-label')).to.eq(scope.field.getKeyValue());
    });
  });

  describe('on editable fields', function() {
    beforeEach(function() {
      scope.field = {
        isEditable: function() {
          return true;
        },
        getKeyValue: function() {
          return 'myKeyValue';
        }
      };

      element = $compile(html)(scope);
      scope.$apply();
    });

    it('has no tabindex', function() {
      expect(element.attr('tabindex')).to.eq(undefined);
    });

    it('has an aria-label with the keyValue', function() {
      expect(element.attr('aria-label')).to.eq(undefined);
    });
  });
});
