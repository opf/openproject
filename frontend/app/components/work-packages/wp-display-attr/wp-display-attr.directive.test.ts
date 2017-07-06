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

import {WorkPackageCacheService} from './../work-package-cache.service';

describe('wpDisplayAttr directive', () => {
  var compile:any;
  var element:any;
  var rootScope;
  var scope:any;
  var I18n:any;
  var wpCacheService: WorkPackageCacheService;


  beforeEach(angular.mock.module(
    'openproject',
    'openproject.workPackages.directives',
    'openproject.templates',
    'openproject.api',
    'openproject.services'
  ));

  beforeEach(angular.mock.module('openproject.templates', ($provide:any) => {
    $provide.constant('ConfigurationService', {
      isTimezoneSet: sinon.stub().returns(false),
      accessibilityModeEnabled: sinon.stub().returns(false)
    });
  }));

  beforeEach(angular.mock.inject(($rootScope:any, $compile:any, _I18n_:any, _$httpBackend_:any, _wpCacheService_:any) => {
    var html = `
      <wp-display-attr work-package="workPackage" attribute="attribute">
      </wp-display-attr>
    `;

    I18n = _I18n_;
    wpCacheService = _wpCacheService_;
    var stub = sinon.stub(I18n, 't');
    stub.withArgs('js.general_text_no').returns('No');
    stub.withArgs(sinon.match.any).returns('');

    element = angular.element(html);
    rootScope = $rootScope;
    scope = $rootScope.$new();

    // Expected request for updates
    _$httpBackend_.expectGET('/api/v3/work_packages/1').respond(200);

    compile = () => {
      wpCacheService.updateWorkPackage(scope.workPackage);

      $compile(element)(scope);
      scope.$digest();
    };
  }));

  afterEach(() => {
    I18n.t.restore();
  });

  var getInnermostSpan = (start:any) => start.find('span:not(:has(span)):not(.hidden-for-sighted)');

  describe('element', () => {
    beforeEach(angular.mock.inject(($q:any) => {
      scope.workPackage = {
        subject: 'Subject1',
        mybool: false,
        type: {id: 1, name: 'Bug'},
        sheep: 10,
        id: 1,
        customField1: 'asdf1234',
        emptyField: null,
        hasOverriddenSchema: true,
        schema: {
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
          "mybool": {
            "type": "Boolean",
            "name": "My Bool",
            "required": false,
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
          },
          "emptyField": {
            "type": "String",
            "name": "empty field",
            "required": false,
            "writable": true
          },
        }
      }
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
        scope.attribute = 'non-existent-field';
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

    describe('rendering a boolean field', () => {
      beforeEach(() => {
        scope.attribute = 'mybool';
        compile();
      });

      it('should render the field as No', () => {
        expect(element.find('.inplace-edit--read-value--value.-placeholder').length).to.eql(0);

        var content = getInnermostSpan(element);
        expect(content.text().trim()).to.equal('No');
      });
    });

    describe('rendering an empty field', () => {
      beforeEach(() => {
        scope.attribute = 'emptyField';
        compile();
      });

      it('should adorne the element with the -placeholder class', () => {
        expect(element.find('.inplace-edit--read-value--value.-placeholder').length).to.eql(1);
      });
    });
  });
});
