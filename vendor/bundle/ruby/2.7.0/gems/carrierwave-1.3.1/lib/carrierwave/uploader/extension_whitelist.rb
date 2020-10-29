module CarrierWave
  module Uploader
    module ExtensionWhitelist
      extend ActiveSupport::Concern

      included do
        before :cache, :check_extension_whitelist!
      end

      ##
      # Override this method in your uploader to provide a white list of extensions which
      # are allowed to be uploaded. Compares the file's extension case insensitive.
      # Furthermore, not only strings but Regexp are allowed as well.
      #
      # When using a Regexp in the white list, `\A` and `\z` are automatically added to
      # the Regexp expression, also case insensitive.
      #
      # === Returns
      #
      # [NilClass, String, Regexp, Array[String, Regexp]] a white list of extensions which are allowed to be uploaded
      #
      # === Examples
      #
      #     def extension_whitelist
      #       %w(jpg jpeg gif png)
      #     end
      #
      # Basically the same, but using a Regexp:
      #
      #     def extension_whitelist
      #       [/jpe?g/, 'gif', 'png']
      #     end
      #
      def extension_whitelist; end

    private

      def check_extension_whitelist!(new_file)
        extension = new_file.extension.to_s
        if extension_whitelist && !whitelisted_extension?(extension)
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.extension_whitelist_error", extension: new_file.extension.inspect, allowed_types: Array(extension_whitelist).join(", "))
        end
      end

      def whitelisted_extension?(extension)
        downcase_extension = extension.downcase
        Array(extension_whitelist).any? { |item| downcase_extension =~ /\A#{item}\z/i }
      end

    end # ExtensionWhitelist
  end # Uploader
end # CarrierWave
