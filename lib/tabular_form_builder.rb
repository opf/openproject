#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'action_view/helpers/form_helper'
require 'securerandom'

class TabularFormBuilder < ActionView::Helpers::FormBuilder
  include Redmine::I18n
  include ActionView::Helpers::AssetTagHelper
  include ERB::Util
  include TextFormattingHelper

  def self.tag_with_label_method(selector, &block)
    ->(field, options = {}, *args) do
      options[:class] = Array(options[:class]) + [field_css_class(selector)]
      merge_required_attributes(options[:required], options)

      input_options, label_options = extract_from options

      if field_has_errors?(field)
        input_options[:class] << ' -error'
      end

      label = label_for_field(field, label_options)
      input = super(field, input_options, *args)

      input = instance_exec(input, options, &block) if block_given?

      (label + container_wrap_field(input, selector, options))
    end
  end
  private_class_method :tag_with_label_method

  def self.with_text_formatting
    ->(input, options) {
      if options[:with_text_formatting]
        # use either the provided id or fetch the one created by rails
        id = options[:id] || input.match(/<[^>]* id="(\w+)"[^>]*>/)[1]
        options[:preview_context] ||= preview_context(object)
        input.concat text_formatting_wrapper id, options
      end

      input
    }
  end
  private_class_method :with_text_formatting

  (field_helpers - %i(radio_button hidden_field fields_for label text_area) + %i(date_select)).each do |selector|
    define_method selector, &tag_with_label_method(selector)
  end

  define_method(:text_area, &tag_with_label_method(:text_area, &with_text_formatting))

  def label(method, text = nil, options = {}, &block)
    options[:class] = Array(options[:class]) + %w(form--label)
    options[:title] = options[:title] || title_from_context(method)
    super
  end

  def radio_button(field, value, options = {}, *args)
    options[:class] = Array(options[:class]) + %w(form--radio-button)

    input_options, label_options = extract_from options
    label_options[:for] = "#{sanitized_object_name}_#{field}_#{value.downcase}"

    if field_has_errors?(field)
      input_options[:class] << ' -error'
    end

    label = label_for_field(field, label_options)
    input = super(field, value, input_options, *args)

    (label + container_wrap_field(input, 'radio-button', options))
  end

  def select(field, choices, options = {}, html_options = {})
    html_options[:class] = Array(html_options[:class]) + %w(form--select)
    if html_options[:container_class].present?
      options[:container_class] = html_options[:container_class]
    end

    if field_has_errors?(field)
      html_options[:class] << ' -error'
    end

    merge_required_attributes(options[:required], html_options)
    label_for_field(field, options) + container_wrap_field(super, 'select', options)
  end

  def collection_select(field, collection, value_method, text_method, options = {}, html_options = {})
    html_options[:class] = Array(html_options[:class]) + %w(form--select)

    label_for_field(field, options) + container_wrap_field(super, 'select', options)
  end

  def collection_check_box(field,
                           checked_value,
                           checked,
                           text = field.to_s + "_#{checked_value}",
                           options = {})

    label_for = "#{sanitized_object_name}_#{field}_#{checked_value}".to_sym
    unchecked_value = options.delete(:unchecked_value) { '' }

    input_options = options.reverse_merge(multiple: true,
                                          checked: checked,
                                          for: label_for,
                                          label: text)

    if options.delete(:no_label)
      input_options.delete :for
      input_options.delete :label
    end

    check_box(field, input_options, checked_value, unchecked_value)
  end

  def fields_for_custom_fields(record_name, record_object = nil, options = {}, &block)
    options_with_defaults = options.merge(builder: CustomFieldFormBuilder)

    fields_for(record_name, record_object, options_with_defaults, &block)
  end

  private

  attr_reader :template

  TEXT_LIKE_FIELDS = %i(
    number_field password_field url_field telephone_field email_field
  ).freeze

  def container_wrap_field(field_html, selector, options = {})
    ret = content_tag(:span, field_html, class: field_container_css_class(selector, options))

    prefix, suffix = options.values_at(:prefix, :suffix)

    if prefix
      ret.prepend content_tag(:span,
                              prefix.html_safe,
                              class: 'form--field-affix',
                              id: options[:prefix_id],
                              'aria-hidden': true)
    end

    if suffix
      ret.concat content_tag(:span,
                             suffix.html_safe,
                             class: 'form--field-affix',
                             id: options[:suffix_id],
                             'aria-hidden': true)
    end

    field_container_wrap_field(ret, options)
  end

  def merge_required_attributes(required, options = nil)
    if required
      options.merge!(required: true, 'aria-required': 'true')
    end
  end

  def field_container_wrap_field(field_html, options = {})
    if options[:no_label]
      field_html
    else
      content_tag(:span, field_html, class: options[:no_class] ? '' : 'form--field-container')
    end
  end

  def field_container_css_class(selector, options)
    classes = if TEXT_LIKE_FIELDS.include?(selector)
                'form--text-field-container'
              else
                "form--#{selector.to_s.tr('_', '-')}-container"
              end

    classes << ' ' + options.fetch(:container_class, '')

    classes.strip
  end

  ##
  # Create a wrapper for the text formatting toolbar for this field
  def text_formatting_wrapper(target_id, options)
    return ''.html_safe unless target_id.present?

    helper = ::OpenProject::TextFormatting::Formats.rich_helper.new(@template)
    helper.wikitoolbar_for target_id, options
  end

  def field_css_class(selector)
    if TEXT_LIKE_FIELDS.include?(selector)
      "form--text-field -#{selector.to_s.gsub(/_field$/, '')}"
    else
      "form--#{selector.to_s.tr('_', '-')}"
    end
  end

  # Returns a label tag for the given field
  def label_for_field(field, options = {})
    return ''.html_safe if options[:no_label]

    text = get_localized_field(field, options[:label])
    label_options = { class: 'form--label', title: text }

    if options[:class].is_a?(Array)
      label_options[:class] << " #{options[:class].join(' ')}"
    elsif options[:class].is_a?(String)
      label_options[:class] << " #{options[:class]}"
    end

    content = h(text)
    label_for_field_errors(content, label_options, field)
    label_for_field_for(options, label_options, field)
    label_for_field_prefix(content, options)

    label_options[:lang] = options[:lang]
    label_options.reject! do |_k, v|
      v.nil?
    end

    @template.label(@object_name, field, content, label_options)
  end

  def label_for_field_errors(content, options, field)
    if field_has_errors?(field)
      options[:class] << ' -error'
      error_label = I18n.t('errors.field_erroneous_label',
                           full_errors: @object.errors.full_messages_for(field).join(' '))
      content << content_tag('p', error_label, class: 'hidden-for-sighted')
    end
  end

  def label_for_field_for(options, label_options, field)
    label_options[:for] = options[:for]
  end

  def label_for_field_prefix(content, options)
    if options[:prefix]
      content << content_tag(:span, options[:prefix].html_safe, class: 'hidden-for-sighted')
    end
  end

  def get_localized_field(field, label)
    if label.is_a?(Symbol)
      l(label)
    elsif label
      label
    elsif @object.class.respond_to?(:human_attribute_name)
      @object.class.human_attribute_name(field)
    else
      l(field)
    end
  end

  def field_has_errors?(field)
    @object&.errors&.include?(field)
  end

  def extract_from(options)
    label_options = options.dup.except(:class)
    input_options = options.dup.except(:for, :label, :no_label, :prefix, :suffix, :label_options)

    label_options.merge!(options.delete(:label_options) || {})

    if options[:suffix]
      options[:suffix_id] ||= SecureRandom.uuid

      input_options[:'aria-describedby'] ||= options[:suffix_id]
    end
    if options[:prefix]
      options[:prefix_id] ||= SecureRandom.uuid
    end

    [input_options, label_options]
  end

  def sanitized_object_name
    object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/, '_').sub(/_$/, '')
  end

  def title_from_context(method)
    if object.class.respond_to? :human_attribute_name
      object.class.human_attribute_name method
    else
      method.to_s.camelize
    end
  end
end
