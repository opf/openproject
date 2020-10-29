# encoding: utf-8

module CarrierWaveDirect
  module Test
    module CapybaraHelpers

      include CarrierWaveDirect::Test::Helpers

      def attach_file_for_direct_upload(path)
        attach_file("file", path)
      end

      def find_key
        key = page.find("input[name='key']", visible: false).value
      end

      def find_upload_path
        page.find("input[name='file']", visible: false).value
      end

      def upload_directly(uploader, button_locator, options = {})
        options[:success] = true unless options[:success] == false
        options[:success] &&= !options[:fail]

        if options[:success]
          # simulate a successful upload

          # form's success action redirect url
          redirect_url = URI.parse(page.find("input[name='success_action_redirect']", visible: false).value)

          unless options[:redirect_key]
            sample_key_args = [{:base => find_key, :filename => File.basename(find_upload_path)}]
            sample_key_args.unshift(uploader) if method(:sample_key).arity == -2
            options[:redirect_key] = sample_key(*sample_key_args)
          end
          
          redirect_url_params = Rack::Utils.parse_nested_query(redirect_url.query)
          
          redirect_url.query = Rack::Utils.build_nested_query({
            :bucket => uploader.fog_directory,
            :key => options[:redirect_key],
            :etag => "\"d41d8cd98f00b204e9800998ecf8427\""
          }.merge(redirect_url_params))

          # click the button
          click_button button_locator

          # simulate success redirect
          visit redirect_url.to_s
        else
          # simulate an unsuccessful upload

          # click the button
          click_button button_locator
        end
      end
    end
  end
end

