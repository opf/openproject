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

  def initialize(object_name, object, template, options, proc)
    set_language_if_valid options.delete(:lang)
    super
  end

  (field_helpers - %w(radio_button hidden_field fields_for label) + %w(date_select)).each do |selector|
    src = <<-END_SRC
    def #{selector}(field, options = {})
      label_for_field(field, options) + super
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
