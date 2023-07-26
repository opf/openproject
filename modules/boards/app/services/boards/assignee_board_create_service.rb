# frozen_string_literal: true

module Boards
  class AssigneeBoardCreateService < BaseCreateService
    private

    def grid_lacks_query?(_params)
      true
    end

    def options_for_widgets(_params)
      []
    end
  end
end
