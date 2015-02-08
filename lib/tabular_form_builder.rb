#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'action_view/helpers/form_helper'

class TabularFormBuilder < ActionView::Helpers::FormBuilder
  include Redmine::I18n
  include ActionView::Helpers::AssetTagHelper

  def initialize(object_name, object, template, options, proc)
    set_language_if_valid options.delete(:lang)
    super
  end

  (field_helpers - %w(radio_button hidden_field fields_for label) + %w(date_select)).each do |selector|
    src = <<-END_SRC
    def #{selector}(field, options = {}, *args)
      if options[:multi_locale] || options[:single_locale]
        localize_field(field, options, __method__)
      else
        options[:class] = Array(options[:class]) + [ field_css_class('#{selector}') ]

        (label_for_field(field, options) + container_wrap_field(super, '#{selector}', options)).html_safe
      end
    end
    END_SRC
    class_eval src, __FILE__, __LINE__
  end

  def select(field, choices, options = {}, html_options = {})
    html_options[:class] = Array(html_options[:class]) + %w(form--select)

    label_for_field(field, options) + container_wrap_field(super, 'select', options)
  end

  def collection_select(field, collection, value_method, text_method, options = {}, html_options = {})
    html_options[:class] = Array(html_options[:class]) + %w(form--select)

    label_for_field(field, options) + container_wrap_field(super, 'select', options)
  end

  def collection_check_box(field,
                           value,
                           checked,
                           text = field.to_s + "_#{value}",
                           options = {})

    label_options = options.reverse_merge(label: text)

    label_for = "#{field}_#{value}".to_sym
    label = label_for_field(label_for, label_options)

    input_options = options.merge(multiple: true, no_label: true, checked: checked)
    input = check_box(field, input_options, value, '')

    label + container_wrap_field(input, 'check-box', options)
  end

  # Return custom field html tag corresponding to its format
  def custom_field(options = {})
    input = custom_field_input(options)

    if options[:no_label]
      input
    else
      label = custom_field_label_tag
      container_options = options.merge(no_label: true)

      label + container_wrap_field(input, 'field', container_options)
    end
  end

  private

  attr_reader :template

  TEXT_LIKE_FIELDS = [
    'number_field', 'password_field', 'url_field', 'telephone_field', 'email_field'
  ].freeze

  def container_wrap_field(field_html, selector, options = {})
    ret = content_tag(:span, field_html, class: field_container_css_class(selector))
    ret = content_tag(:span, ret, class: 'form--field-container') unless options[:no_label]

    ret
  end

  def localize_field(field, options, meth)
    localized_field = Proc.new do |translation_form, multiple|
      localized_field(translation_form, meth, field, options)
    end

    ret = nil

    translation_objects = translation_objects field, options

    fields_for(:translations, translation_objects, builder: TabularFormBuilder) do |translation_form|
      ret = label_for_field(field, options, translation_form) unless ret

      ret.concat localized_field.call(translation_form)
    end

    if options[:multi_locale]
      ret.concat add_localization_link
    end

    ret
  end

  def field_container_css_class(selector)
    if TEXT_LIKE_FIELDS.include?(selector)
      'form--text-field-container'
    else
      "form--#{selector.tr('_', '-')}-container"
    end
  end

  def field_css_class(selector)
    if TEXT_LIKE_FIELDS.include?(selector)
      "form--text-field -#{selector.gsub(/_field$/, '')}"
    else
      "form--#{selector.tr('_', '-')}"
    end
  end

  # Returns a label tag for the given field
  def label_for_field(field, options = {}, translation_form = nil)
    options = options.dup
    return '' if options.delete(:no_label)
    text = options[:label].is_a?(Symbol) ? l(options[:label]) : options[:label]
    text ||= @object.class.human_attribute_name(field.to_sym) if @object.is_a?(ActiveRecord::Base)
    text += @template.content_tag('span', ' *', class: 'required') if options.delete(:required)

    id = element_id(translation_form) if translation_form

    label_options = { class: '' }
    # FIXME: reenable the error handling
    label_options[:class] << 'error' if false && @object && @object.respond_to?(:errors) && @object.errors[field] # FIXME
    label_options[:class] << 'form--label'
    label_options[:for] = id.sub(/\_id$/, "_#{field}") if options[:multi_locale] && id

    @template.label(@object_name, field.to_s, text.html_safe, label_options)
  end

  def element_id(translation_form)
    match = /id=\"(?<id>\w+)"/.match(translation_form.hidden_field :id)
    match ? match[:id] : nil
  end

  def custom_field_input(options = {})
    field = :value

    input_options = options.merge(no_label: true,
                                  name: custom_field_field_name,
                                  id: custom_field_field_id)

    field_format = Redmine::CustomFieldFormat.find_by_name(object.custom_field.field_format)

    case field_format.try(:edit_as)
    when 'date'
      text_field(field, input_options) +
        template.calendar_for(custom_field_field_id)
    when 'text'
      text_area(field, input_options.merge(rows: 3))
    when 'bool'
      check_box(field, input_options)
    when 'list'
      custom_field_input_list(field, input_options)
    else
      text_field(field, input_options)
    end
  end

  def custom_field_input_list(field, input_options)
    select_options = { no_label: true }
    is_required = object.custom_field.is_required?
    default_value = object.custom_field.default_value
    possible_options = object.custom_field.possible_values_options(object.customized)

    if is_required && default_value.blank?
      select_options[:prompt] = "--- #{l(:actionview_instancetag_blank_option)} ---"
    elsif !is_required
      select_options[:include_blank] = true
    end

    selectable_options = template.options_for_select(possible_options, object.value)

    select(field, selectable_options, select_options, input_options).html_safe
  end

  def custom_field_field_name
    "#{object_name}[#{ object.custom_field.id }]"
  end

  def custom_field_field_id
    "#{object_name}_#{ object.custom_field.id }".gsub(/[\[\]]/, '_')
  end

  # Return custom field label tag
  def custom_field_label_tag
    custom_value = object

    classes = 'form--label'
    classes << ' error' unless custom_value.errors.empty?

    content_tag 'label',
                custom_value.custom_field.name,
                for: custom_field_field_id,
                class: classes,
                lang: custom_value.custom_field.name_locale
  end

  def localized_field(translation_form, method, field, options)
    @template.content_tag :span, class: "form--field-container translation #{field}_translation" do
      ret = ''.html_safe

      field_options = localized_options options, translation_form.object.locale

      ret.safe_concat translation_form.send(method, field, field_options.merge(no_label: true))
      ret.safe_concat translation_form.hidden_field :id,
                                                    class: 'translation_id'
      if options[:multi_locale]
        ret.safe_concat translation_form.select :locale,
                                                Setting.available_languages.map { |lang| [ll(lang.to_s, :general_lang_name), lang.to_sym] },
                                                { no_label: true },
                                                class: 'locale_selector'
        ret.safe_concat translation_form.hidden_field '_destroy',
                                                      disabled: true,
                                                      class: 'destroy_flag',
                                                      value: '1'
        ret.safe_concat '<a href="#" class="destroy_locale icon icon-delete" title="Delete"></a>'
      else
        ret.safe_concat translation_form.hidden_field :locale,
                                                      class: 'locale_selector'
      end

      ret
    end
  end

  def translation_objects(field, options)
    if options[:multi_locale]
      multi_translation_object field, options
    elsif options[:single_locale]
      single_translation_object field, options
    end
  end

  def single_translation_object(_field, _options)
    if object.translations.detect { |t| t.locale == :en }.nil?
      object.translations.build locale: :en
    end

    object.translations.select { |t| t.locale == :en }
  end

  def multi_translation_object(field, _options)
    if object.translations.size == 0
      object.translations.build locale: user_locale
      object.translations
    else
      translations = object.translations.select do |t|
        t.send(field).present?
      end

      if translations.size > 0
        translations
      else
        object.translations.detect { |t| t.locale == user_locale } ||
          object.translations.first
      end

    end
  end

  def add_localization_link
    @template.content_tag :a, l(:button_add), href: '#', class: 'form--field-extra-actions add_locale'
  end

  def localized_options(options, locale = :en)
    localized_options = options.clone
    localized_options[:value] = localized_options[:value][locale] if options[:value].is_a?(Hash)
    localized_options.delete(:single_locale)
    localized_options.delete(:multi_locale)

    localized_options
  end

  def user_locale
    User.current.language.present? ?
      User.current.language.to_sym :
      Setting.default_language.to_sym
  end
end
