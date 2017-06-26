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

import {opApiModule} from '../../../../angular-modules';
import IPromise = angular.IPromise;
import IRootScopeService = angular.IRootScopeService;
import IHttpBackendService = angular.IHttpBackendService;
import {RelationsDmService} from './relations-dm.service';
import {buildApiV3Filter} from '../api-v3-filter-builder';

describe('relationsDm service', () => {
  var $httpBackend:IHttpBackendService;
  var relationsDm:RelationsDmService;
  var $rootScope:ng.IRootScopeService;

  beforeEach(angular.mock.module(opApiModule.name));
  beforeEach(angular.mock.inject(function (_relationsDm_:RelationsDmService, _$rootScope_:ng.IRootScopeService, _$httpBackend_:ng.IHttpBackendService) {
    $httpBackend = _$httpBackend_;
    relationsDm = _relationsDm_;
    $rootScope = _$rootScope_;
  }));

  it('should exist', () => {
    expect(relationsDm).to.exist;
  });

  afterEach(() => {
    $rootScope.$apply();
  });

  function filterString(ids:string[]) {
    let filterString = encodeURI(buildApiV3Filter('involved', '=', ids).toJson());
    // Angular extends on encodeURI to unescape some values..
    // https://github.com/angular/angular.js/blob/v1.5.x/src/Angular.js
    filterString = filterString.replace(/=/gi, '%3D');
    return '?filters=' + filterString;
  }

  describe('#loadInvolved', () => {
    let promise:ng.IPromise<any>;
    let ids:string[];

    describe('when requesting some IDs', () => {
      beforeEach(() => {
        ids = ['1', '2', '3'];
        promise = relationsDm.loadInvolved(ids);
      });

      it('should append the parameters at the end of the requested url', () => {
        $httpBackend.expectGET('/api/v3/relations' + filterString(ids)).respond(200, { elements: ['foo'] });
        $httpBackend.flush();

        expect(promise).to.eventually.be.fulfilled.then((relations) => {
          expect(relations).to.deep.equal(['foo']);
        });
      });
    });

    describe('when requesting with an invalid IDs', () => {
      beforeEach(() => {
        ids = ['1', 'foo'];
        promise = relationsDm.loadInvolved(ids);
      });

      it('should append the parameters at the end of the requested url', () => {
        $httpBackend.expectGET('/api/v3/relations' + filterString(['1'])).respond(200, { elements: ['foo'] });
        $httpBackend.flush();

        expect(promise).to.eventually.be.fulfilled.then((relations) => {
          expect(relations).to.deep.equal(['foo']);
        });
      });
    });

    describe('when requesting with no valid IDs', () => {
      beforeEach(() => {
        ids = ['foo'];
        promise = relationsDm.loadInvolved(ids);
      });

      it('should append the parameters at the end of the requested url', () => {
        expect($httpBackend.flush).to.throw('No pending request to flush !');
        expect(promise).to.eventually.be.fulfilled.then((relations) => {
          expect(relations).to.be.empty;
        });
      });
    });
  });
});
