# frozen_string_literal: true

module API
  module V3
    module TestManagement
      class RunCollectionRepresenter < ::API::Decorators::UnpaginatedCollection
        element_decorator RunRepresenter
      end
    end
  end
end
