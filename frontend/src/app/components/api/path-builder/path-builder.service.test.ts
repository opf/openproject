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

import {opApiModule} from '../../../angular-modules';
import {PathBuilderService} from './path-builder.service';

describe('pathBuilder service', () => {
  var pathBuilder:PathBuilderService;

  beforeEach(angular.mock.module(opApiModule.name));
  beforeEach(angular.mock.inject(function (_pathBuilder_:any) {
    [pathBuilder] = _.toArray(arguments);
  }));

  it('should exist', () => {
    expect(pathBuilder).to.exist;
  });

  describe('when defining a collection of paths', () => {
    var pathCollection:any;
    var pathConfig:any;
    var path:any;
    var result:any;
    var params:any;
    var withoutParams:any;
    var withParams:any;

    const testCallablePath = (prepare:any) => {
      beforeEach(prepare);

      it('should exist', () => {
        expect(path).to.exist;
      });

      it('should be callable', () => {
        expect(path).to.not.throw(Error);
      });

      describe('when calling it without params', () => {
        beforeEach(() => {
          result = path();
        });

        it('should generate a path without the param', () => {
          expect(result).to.equal(withoutParams);
        });
      });

      describe('when calling it with params', () => {
        beforeEach(() => {
          result = path(params);
        });

        it('should generate a path with the param', () => {
          expect(result).to.equal(withParams);
        });
      });
    };

    beforeEach(() => {
      pathConfig = {
        string: 'foo{/param}',
        array: ['bar{/param}', {
          nestedString: 'nested-string',
          nestedArray: ['nested-array', {}]
        }],
        withParent: ['hello{/param}', {}, {
          stringParent: 'parent/{stringParent}',
          arrayParent: ['parent/{arrayParent}']
        }],
        withParentAndChild: ['world', {
          child: 'child{/child}'
        }, {
          parent: 'parent/{parent}'
        }]
      };
      pathCollection = pathBuilder.buildPaths(pathConfig);
      params = {param: 'param'};
    });

    it('should return the path collection', () => {
      expect(pathCollection).to.exist;
    });

    it('should have the same keys as the config object', () => {
      expect(pathCollection).to.have.all.keys(pathConfig);
    });

    describe('when the path config is a string, the resulting callable', () => {
      testCallablePath(() => {
        path = pathCollection.string;
        withParams = 'foo/param';
        withoutParams = 'foo';
      });
    });

    describe('when the path config is an array, the resulting callable', () => {
      testCallablePath(() => {
        path = pathCollection.array;
        withParams = 'bar/param';
        withoutParams = 'bar';
      });

      it('should have the same properties as the config object', () => {
        expect(path).to.have.all.keys(pathConfig.array[1]);
      });

      describe('when the nested path is a string', () => {
        testCallablePath(() => {
          path = path.nestedString;
          withParams = 'bar/param/nested-string';
          withoutParams = 'bar/nested-string';
        });
      });

      describe('when the nested path is an array', () => {
        testCallablePath(() => {
          path = path.nestedArray;
          withParams = 'bar/param/nested-array';
          withoutParams = 'bar/nested-array';
        });
      });
    });

    describe('when passing false values as params to a path with a parent', () => {
      testCallablePath(() => {
        path = pathCollection.withParent;
        params = {stringParent: null};
        withParams = 'hello';
        withoutParams = 'hello';
      });
    });

    describe('when the path has a parent', () => {
      beforeEach(() => {
        path = pathCollection.withParent;
        withParams = 'parent/parentId/hello';
        withoutParams = 'hello';
      });

      describe('when the parent is a string', () => {
        testCallablePath(() => {
          params = {stringParent: 'parentId'};
        });
      });

      describe('when the parent is a array', () => {
        testCallablePath(() => {
          params = {arrayParent: 'parentId'};
        });
      });

      describe('when the parent was set, but gets reset afterwards', () => {
        beforeEach(() => {
          path({stringParent: 'parentId'});
          result = path();
        });

        it('should not include the path segment of the parent', () => {
          expect(result).to.equal('hello');
        });
      });
    });

    describe('when the path is a child of a path with a parent', () => {
      beforeEach(() => {
        path = pathCollection.withParentAndChild.child;
      });

      describe('when only the child id is set', () => {
        testCallablePath(() => {
          params = {child: 'childId', parent: null};
          withParams = 'world/child/childId';
          withoutParams = 'world/child';
        });
      });

      describe('when only the parent id is set', () => {
        testCallablePath(() => {
          params = {parent: 'parentId', child: null};
          withParams = 'parent/parentId/world/child';
          withoutParams = 'world/child';
        });
      });

      describe('when both ids are set', () => {
        testCallablePath(() => {
          params = {child: 'childId', parent: 'parentId'};
          withParams = 'parent/parentId/world/child/childId';
          withoutParams = 'world/child';
        });
      });
    });
  });
});
