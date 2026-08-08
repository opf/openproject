# frozen_string_literal: true

module Cde
  module Conventions
    @config = nil

    class << self
      def initialize
        config
      end

      def config
        @config ||= begin
          path = Rails.root.join('config/cde_conventions.yml')
          YAML.load_file(path)
        rescue Errno::ENOENT
          raise 'Missing config/cde_conventions.yml — required for CDE plugin'
        end
      end

      def container_id_validator
        @validator ||= begin
          c = config['identifier']['container']
          Regexp.new(c['validator'])
        end
      end

      def status_codes
        config['states']['values']
      end

      def suitability_codes
        config['suitability']['values']
      end

      def publication_preconditions
        config['publication']['preconditions']
      end

      def mandatory_metadata_fields
        config['publication']['preconditions']['mandatory_metadata']
      end
    end
  end
end
