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

import {ApiPathsService} from './api-paths.service';

describe('apiPaths', () => {
  var apiPaths:ApiPathsService;
  var $document:ng.IDocumentService;

  beforeEach(angular.mock.module('openproject.api'));
  beforeEach(angular.mock.module('openproject.services'));

  beforeEach(angular.mock.inject((_$document_, _apiPaths_) => {
    $document = _$document_;
    apiPaths = _apiPaths_;
  }));

  describe('when without app_base_path', () => {
    describe('when using path()', () => {
      it('should return an api experimental path', () => {
        expect(apiPaths.path('experimental')).to.eq('/api/experimental/');
      });

      it('should return an api v2 path', () => {
        expect(apiPaths.path('v2')).to.eq('/api/v2/');
      });

      it('should return an api v3 path', () => {
        expect(apiPaths.path('v3')).to.eq('/api/v3/');
      });
    });

    describe('when using v3', () => {
      it('should return an api v3 path', () => {
        expect(apiPaths.v3).to.eq('/api/v3/');
      });
    });

    describe('when using v2', () => {
      it('should return an api v3 path', () => {
        expect(apiPaths.v2).to.eq('/api/v2/');
      });
    });

    describe('when using experimental', () => {
      it('should return an api experimental path', () => {
        expect(apiPaths.experimental).to.eq('/api/experimental/');
      });
    });
  });
});
