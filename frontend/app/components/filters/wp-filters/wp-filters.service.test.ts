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

import WorkPackageFiltersService from "./wp-filters.service";
const expect = chai.expect;

describe('wpFiltersService', () => {
  var wpFiltersService:WorkPackageFiltersService;

  beforeEach(angular.mock.module('openproject.filters'));
  beforeEach(angular.mock.inject((_wpFiltersService_:any) => {
    wpFiltersService = _wpFiltersService_;
  }));

  it('should exist', () => {
    expect(wpFiltersService).to.exist;
  });

  it('should have set its visibility to false', () => {
    expect(wpFiltersService.visible).to.be.false;
  });

  describe('when using toggleVisibility', () => {
    beforeEach(() => {
      wpFiltersService.toggleVisibility();
    });

    it('should turn its visibility to true', () => {
      expect(wpFiltersService.visible).to.be.true;
    });

    it('should turn off its visibility when used again', () => {
      wpFiltersService.toggleVisibility();
      expect(wpFiltersService.visible).to.be.false;
    });
  });
});
