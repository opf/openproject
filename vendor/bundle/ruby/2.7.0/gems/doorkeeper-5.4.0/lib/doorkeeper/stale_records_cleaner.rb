# frozen_string_literal: true

module Doorkeeper
  class StaleRecordsCleaner
    CLEANER_CLASS = "StaleRecordsCleaner"

    def self.for(base_scope)
      orm_adapter = "doorkeeper/orm/#{configured_orm}".classify

      orm_cleaner = "#{orm_adapter}::#{CLEANER_CLASS}".constantize
      orm_cleaner.new(base_scope)
    rescue NameError
      raise Doorkeeper::Errors::NoOrmCleaner, "'#{configured_orm}' ORM has no cleaner!"
    end

    def self.new(base_scope)
      self.for(base_scope)
    end

    def self.configured_orm
      Doorkeeper.config.orm
    end
  end
end
