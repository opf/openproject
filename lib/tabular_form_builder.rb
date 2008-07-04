# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

require 'action_view/helpers/form_helper'

class TabularFormBuilder < ActionView::Helpers::FormBuilder
  include GLoc
  
  def initialize(object_name, object, template, options, proc)
    set_language_if_valid options.delete(:lang)
    super
  end      
      
  (field_helpers - %w(radio_button hidden_field) + %w(date_select)).each do |selector|
    src = <<-END_SRC
    def #{selector}(field, options = {}) 
      return super if options.delete :no_label
      label_text = l(options[:label]) if options[:label]
      label_text ||= l(("field_"+field.to_s.gsub(/\_id$/, "")).to_sym)
      label_text << @template.content_tag("span", " *", :class => "required") if options.delete(:required)
      label = @template.content_tag("label", label_text, 
                    :class => (@object && @object.errors[field] ? "error" : nil), 
                    :for => (@object_name.to_s + "_" + field.to_s))
      label + super
    end
    END_SRC
    class_eval src, __FILE__, __LINE__
  end
  
  def select(field, choices, options = {}, html_options = {}) 
    label_text = l(("field_"+field.to_s.gsub(/\_id$/, "")).to_sym) + (options.delete(:required) ? @template.content_tag("span", " *", :class => "required"): "")
    label = @template.content_tag("label", label_text, 
                  :class => (@object && @object.errors[field] ? "error" : nil), 
                  :for => (@object_name.to_s + "_" + field.to_s))
    label + super
  end
end
