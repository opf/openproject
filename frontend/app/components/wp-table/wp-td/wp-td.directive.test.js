// -- copyright
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
// ++

describe('wpTd Directive', function() {
  var compile, element, rootScope, scope;

  beforeEach(angular.mock.module('openproject.workPackages.directives'));
  beforeEach(angular.mock.module('openproject.templates',
                                 'openproject.api',
                                 'openproject.services'));
  beforeEach(angular.mock.module('openproject.templates', function($provide) {
    var configurationService = {};

    configurationService.isTimezoneSet = sinon.stub().returns(false);

    $provide.constant('ConfigurationService', configurationService);
  }));

  beforeEach(inject(function($rootScope, $compile) {
    var html;
    html = '<wp-td work-package="workPackage" column="column" display-type="displayType"' +
          'display-empty="-"></wp-td>';

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();

    compile = function() {
      $compile(element)(scope);
      scope.$digest();
    };
  }));

  var getInnermostSpan = function(start) {
    return start.find('span :not(:has("*"))').first();
  };

  describe('element', function() {
    beforeEach(function() {
      scope.workPackage = {
        subject: 'Subject1',
        type: { id: 1, name: 'Bug'},
        sheep: 10,
        custom_values: [ { custom_field_id: 1, field_format: 'string', value: 'asdf1234'} ]
      };
    });

    describe('rendering an object field', function(){
      beforeEach(function(){
        scope.column = {
          custom_field: false,
          groupable: 'type',
          meta_data: { data_type: 'object', link: { display: false} },
          name: 'type',
          sortable: 'types:position',
          title: 'Type'
        };
        scope.displayType = 'text';

        compile();
      });

      it('should contain the object title', function() {
        var content = getInnermostSpan(element);

        expect(content.text()).to.equal('Bug');
      });

      it('should have the object title as title attribute', function() {
        var tag = getInnermostSpan(element);

        expect(tag.attr('title')).to.equal('Bug');
      });
    });

    describe('rendering a text field', function(){
      beforeEach(function(){
        scope.column = {
          custom_field: false,
          groupable: false,
          meta_data: { data_type: 'string', link: { display: false} },
          name: 'subject',
          sortable: 'work_packages.subject',
          title: 'Subject'
        };
        scope.displayType = 'text';

        compile();
      });

      it('should contain the text', function() {
        var content = getInnermostSpan(element);

        expect(content.text()).to.equal('Subject1');
      });

      it('should contain the text as the title', function() {
        var tag = getInnermostSpan(element);

        expect(tag.attr('title')).to.equal('Subject1');
      });
    });

    describe('rendering a number field', function(){
      beforeEach(function(){
        scope.column = {
          custom_field: false,
          groupable: false,
          meta_data: { data_type: 'integer', link: { display: false} },
          name: 'sheep',
          sortable: 'work_packages.sheep',
          title: 'Sheep'
        };
        scope.displayType = 'number';

        compile();
      });

      it('should contain the text', function() {
        var content = getInnermostSpan(element);

        expect(content.text()).to.equal('10');
      });

      it('should contain the text as the title', function() {
        var tag = getInnermostSpan(element);

        expect(tag.attr('title')).to.equal('10');
      });
    });

    describe('rendering a custom string field', function(){
      beforeEach(function(){
        scope.column = {
          custom_field: { field_format: 'string', id: 1 },
          groupable: false,
          meta_data: { data_type: 'string', link: { display: false} },
          name: 'a_custom_field',
          title: 'A Custom Field'
        };
        scope.displayType = 'text';

        compile();
      });

      it('should contain the text', function() {
        var content = getInnermostSpan(element);

        expect(content.text()).to.equal('asdf1234');
      });

      it('should contain the text as the title', function() {
        var tag = getInnermostSpan(element);

        expect(tag.attr('title')).to.equal('asdf1234');
      });
    });

    describe('rendering missing field', function(){
      beforeEach(function(){
        scope.column = {
          custom_field: false,
          groupable: false,
          meta_data: { data_type: 'string', link: { display: false} },
          name: 'non_existant',
          title: 'Non-existant'
        };
        scope.displayType = 'text';

        compile();
      });

      it('should contain the display empty text', function() {
        var content = getInnermostSpan(element);

        expect(content.text()).to.equal('-');
      });

      it('should contain the empty text as the title', function() {
        var tag = getInnermostSpan(element);

        expect(tag.attr('title')).to.equal('-');
      });
    });

    describe('rendering missing custom field', function(){
      beforeEach(function(){
        scope.column = {
          custom_field: { field_format: 'string', id: 2 },
          groupable: false,
          meta_data: { data_type: 'string', link: { display: false} },
          name: 'non_existant',
          title: 'Non-existant'
        };
        scope.displayType = 'text';

        compile();
      });

      it('should contain the display empty text', function() {
        var content = getInnermostSpan(element);

        expect(content.text()).to.equal('-');
      });

      it('should contain the empty text as the title', function() {
        var tag = getInnermostSpan(element);

        expect(tag.attr('title')).to.equal('-');
      });
    });
  });
});
