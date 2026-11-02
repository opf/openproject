# frozen_string_literal: true

module API
  module V3
    module TestManagement
      class ImportCollectionRepresenter < ::API::Decorators::UnpaginatedCollection
        element_decorator ImportRepresenter
      end
    end
  end
end
