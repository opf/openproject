#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
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
    def #{selector}(field, options = {})
      if options.delete(:multi_locale)
        ret = label_for_field(field, options)

        if self.object.translations.length == 0
          locale = User.current.language.present? ? User.current.language : Setting.default_language

          self.object.translations.build :locale => locale
        end

        fields_for(:translations, :builder => ActionView::Helpers::FormBuilder) do |translation_form|
          ret.concat '<span class="translation ' + field.to_s + '_translation">'
          ret.concat translation_form.send(__method__, field, options)
          ret.concat translation_form.select :locale,
                                             Setting.available_languages.map { |lang| [ ll(lang.to_s, :general_lang_name), lang.to_sym ] },
                                             {},
                                             :class => 'locale_selector'
          ret.concat translation_form.hidden_field '_destroy',
                                             :disabled => true,
                                             :class => 'destroy_flag',
                                             :value => "1"
          ret.concat '<a href="#" class="destroy_locale icon icon-del" title="Delete"></a>'
          ret.concat "<br>"
          ret.concat "</span>"
        end

        new_translation = object.translation_class.new :locale => User.current.language.present? ? User.current.language : Setting.default_language

#        fields_for(:translations, new_translation, :builder => ActionView::Helpers::FormBuilder) do |translation_form|
#          ret.concat '<span class="backup_locale" style="display:none">'
#          ret.concat translation_form.send(__method__,
#                                           field,
#                                           options.merge({ :disabled => true }))
#          ret.concat translation_form.select :locale,
#                                             Setting.available_languages.map { |lang| [ ll(lang.to_s, :general_lang_name), lang.to_s ] },
#                                             {},
#                                             :disabled => true,
#                                             :class => 'locale_selector'
#          ret.concat '<br>'
#          ret.concat '</span>'
#
#        end
        ret.concat '<a href="#" class="add_locale">Add</a>'

        ret
      else
        label_for_field(field, options) + super
      end
    end
    END_SRC
    class_eval src, __FILE__, __LINE__
  end

  def select(field, choices, options = {}, html_options = {})
    label_for_field(field, options) + super
  end

  # Returns a label tag for the given field
  def label_for_field(field, options = {})
      return '' if options.delete(:no_label)
      text = options[:label].is_a?(Symbol) ? l(options[:label]) : options[:label]
      text ||= l(("field_" + field.to_s.gsub(/\_id$/, "")).to_sym)
      text += @template.content_tag("span", " *", :class => "required") if options.delete(:required)
      @template.label(@object_name, field.to_s, text,
                                     :class => (@object && @object.errors[field] ? "error" : nil))
  end
end
