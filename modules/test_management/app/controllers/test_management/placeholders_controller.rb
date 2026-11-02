# frozen_string_literal: true

module TestManagement
  class PlaceholdersController < ApplicationController
    menu_item :test_management

    before_action :find_project_by_project_id
    before_action :authorize

    PAGES = %w[ci].freeze

    def show
      @placeholder_page = params[:page].to_s
      unless PAGES.include?(@placeholder_page)
        render_404
      end
    end
  end
end
