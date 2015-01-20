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

describe('workPackageColumn Directive', function() {
    var compile, element, rootScope, scope;

    beforeEach(angular.mock.module('openproject.workPackages.directives'));
    beforeEach(module('openproject.templates', 'openproject.api', 'openproject.services'));
    beforeEach(module('openproject.templates', function($provide) {
      var configurationService = {};

      configurationService.isTimezoneSet = sinon.stub().returns(false);

      $provide.constant('ConfigurationService', configurationService);
    }));
    beforeEach(inject(function($rootScope, $compile) {
      var html;
      html = '<span work-package-column work-package="workPackage" column="column" display-type="displayType" display-empty="-"></span>';

      element = angular.element(html);
      rootScope = $rootScope;
      scope = $rootScope.$new();

      compile = function() {
        $compile(element)(scope);
        scope.$digest();
      };
    }));

    describe('element', function() {
      beforeEach(function() {
        scope.workPackage = {
          subject: "Subject1",
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

        it('should render a span', function() {
          expect(element.prop('tagName')).to.equal('SPAN');
        });

        it('should contain the object title', function() {
          var content = element.find('span').first();
          expect(content.text()).to.equal('Bug');
        });

        it('should have the object title as title attribute', function() {
          var tag = element.find('span').first();
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
          var content = element.find('span').first();
          expect(content.text()).to.equal('Subject1');
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
          var content = element.find('span').first();
          expect(content.text()).to.equal('10');
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
          var content = element.find('span').first();
          expect(content.text()).to.equal('asdf1234');
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
          var content = element.find('span').first();
          expect(content.text()).to.equal('-');
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
          var content = element.find('span').first();
          expect(content.text()).to.equal('-');
        });
      });

    });

    describe('linking', function() {
      beforeEach(function() {

        scope.workPackage = {
          subject: "Subject",
          type: { id: 1, name: 'Bug'},
          sheep: 10,
          parent: { id: 1, subject: 'Test child work package' },
          parent_id: 1,
          assigned_to: { id: 1, name: 'Name', firstname: 'My', type: 'User' },
          custom_values: [ { custom_field_id: 1, field_format: 'string', value: 'asdf1234'} ],
          project: {
            id:         29,
            identifier: 'project-dream-team'
          }
        };
        scope.displayType = 'link';
       });

      describe('to assignee', function() {
        describe('who is a regular user', function() {
          beforeEach(function() {
            scope.column = {
              meta_data: { data_type: 'object', link: { display: true, model_type: 'user'} },
              name: 'assigned_to'
            };
            scope.workPackage.assigned_to.type = 'User';
            compile();
          });

          it('should have correct href', function() {
            var content = element.find('a').last();
            expect(content.attr('href')).to.equal('/users/1');
          });

          it('should have the title equal to content', function() {
            var tag = element.find('a').last();
            expect(tag.attr('title')).to.equal(tag.text());
          });
        });

        describe('who is a group', function() {
          beforeEach(function() {
            scope.column = {
              meta_data: { data_type: 'object', link: { display: true, model_type: 'user'} },
              name: 'assigned_to'
            };
            scope.workPackage.assigned_to.type = 'Group';
            compile();
          });

          it('should not be a link', function() {
            expect(element.find('a').length).to.equal(0);
          });

          it('should only have the name as content', function() {
            var content = element.find('span').first();
            expect(content.text()).to.equal('Name');
          });
        });
      });

      describe('to project', function() {
        beforeEach(function() {
          scope.column = {
            meta_data: { data_type: 'object', link: { display: true, model_type: 'project'} },
            name: 'project'
          };
          compile();
        });

        it('should have correct href', function() {
          var content = element.find('a').last();
          expect(content.attr('href')).to.equal('/projects/project-dream-team');
        });

        it('should have the title equal to content', function() {
          var tag = element.find('a').last();
          expect(tag.attr('title')).to.equal(tag.text());
        });
      });

      describe('to parent work package', function() {

        beforeEach(function() {
          scope.column = {
            custom_field: false,
            groupable: false,
            meta_data: { data_type: 'object', link: { display: true, model_type: 'work_package'} },
            name: 'parent',
            sortable: 'work_packages.subject',
            title: 'Parent'
          };
          compile();
        });

        it('should have correct href', function() {
          var content = element.find('a').last();
          expect(content.attr('href')).to.equal('/work_packages/1');
        });
        it('should have the title equal to content', function() {
          var tag = element.find('a').last();
          expect(tag.attr('title')).to.equal(tag.text());
        });
      });
    });
});
