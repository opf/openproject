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

describe('wpDisplayAttr directive', () => {
  var compile;
  var element;
  var rootScope;
  var scope;

  beforeEach(angular.mock.module(
    'openproject.workPackages.directives',
    'openproject.templates',
    'openproject.api',
    'openproject.services'
  ));

  beforeEach(angular.mock.module('openproject.templates', $provide => {
    $provide.constant('ConfigurationService', {
      isTimezoneSet: sinon.stub().returns(false),
      accessibilityModeEnabled: sinon.stub().returns(false);
    });
  }));

  beforeEach(angular.mock.inject(($rootScope, $compile) => {
    var html = `
      <wp-display-attr work-package="workPackage" schema="schema" attribute="attribute">
      </wp-display-attr>
    `;

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();

    compile = () => {
      $compile(element)(scope);
      scope.$digest();
    };
  }));

  var getInnermostSpan = start => start.find('.cell-span--value');

  describe('element', () => {
    beforeEach(angular.mock.inject(($q) => {
      scope.workPackage = {
        subject: 'Subject1',
        type: {id: 1, name: 'Bug'},
        sheep: 10,
        customField1: 'asdf1234',
      };
      scope.schema = {
        "$load": () => $q.when(true),
        "_type": "Schema",
        "type": {
          "type": "Type",
          "name": "Type",
          "required": true,
          "writable": true,
          "_links": {},
          "_embedded": {}
        },
        "subject": {
          "type": "String",
          "name": "Subject",
          "required": true,
          "writable": true,
          "minLength": 1,
          "maxLength": 255
        },
        "sheep": {
          "type": "Integer",
          "name": "Sheep",
          "required": true,
          "writable": true
        },
        "sheep": {
          "type": "Integer",
          "name": "Sheep",
          "required": true,
          "writable": true
        },
        "customField1": {
          "type": "String",
          "name": "foobar",
          "required": false,
          "writable": true
        }
      };
    }));

    describe('rendering an object field', () => {
      beforeEach(() => {
        scope.attribute = 'type';
        compile();
      });

      it('should contain the object title', () => {
        var content = getInnermostSpan(element);

        expect(content.text().trim()).to.equal('Bug');
      });

      it('should have the object title as title attribute', () => {
        var tag = getInnermostSpan(element);

        expect(tag.attr('title')).to.equal('Bug');
      });
    });

    describe('rendering a text field', () => {
      beforeEach(() => {
        scope.attribute = 'subject';
        compile();
      });

      it('should contain the text', () => {
        var content = getInnermostSpan(element);

        expect(content.text().trim()).to.equal('Subject1');
      });

      it('should contain the text as the title', () => {
        var tag = getInnermostSpan(element);

        expect(tag.attr('title')).to.equal('Subject1');
      });
    });

    describe('rendering a number field', () => {
      beforeEach(() => {
        scope.attribute = 'sheep';
        compile();
      });

      it('should contain the text', () => {
        var content = getInnermostSpan(element);

        expect(content.text().trim()).to.equal('10');
      });

      it('should contain the text as the title', () => {
        var tag = getInnermostSpan(element);

        expect(tag.attr('title')).to.equal('10');
      });
    });

    describe('rendering a custom string field', () => {
      beforeEach(() => {
        scope.attribute = 'customField1';
        compile();
      });

      it('should contain the text', () => {
        var content = getInnermostSpan(element);

        expect(content.text().trim()).to.equal('asdf1234');
      });

      it('should contain the text as the title', () => {
        var tag = getInnermostSpan(element);

        expect(tag.attr('title')).to.equal('asdf1234');
      });
    });

    describe('rendering missing field', () => {
      beforeEach(() => {
        scope.attribute = 'non-existant-field';
        compile();
      });

      it('should contain the display empty text', () => {
        var content = getInnermostSpan(element);

        expect(content.text().trim()).to.equal('');
      });

      it('should contain the empty text as the title', () => {
        var tag = getInnermostSpan(element);

        expect(tag.attr('title')).to.equal('');
      });
    });
  });
});
