class Timelines::TimelinesPrincipalsController < ApplicationController
  extend Timelines::Pagination::Controller

  timelines_paginate_model Principal
  timelines_search_for Principal, :like
end
