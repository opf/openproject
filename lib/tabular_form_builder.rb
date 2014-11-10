#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

  def initialize(object_name, object, template, options)
    set_language_if_valid options.delete(:lang)
    super
  end

  (field_helpers - %i(radio_button hidden_field fields_for label) + %i(date_select)).each do |selector|
    src = <<-END_SRC
    def #{selector}(field, options = {})
      if options[:multi_locale] || options[:single_locale]
        localized_field = Proc.new do |translation_form, multiple|
          localized_field(translation_form, __method__, field, options)
        end

        ret = nil

        translation_objects = translation_objects field, options

        fields_for(:translations, translation_objects, :builder => ActionView::Helpers::FormBuilder) do |translation_form|
          ret = label_for_field(field, options, translation_form) unless ret

          ret.concat localized_field.call(translation_form)
        end

        if options[:multi_locale]
          ret.concat add_localization_link
        end

        ret
      else
        (label_for_field(field, options) + super).html_safe
      end
    end
    END_SRC
    class_eval src, __FILE__, __LINE__
  end

  def select(field, choices, options = {}, html_options = {})
    label_for_field(field, options) + super
  end

  def collection_select(field, collection, value_method, text_method, options = {}, html_options = {})
    label_for_field(field, options) + super
  end

  private

  # Returns a label tag for the given field
  def label_for_field(field, options = {}, translation_form = nil)
    return '' if options.delete(:no_label)
    text = options[:label].is_a?(Symbol) ? l(options[:label]) : options[:label]
    text ||= @object.class.human_attribute_name(field.to_sym) if @object.is_a?(ActiveRecord::Base)
    text += @template.content_tag('span', ' *', class: 'required') if options.delete(:required)

    id = element_id(translation_form) if translation_form
    label_options = { class: (@object && @object.errors[field] ? 'error' : nil) }
    label_options[:for] = id.sub(/\_id$/, "_#{field}") if options[:multi_locale] && id

    @template.label(@object_name, field.to_s, text.html_safe, label_options)
  end

  def element_id(translation_form)
    match = /id=\"(?<id>\w+)"/.match(translation_form.hidden_field :id)
    match ? match[:id] : nil
  end

  def localized_field(translation_form, method, field, options)
    @template.content_tag :span, class: "translation #{field}_translation" do
      ret = ''.html_safe

      field_options = localized_options options, translation_form.object.locale

      ret.safe_concat translation_form.send(method, field, field_options)
      ret.safe_concat translation_form.hidden_field :id,
                                                    class: 'translation_id'
      if options[:multi_locale]
        ret.safe_concat translation_form.select :locale,
                                                Setting.available_languages.map { |lang| [ll(lang.to_s, :general_lang_name), lang.to_sym] },
                                                {},
                                                class: 'locale_selector'
        ret.safe_concat translation_form.hidden_field '_destroy',
                                                      disabled: true,
                                                      class: 'destroy_flag',
                                                      value: '1'
        ret.safe_concat '<a href="#" class="destroy_locale icon icon-delete" title="Delete"></a>'
        ret.safe_concat('<br>')
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
    @template.content_tag :a, l(:button_add), href: '#', class: 'add_locale'
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
