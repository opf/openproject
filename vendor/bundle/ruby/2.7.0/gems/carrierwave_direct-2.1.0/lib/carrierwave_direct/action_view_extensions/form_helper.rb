# encoding: utf-8

module CarrierWaveDirect

  module ActionViewExtensions
    # This module creates direct upload forms to post to cloud services
    #
    # Example:
    #
    #   direct_upload_form_for @video_uploader do |f|
    #     f.file_field :video
    #     f.submit
    #   end
    #
    module FormHelper

      def direct_upload_form_for(record, *args, &block)
        options = args.extract_options!

        html_options = {
          :multipart => true
        }.update(options[:html] || {})

        form_for(
          record,
          *(args << options.merge(
            :builder => CarrierWaveDirect::FormBuilder,
            :url => record.direct_fog_url,
            :html => html_options,
            :authenticity_token => false,
            :include_id => false
          )),
          &block
        )
      end
    end
  end
end

ActionView::Base.send :include, CarrierWaveDirect::ActionViewExtensions::FormHelper

