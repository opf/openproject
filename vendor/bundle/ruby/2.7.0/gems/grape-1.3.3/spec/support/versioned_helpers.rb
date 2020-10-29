# frozen_string_literal: true

# Versioning
module Spec
  module Support
    module Helpers
      # Returns the path with options[:version] prefixed if options[:using] is :path.
      # Returns normal path otherwise.
      def versioned_path(options = {})
        case options[:using]
        when :path
          File.join('/', options[:prefix] || '', options[:version], options[:path])
        when :param
          File.join('/', options[:prefix] || '', options[:path])
        when :header
          File.join('/', options[:prefix] || '', options[:path])
        when :accept_version_header
          File.join('/', options[:prefix] || '', options[:path])
        else
          raise ArgumentError.new("unknown versioning strategy: #{options[:using]}")
        end
      end

      def versioned_headers(**options)
        case options[:using]
        when :path
          {}  # no-op
        when :param
          {}  # no-op
        when :header
          {
            'HTTP_ACCEPT' => [
              "application/vnd.#{options[:vendor]}-#{options[:version]}",
              options[:format]
            ].compact.join('+')
          }
        when :accept_version_header
          {
            'HTTP_ACCEPT_VERSION' => options[:version].to_s
          }
        else
          raise ArgumentError.new("unknown versioning strategy: #{options[:using]}")
        end
      end

      def versioned_get(path, version_name, version_options = {})
        path    = versioned_path(version_options.merge(version: version_name, path: path))
        headers = versioned_headers(**version_options.merge(version: version_name))
        params = {}
        if version_options[:using] == :param
          params = { version_options[:parameter] => version_name }
        end
        get path, params, headers
      end
    end
  end
end
