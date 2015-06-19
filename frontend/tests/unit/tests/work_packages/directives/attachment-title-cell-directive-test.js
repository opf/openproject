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

describe('attachmentTitleCell Directive', function() {
    var compile, element, rootScope, scope;

    beforeEach(angular.mock.module('openproject.workPackages.directives'));
    beforeEach(module('openproject.templates'));

    beforeEach(inject(function($rootScope, $compile) {
      var html;
      html = '<td attachment-title-cell attachment="attachment"></td>';

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
        scope.attachment = {
          props: {
            id: 1,
            fileName: 'hearmi.now',
            fileSize: '12340'
          },
          links: {
            downloadLocation: { href: "ze link to da file" }
          }
        };

        compile();
      });

      it('should render element', function() {
        expect(element.prop('tagName')).to.equal('TD');
      });

      it('should render link to attachment', function() {
        var link = element.find('a');
        expect(link.text()).to.equal('hearmi.now');
        expect(link.attr('href')).to.equal('ze link to da file');
      });
    });
});
