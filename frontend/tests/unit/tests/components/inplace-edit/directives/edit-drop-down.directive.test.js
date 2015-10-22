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

describe('Inplace editor drop-down directive', function() {
  var element, scope, html, workPackageFieldConfigurationService = {},
      allowedValues = [], angularCompile;

  html = '<div><inplace-editor-drop-down></inplace-editor-drop-down></div>';

  beforeEach(angular.mock.module('openproject.inplace-edit'));

  beforeEach(module('openproject.services', function($provide) {
    $provide.constant('WorkPackageService', {});
    $provide.constant('WorkPackageFieldConfigurationService', workPackageFieldConfigurationService);
  }));

  beforeEach(module('openproject.templates'));

  beforeEach(inject(function($rootScope, $compile, $q) {
    angularCompile = $compile;

    scope = $rootScope.$new();

    allowedValues = [
      { href: '/1', name: 'zzzzzz'},
      { href: '/2', name: 'mmmmmm'},
      { href: '/3', name: 'aaaaaa'}
    ];

    var allowedValuePromise = $q(function(resolve) {
      resolve(allowedValues);
    });

    scope.field = {
      getAllowedValues: sinon.stub().returns(allowedValuePromise),
      format: sinon.stub().returns({ props: { name: allowedValues[0].name } }),
      isRequired: sinon.stub().returns(true),
      value: { props: { href: allowedValues[0].href } }
    };

    // severing dependency from the work package field directive as described by
    // http://busypeoples.github.io/post/testing-angularjs-hierarchical-directives
    element = angular.element(html);
    var workPackageFieldController = {
      state: { isBusy: false }
    };
    element.data('$workPackageFieldController', workPackageFieldController);

    workPackageFieldConfigurationService.getDropdownSortingStrategy = sinon.stub().returns(null);

    angularCompile(element)(scope);
    scope.$digest();
  }));

  it('has options to choose from', function () {
    var amount = element.find('.inplace-edit-select > option').length;
    expect(amount).to.equal(allowedValues.length);
  });

  it('prints the allowedValues as options', function() {
    element.find('.inplace-edit-select > option').each(function(index) {
      expect(angular.element(this).text()).to.equal(allowedValues[index].name);
    });
  });

  it('preselects a value', function() {
    var selectedText = element.find('.inplace-edit-select > option:selected').text();
    expect(selectedText).to.equal(allowedValues[0].name);
  });
});
