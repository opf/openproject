# frozen_string_literal: true

module API
  module V3
    module TestManagement
      class PlanCollectionRepresenter < ::API::Decorators::UnpaginatedCollection
        element_decorator PlanRepresenter
      end
    end
  end
end
