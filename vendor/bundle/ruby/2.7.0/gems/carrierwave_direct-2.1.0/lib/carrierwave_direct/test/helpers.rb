# encoding: utf-8

module CarrierWaveDirect
  module Test
    module Helpers
      # Example usage:

      # sample_key(ImageUploader, :base => "store_dir/guid/${filename}")
      # => "store_dir/guid/filename.extension"

      def sample_key(uploader, options = {})
        options[:valid] = true unless options[:valid] == false
        options[:valid] &&= !options[:invalid]
        options[:base] ||= uploader.key
        if options[:filename]
          filename_parts = options[:filename].split(".")
          options[:extension] = filename_parts.pop if filename_parts.size > 1
          options[:filename] = filename_parts.join(".")
        end
        options[:filename] ||= "filename"
        valid_extension = uploader.extension_whitelist.first if uploader.extension_whitelist
        options[:extension] = options[:extension] ? options[:extension].gsub(".", "") : (valid_extension || "extension")
        key = options[:base].split("/")
        key.pop
        key.pop unless options[:valid]
        key << "#{options[:filename]}.#{options[:extension]}"
        key.join("/")
      end
    end
  end
end

