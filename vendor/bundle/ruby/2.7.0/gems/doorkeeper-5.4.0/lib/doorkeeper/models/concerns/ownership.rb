# frozen_string_literal: true

module Doorkeeper
  module Models
    module Ownership
      extend ActiveSupport::Concern

      included do
        belongs_to :owner, polymorphic: true, optional: true
        validates :owner, presence: true, if: :validate_owner?
      end

      def validate_owner?
        Doorkeeper.config.confirm_application_owner?
      end
    end
  end
end
