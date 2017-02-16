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

describe('queryFilters', () => {
  var doc:any, $httpBackend:any,
      $timeout:any, compile:any, scope:any, element:any,
      OPERATORS_AND_LABELS_BY_FILTER_TYPE:any, OPERATORS_NOT_REQUIRING_VALUES:any;
  var html = "<query-filters></query-filters>";

  beforeEach(angular.mock.module(
    'ui.router',
    'openproject.filters',
    'openproject.api',
    'openproject.layout',
    'openproject.workPackages.directives',
    'openproject.workPackages.config',
    'openproject.workPackages.filters'));

  beforeEach(angular.mock.module('openproject.templates', function ($provide:any) {
    $provide.constant('ConfigurationService', {
      accessibilityModeEnabled: sinon.stub().returns(false),
      isTimezoneSet: sinon.stub().returns(false)
    });
  }));

  beforeEach(angular.mock.inject(($rootScope:any,
                                  $compile:any,
                                  $document:any,
                                  _$httpBackend_:any,
                                  _$timeout_:any,
                                  PathHelper:any,
                                  _OPERATORS_AND_LABELS_BY_FILTER_TYPE_:any,
                                  _OPERATORS_NOT_REQUIRING_VALUES_:any) => {
    $httpBackend = _$httpBackend_;
    $timeout = _$timeout_;
    OPERATORS_AND_LABELS_BY_FILTER_TYPE = _OPERATORS_AND_LABELS_BY_FILTER_TYPE_;
    OPERATORS_NOT_REQUIRING_VALUES = _OPERATORS_NOT_REQUIRING_VALUES_;

    doc = $document[0];
    scope = $rootScope.$new();


    compile = () => {
      element = $compile(html)(scope);
      scope.$digest();
      var body = angular.element(doc.body);
      body.append(element);
      $timeout.flush();
    };

    var path = PathHelper.apiCustomFieldsPath();
    var customFieldFilters = {custom_field_filters: {}};
    $httpBackend.when('GET', path).respond(200, customFieldFilters);
  }));

  afterEach(() => {
    var body = angular.element(doc.body);
    body.find('#filters').remove();
  });


  describe('accessibility', () => {
    describe('focus', () => {
      // I used filters that are not of type 'list_model' or 'list_optional' to
      // prevent additional mocking of WorkPackageLoadingHelper.
      var filter1 = Factory.build('Filter', {name: 'subject'});
      var filter2 = Factory.build('Filter', {name: 'start_date'});
      var filter3 = Factory.build('Filter', {name: 'done_ratio'});

      // currently unused
      var removeFilter = (filterName:string) => {
        var removeLinkElement = angular.element(element).find('#filter_' + filterName +
          ' .advanced-filters--remove-filter a');
        var enterEvent = jQuery.Event('keyup', {which: 13});

        angular.element(removeLinkElement[0]).trigger(enterEvent);
        $timeout.flush();
      };

      beforeEach(() => {
        scope.query = Factory.build('Query', {filters: []});
        scope.query.setFilters([filter1, filter2, filter3]);
        scope.operatorsAndLabelsByFilterType = OPERATORS_AND_LABELS_BY_FILTER_TYPE;
        compile();
      });

      describe('operator dropdown preselected value', () => {
        context('OPERATORS_NOT_REQUIRING_VALUES', () => {
          context('will not preselect any operators not requiring values', () => {
            beforeEach(() => {
              OPERATORS_AND_LABELS_BY_FILTER_TYPE['some_type'] = [
                {symbol:'!*', label:'label_none'}, {symbol:'*', label:'label_all'}
              ];
              scope.query.filters.push({
                isSelectInputField: () => false,
                name: 'some_value',
                type: 'some_type',
                values: []
              });
              scope.$apply();
            });
            it('should have injected an undefined option', () => {
              var operatorValue = element.find('#operators-some_value').val();
              expect(operatorValue).to.eq('? undefined:undefined ?');
            });
          });

          context('will preselect first operator requiring values', () => {
            beforeEach(() => {
              scope.query.filters.push({
                isSelectInputField: () => false,
                name: 'some_value',
                type: 'integer',
                values: []
              });
              scope.$apply();
            });
            it('should take the first one', () => {
              var operatorValue = element.find('#operators-some_value').val();
              expect(operatorValue).to.eq('=');
            });
          });
        });
      });
    });
  });
});
