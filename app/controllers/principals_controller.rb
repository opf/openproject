class PrincipalsController < ApplicationController
  extend Pagination::Controller

  paginate_model Principal
  search_for Principal, :like
end
