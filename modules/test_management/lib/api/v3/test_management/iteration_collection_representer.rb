# frozen_string_literal: true

module API
  module V3
    module TestManagement
      class IterationCollectionRepresenter < ::API::Decorators::UnpaginatedCollection
        element_decorator IterationRepresenter
      end
    end
  end
end
