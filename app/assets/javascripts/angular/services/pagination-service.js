angular.module('openproject.services')

.service('PaginationService', ['DEFAULT_PAGINATION_OPTIONS', function(DEFAULT_PAGINATION_OPTIONS) {
  var paginationOptions = {
    page: DEFAULT_PAGINATION_OPTIONS.page,
    perPage: DEFAULT_PAGINATION_OPTIONS.perPage,
    perPageOptions: DEFAULT_PAGINATION_OPTIONS.perPageOptions
  };

  PaginationService = {
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
}]);
