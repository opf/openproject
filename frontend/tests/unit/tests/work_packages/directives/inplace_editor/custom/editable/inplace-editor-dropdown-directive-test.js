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

describe('Inplace editor dropdown directive', function() {
  var element,
      scope,
      html,
      workPackageFieldService = {},
      workPackageFieldConfigurationService = {},
      allowedValues = [],
      angularCompile;

  html = '<div><inplace-editor-dropdown></inplace-editor-dropdown></div>';

  beforeEach(angular.mock.module('openproject.workPackages.directives'));

  beforeEach(module('openproject.services', function($provide) {
    $provide.constant('WorkPackageFieldService', workPackageFieldService);
    $provide.constant('WorkPackageService', {});
    $provide.constant('WorkPackageFieldConfigurationService', workPackageFieldConfigurationService);
  }));

  beforeEach(module('openproject.templates'));

  beforeEach(inject(function($rootScope, $compile, $q) {
    angularCompile = $compile;

    scope = $rootScope.$new();

    allowedValues = [{
                       href: '/1',
                       name: 'zzzzzz'
                     },
                     {
                       href: '/2',
                       name: 'mmmmmm'
                     },
                     {
                       href: '/3',
                       name: 'aaaaaa'
                     }];

    var allowedValuePromise = $q(function(resolve) {
      resolve(allowedValues);
    });

    workPackageFieldService.getAllowedValues = sinon.stub().returns(allowedValuePromise);
    workPackageFieldService.isRequired = sinon.stub().returns(true);
    workPackageFieldConfigurationService.getDropdownSortingStrategy = sinon.stub().returns(null);

    // severing dependency from the work package field directive as described by
    // http://busypeoples.github.io/post/testing-angularjs-hierarchical-directives
    element = angular.element(html);
    var workPackageFieldController = { state:
                                        { isBusy: false }
                                     };
    element.data('$workPackageFieldController', workPackageFieldController);
  }));

  var compile = function() {
    angularCompile(element)(scope);

    scope.$digest();

    // open the ui-select
    var uiSelectScope = element.find('.inplace-edit--select .ui-select-match')
                               .data()
                               .$scope;

    uiSelectScope.$select.activate();

    uiSelectScope.$digest();
  };

  it('prints the allowedValues as options in a ui-select', function() {
    compile();

    element.find('li .select2-result-label div').each(function(index) {
      expect(angular.element(this).text()).to.equal(allowedValues[index].name);
    });
  });

  it ('has a ui-select option at the beginning if isRequired is false', function () {
    workPackageFieldService.isRequired = sinon.stub().returns(false);

    compile();

    expect(element.find('li .select2-result-label div').length).to.equal(4);
    expect(element.find('li .select2-result-label div').first().text()).to.equal('');
  });

  it('sorts the allowed values if specified by the configuration service', function() {
    workPackageFieldConfigurationService.getDropdownSortingStrategy = sinon.stub().returns('name');

    compile();

    element.find('li .select2-result-label div').each(function(index) {
      expect(angular.element(this).text()).to.equal(allowedValues[2 - index].name);
    });
  });
});
