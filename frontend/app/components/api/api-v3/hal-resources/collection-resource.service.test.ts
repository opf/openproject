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

import {opApiModule, opServicesModule} from '../../../../angular-modules';
import IQService = angular.IQService;
import IRootScopeService = angular.IRootScopeService;

describe('CollectionResource service', () => {
  var $q:any;
  var $rootScope:any;
  var CollectionResource:any;

  var source:any;
  var collection:any;

  beforeEach(angular.mock.module(opApiModule.name, opServicesModule.name));
  beforeEach(angular.mock.inject(function (_$q_:any, _$rootScope_:any, _CollectionResource_:any) {
    [$q, $rootScope, CollectionResource] = _.toArray(arguments);
  }));

  function createCollection() {
    source = source || {};
    collection = new CollectionResource(source);
  }

  it('should exist', () => {
    expect(CollectionResource).to.exist;
  });

  describe('when using updateElements', () => {
    var elements:any;
    var result:any;

    beforeEach(() => {
      createCollection();
      elements = [{}, {}];
      sinon.stub(collection, '$load').returns($q.when({elements}));

      result = collection.updateElements();
      $rootScope.$apply();
    });

    it('should set the elements of the resource so the new value', () => {
      expect(collection.elements).to.equal(elements);
    });

    it('should return a promise with the elements as the result', () => {
      expect(result).to.eventually.equal(elements);
    });
  });
});
