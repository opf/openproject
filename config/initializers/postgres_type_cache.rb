##
# We backported the proposed PostgreSQL adapter type cache code by Zhang 'piecehealth' Kang
# to rails 6.0.3 and apply the patches here to improve performance conisderably
# for new database connections. This is especially important when working with many postgres schemas.
#
# See:
#
#     https://community.openproject.com/projects/saas/work_packages/33955/activity
#     https://github.com/rails/rails/pull/39077
#
# @TODO remove this once the PR is merged into the rails master and once we have updated
#       to rails 6.1 which will likely include this then.

require 'active_record/connection_adapters/schema_cache'

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      class SchemaCache < ActiveRecord::ConnectionAdapters::SchemaCache
        attr_reader :postgresql_additional_type_records, :postgresql_known_coder_type_records

        def encode_with(coder)
          super
          reset_postgresql_type_records!
          coder["postgresql_additional_type_records"] = @postgresql_additional_type_records
          coder["postgresql_known_coder_type_records"] = @postgresql_known_coder_type_records
        end

        def init_with(coder)
          @postgresql_additional_type_records = coder["postgresql_additional_type_records"]
          @postgresql_known_coder_type_records = coder["postgresql_known_coder_type_records"]
          super
        end

        def clear!
          super
          @postgresql_additional_type_records = []
          @postgresql_known_coder_type_records = []
        end

        def marshal_dump
          reset_version!
          reset_postgresql_type_records!
          [@version, @columns, {}, @primary_keys, @data_sources, @indexes, database_version, @postgresql_additional_type_records, @postgresql_known_coder_type_records]
        end

        def marshal_load(array)
          @version, @columns, _columns_hash, @primary_keys, @data_sources, @indexes, @database_version, @postgresql_additional_type_records, @postgresql_known_coder_type_records = array
          @indexes ||= {}

          derive_columns_hash_and_deduplicate_values
        end

        private
          def reset_postgresql_type_records!
            @postgresql_additional_type_records = connection&.additional_type_records_cache
            @postgresql_known_coder_type_records = connection&.known_coder_type_records_cache
          end
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    module PostgresAdapterTypeCache
      def self.prepended(base)
        base.cattr_accessor :additional_type_records_cache, default: []
        base.cattr_accessor :known_coder_type_records_cache, default: []

        class << base
          def clear_type_records_cache!
            self.additional_type_records_cache = []
            self.known_coder_type_records_cache = []
          end

          delegate :clear_type_records_cache!, to: :class
        end
      end

      module_function

      def load_additional_types(oids = nil)
        initializer = PostgreSQL::OID::TypeMapInitializer.new(type_map)

        if additional_type_records_cache.present?
          use_cache = if oids.nil?
            true
          else
            cached_oids = additional_type_records_cache.map { |oid| oid["oid"] }
            (oids - cached_oids).empty?
          end

          if use_cache
            initializer.run(additional_type_records_cache)
            return
          end
        end

        query = <<~SQL
          SELECT t.oid, t.typname, t.typelem, t.typdelim, t.typinput, r.rngsubtype, t.typtype, t.typbasetype
          FROM pg_type as t
          LEFT JOIN pg_range as r ON oid = rngtypid
        SQL

        if oids
          query += "WHERE t.oid IN (%s)" % oids.join(", ")
        else
          query += initializer.query_conditions_for_initial_load
        end

        execute_and_clear(query, "SCHEMA", []) do |records|
          self.additional_type_records_cache |= records.to_a
          initializer.run(records)
        end
      end

      def add_pg_decoders
        @default_timezone = nil
        @timestamp_decoder = nil

        coders_by_name = {
          "int2" => PG::TextDecoder::Integer,
          "int4" => PG::TextDecoder::Integer,
          "int8" => PG::TextDecoder::Integer,
          "oid" => PG::TextDecoder::Integer,
          "float4" => PG::TextDecoder::Float,
          "float8" => PG::TextDecoder::Float,
          "bool" => PG::TextDecoder::Boolean,
        }

        if defined?(PG::TextDecoder::TimestampUtc)
          # Use native PG encoders available since pg-1.1
          coders_by_name["timestamp"] = PG::TextDecoder::TimestampUtc
          coders_by_name["timestamptz"] = PG::TextDecoder::TimestampWithTimeZone
        end

        if known_coder_type_records_cache.present?
          coders = known_coder_type_records_cache
                    .map { |row| construct_coder(row, coders_by_name[row["typname"]]) }
                    .compact
        else
          known_coder_types = coders_by_name.keys.map { |n| quote(n) }
          query = <<~SQL % known_coder_types.join(", ")
            SELECT t.oid, t.typname
            FROM pg_type as t
            WHERE t.typname IN (%s)
          SQL
          coders = execute_and_clear(query, "SCHEMA", []) do |result|
            self.known_coder_type_records_cache = result.to_a

            result
              .map { |row| construct_coder(row, coders_by_name[row["typname"]]) }
              .compact
          end
        end

        map = PG::TypeMapByOid.new
        coders.each { |coder| map.add_coder(coder) }
        @connection.type_map_for_results = map

        # extract timestamp decoder for use in update_typemap_for_default_timezone
        @timestamp_decoder = coders.find { |coder| coder.name == "timestamp" }
        update_typemap_for_default_timezone
      end

      def reload_type_map
        clear_type_records_cache!
        super
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    module AbstractPoolTypeCache
      def get_schema_cache(connection)
        self.schema_cache ||= defined?(PostgreSQLAdapter) && connection.kind_of?(PostgreSQLAdapter) ? PostgreSQL::SchemaCache.new(connection) : SchemaCache.new(connection)
        schema_cache.connection = connection
        schema_cache
      end
    end
  end
end

require "active_record/connection_adapters/postgresql_adapter"
require 'active_record/connection_adapters/abstract/connection_pool'

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  .prepend ActiveRecord::ConnectionAdapters::PostgresAdapterTypeCache

ActiveRecord::ConnectionAdapters::AbstractPool
  .prepend ActiveRecord::ConnectionAdapters::AbstractPoolTypeCache
