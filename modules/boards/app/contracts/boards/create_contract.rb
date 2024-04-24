# frozen_string_literal: true

module Boards
  class CreateContract < ::Grids::CreateContract
    private

    def validate_allowed
      unless edit_allowed?
        # "project" is what is exposed to the user in the global form, not "scope"
        errors.add(:project, :blank)
      end
    end
  end
end
