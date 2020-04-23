module Bim::Bcf
  ##
  # Module to set an initial UUID on the model
  # whenever it is created
  module InitializeWithUuid
    extend ActiveSupport::Concern

    included do
      after_initialize :set_initial_uuid, if: :new_record?
    end

    def set_initial_uuid
      self.uuid ||= SecureRandom.uuid
    end
  end
end
