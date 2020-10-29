module CarrierWave
  module Uploader
    module ExtensionBlacklist
      extend ActiveSupport::Concern

      included do
        before :cache, :check_extension_blacklist!
      end

      ##
      # Override this method in your uploader to provide a black list of extensions which
      # are prohibited to be uploaded. Compares the file's extension case insensitive.
      # Furthermore, not only strings but Regexp are allowed as well.
      #
      # When using a Regexp in the black list, `\A` and `\z` are automatically added to
      # the Regexp expression, also case insensitive.
      #
      # === Returns

      # [NilClass, String, Regexp, Array[String, Regexp]] a black list of extensions which are prohibited to be uploaded
      #
      # === Examples
      #
      #     def extension_blacklist
      #       %w(swf tiff)
      #     end
      #
      # Basically the same, but using a Regexp:
      #
      #     def extension_blacklist
      #       [/swf/, 'tiff']
      #     end
      #

      def extension_blacklist; end

    private

      def check_extension_blacklist!(new_file)
        extension = new_file.extension.to_s
        if extension_blacklist && blacklisted_extension?(extension)
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.extension_blacklist_error", extension: new_file.extension.inspect, prohibited_types: Array(extension_blacklist).join(", "))
        end
      end

      def blacklisted_extension?(extension)
        Array(extension_blacklist).any? { |item| extension =~ /\A#{item}\z/i }
      end
    end
  end
end
