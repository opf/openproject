# frozen_string_literal: true

module API
  module V3
    module TestManagement
      class MilestoneCollectionRepresenter < ::API::Decorators::UnpaginatedCollection
        element_decorator MilestoneRepresenter
      end
    end
  end
end
