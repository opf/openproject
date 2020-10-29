module CarrierWaveDirect
  module Policies
    class Base
      attr_reader :uploader
      def initialize(uploader)
        @uploader = uploader
      end

      def policy(options = {}, &block)
        options[:expiration] ||= uploader.upload_expiration
        options[:min_file_size] ||= uploader.min_file_size
        options[:max_file_size] ||= uploader.max_file_size
        @policy ||= generate(options, &block)
      end

      def clear!
        @policy = nil
      end
    end
  end
end
