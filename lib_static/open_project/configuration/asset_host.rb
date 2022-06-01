module OpenProject
  module Configuration
    module AssetHost
      module_function

      def value
        Proc.new do |source|
          asset_host if serve_through_asset_host? source
        end
      end

      def asset_host
        @asset_host ||= OpenProject::Configuration["rails_asset_host"]
      end

      def serve_through_asset_host?(source)
        src = String(source)

        include_prefixes.any? { |prefix| src.start_with? prefix }
      end

      ##
      # Only serve resources with these prefixes from the asset host.
      def include_prefixes
        ["/assets/"]
      end
    end
  end
end
