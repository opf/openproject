# encoding: utf-8

module CarrierWaveDirect
  class FormBuilder < ActionView::Helpers::FormBuilder
    def file_field(method, options = {})
      @object.policy(enforce_utf8: true)

      fields = hidden_fields(options)

      # The file field must be the last element in the form.
      # Any element after this will be ignored by Amazon.
      options.merge!(:name => "file")

      fields << super
    end

    def fields_except_file_field(options = {})
      @object.policy(enforce_utf8: true)

      hidden_fields(options)
    end

    def content_type_label(content=nil)
      content ||= 'Content Type'
      @template.label_tag('Content-Type', content)
    end

    def content_type_select(choices = [], selected = nil, options = {})
      @template.select_tag('Content-Type', content_choices_options(choices, selected), options)
    end

    private

    def hidden_fields(options)
      fields = required_base_fields
      fields << content_type_field(options)
      fields << success_action_field(options)
      fields
    end

    def required_base_fields
      fields = ''.html_safe
      @object.direct_fog_hash(enforce_utf8: true).each do |key, value|
        normalized_keys = {
          'X-Amz-Signature':  'signature',
          'X-Amz-Credential': 'credential',
          'X-Amz-Algorithm':  'algorithm',
          'X-Amz-Date': 'date'
        }
        id = "#{@template.dom_class(@object)}_#{normalized_keys[key] || key}"
        if key != :uri
          fields << @template.hidden_field_tag(key, value, id: id, required: false)
        end
      end
      fields
    end

    def content_type_field(options)
      return ''.html_safe unless @object.will_include_content_type

      hidden_field(:content_type, :name => 'Content-Type') unless options[:exclude_content_type]
    end

    def success_action_field(options)
      if @object.use_action_status
        hidden_field(:success_action_status, :name => "success_action_status")
      else
        hidden_field(:success_action_redirect, :name => "success_action_redirect")
      end
    end

    def content_choices_options(choices, selected = nil)
      choices = @object.content_types if choices.blank?
      selected ||= @object.content_type
      @template.options_for_select(choices, selected)
    end
  end
end
