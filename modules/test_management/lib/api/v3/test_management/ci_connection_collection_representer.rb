# frozen_string_literal: true

module API
  module V3
    module TestManagement
      class CiConnectionCollectionRepresenter < ::API::Decorators::UnpaginatedCollection
        element_decorator CiConnectionRepresenter
      end
    end
  end
end
