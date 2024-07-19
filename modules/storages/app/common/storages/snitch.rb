# frozen_string_literal: true

#-- copyright
#++

module Storages
  module Snitch
    delegate :info, :error, to: :logger

    def with_tagged_logger(tag = self.class, &)
      logger.tagged(*tag, &)
    end

    def logger
      Rails.logger
    end
  end
end
