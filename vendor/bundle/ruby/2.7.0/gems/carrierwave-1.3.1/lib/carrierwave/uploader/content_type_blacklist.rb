module CarrierWave
  module Uploader
    module ContentTypeBlacklist
      extend ActiveSupport::Concern

      included do
        before :cache, :check_content_type_blacklist!
      end

      ##
      # Override this method in your uploader to provide a blacklist of files content types
      # which are not allowed to be uploaded.
      # Not only strings but Regexp are allowed as well.
      #
      # === Returns
      #
      # [NilClass, String, Regexp, Array[String, Regexp]] a blacklist of content types which are not allowed to be uploaded
      #
      # === Examples
      #
      #     def content_type_blacklist
      #       %w(text/json application/json)
      #     end
      #
      # Basically the same, but using a Regexp:
      #
      #     def content_type_blacklist
      #       [/(text|application)\/json/]
      #     end
      #
      def content_type_blacklist; end

    private

      def check_content_type_blacklist!(new_file)
        content_type = new_file.content_type
        if content_type_blacklist && blacklisted_content_type?(content_type)
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.content_type_blacklist_error", content_type: content_type)
        end
      end

      def blacklisted_content_type?(content_type)
        Array(content_type_blacklist).any? { |item| content_type =~ /#{item}/ }
      end

    end # ContentTypeBlacklist
  end # Uploader
end # CarrierWave
