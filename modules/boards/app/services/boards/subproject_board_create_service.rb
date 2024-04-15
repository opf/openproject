# frozen_string_literal: true

module Boards
  class SubprojectBoardCreateService < BaseCreateService
    private

    def no_widgets_initially?
      true
    end
  end
end
