require 'active_record'
require 'active_record/session_store/version'
require 'action_dispatch/session/active_record_store'
require "active_record/session_store/extension/logger_silencer"
require 'active_support/core_ext/hash/keys'
require 'multi_json'

module ActiveRecord
  module SessionStore
    autoload :Session, 'active_record/session_store/session'

    module ClassMethods # :nodoc:
      mattr_accessor :serializer

      def serialize(data)
        serializer_class.dump(data) if data
      end

      def deserialize(data)
        serializer_class.load(data) if data
      end

      def drop_table!
        if connection.schema_cache.respond_to?(:clear_data_source_cache!)
          connection.schema_cache.clear_data_source_cache!(table_name)
        else
          connection.schema_cache.clear_table_cache!(table_name)
        end
        connection.drop_table table_name
      end

      def create_table!
        if connection.schema_cache.respond_to?(:clear_data_source_cache!)
          connection.schema_cache.clear_data_source_cache!(table_name)
        else
          connection.schema_cache.clear_table_cache!(table_name)
        end
        connection.create_table(table_name) do |t|
          t.string session_id_column, :limit => 255
          t.text data_column_name
        end
        connection.add_index table_name, session_id_column, :unique => true
      end

      def serializer_class
        case self.serializer
          when :marshal, nil then
            MarshalSerializer
          when :json then
            JsonSerializer
          when :hybrid then
            HybridSerializer
          when :null then
            NullSerializer
          else
            self.serializer
        end
      end

      # Use Marshal with Base64 encoding
      class MarshalSerializer
        def self.load(value)
          Marshal.load(::Base64.decode64(value))
        end

        def self.dump(value)
          ::Base64.encode64(Marshal.dump(value))
        end
      end

      # Uses built-in JSON library to encode/decode session
      class JsonSerializer
        def self.load(value)
          hash = MultiJson.load(value)
          hash.is_a?(Hash) ? hash.with_indifferent_access[:value] : hash
        end

        def self.dump(value)
          MultiJson.dump(value: value)
        end
      end

      # Transparently migrates existing session values from Marshal to JSON
      class HybridSerializer < JsonSerializer
        MARSHAL_SIGNATURE = 'BAh'.freeze

        def self.load(value)
          if needs_migration?(value)
            Marshal.load(::Base64.decode64(value))
          else
            super
          end
        end

        def self.needs_migration?(value)
          value.start_with?(MARSHAL_SIGNATURE)
        end
      end

      # Defer serialization to the ActiveRecord database adapter
      class NullSerializer
        def self.load(value)
          value
        end

        def self.dump(value)
          value
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  require 'active_record/session_store/session'
end

require 'active_record/session_store/sql_bypass'
require 'active_record/session_store/railtie' if defined?(Rails)

Logger.send :include, ActiveRecord::SessionStore::Extension::LoggerSilencer

begin
  require "syslog/logger"
  Syslog::Logger.send :include, ActiveRecord::SessionStore::Extension::LoggerSilencer
rescue LoadError; end
