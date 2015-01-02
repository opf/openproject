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

module.exports = function(DEFAULT_PAGINATION_OPTIONS) {
  var paginationOptions = {
    page: DEFAULT_PAGINATION_OPTIONS.page,
    perPage: DEFAULT_PAGINATION_OPTIONS.perPage,
    perPageOptions: DEFAULT_PAGINATION_OPTIONS.perPageOptions,
    maxVisiblePageOptions: DEFAULT_PAGINATION_OPTIONS.maxVisiblePageOptions,
    optionsTruncationSize: DEFAULT_PAGINATION_OPTIONS.optionsTruncationSize
  };

  var PaginationService = {
    getPaginationOptions: function() {
      return paginationOptions;
    },
    getPage: function() {
      return paginationOptions.page;
    },
    setPage: function(page) {
      paginationOptions.page = page;
    },
    getPerPage: function() {
      return paginationOptions.perPage;
    },
    getMaxVisiblePageOptions: function() {
      return paginationOptions.maxVisiblePageOptions;
    },
    getOptionsTruncationSize: function() {
      return paginationOptions.optionsTruncationSize;
    },
    setPerPage: function(perPage) {
      paginationOptions.perPage = perPage;
    },
    getPerPageOptions: function() {
      return paginationOptions.perPageOptions;
    },
    setPerPageOptions: function(perPageOptions) {
      paginationOptions.perPageOptions = perPageOptions;
    },
    getLowerPageBound: function() {
      return paginationOptions.perPage * (paginationOptions.page - 1) + 1;
    },
    getUpperPageBound: function(limit) {
      return Math.min(paginationOptions.perPage * paginationOptions.page, limit);
    },
    resetPage: function() {
      paginationOptions.page = 1;
    },
    nextPage: function() {
      paginationOptions.page = paginationOptions.page + 1;
    },
    previousPage: function() {
      paginationOptions.page = paginationOptions.page - 1;
    }
  };

  return PaginationService;
};
