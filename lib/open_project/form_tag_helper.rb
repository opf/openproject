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

module OpenProject
  module FormTagHelper
    include ActionView::Helpers::FormTagHelper

    TEXT_LIKE_FIELDS = [
      'number_field', 'password_field', 'url_field', 'telephone_field', 'email_field'
    ].freeze

    def styled_form_tag(url_for_options = {}, options = {}, &block)
      apply_css_class_to_options(options, 'form')
      form_tag(url_for_options, options, &block)
    end

    def styled_select_tag(name, styled_option_tags = nil, options = {})
      apply_css_class_to_options(options, 'form--select')
      wrap_field 'select', options do
        select_tag(name, styled_option_tags, options)
      end
    end

    def styled_text_field_tag(name, value = nil, options = {})
      apply_css_class_to_options(options, 'form--text-field')
      wrap_field 'text-field', options do
        text_field_tag(name, value, options)
      end
    end

    def styled_label_tag(name = nil, content_or_options = nil, options = {}, &block)
      apply_css_class_to_options(
        block_given? && content_or_options.is_a?(Hash) ? content_or_options : (options ||= {}),
        'form--label'
      )
      options[:title] ||= strip_tags(block_given? ? capture(&block) : content_or_options)
      label_tag(name, content_or_options, options, &block)
    end

    def styled_file_field_tag(name, options = {})
      apply_css_class_to_options(options, 'form--file-field')
      wrap_field 'file-field', options do
        file_field_tag(name, options)
      end
    end

    def styled_text_area_tag(name, content = nil, options = {})
      apply_css_class_to_options(options, 'form--text-area')
      wrap_field 'text-area', options do
        text_area_tag(name, content, options)
      end
    end

    def styled_check_box_tag(name, value = '1', checked = false, options = {})
      apply_css_class_to_options(options, 'form--check-box')
      wrap_field 'check-box', options do
        check_box_tag(name, value, checked, options)
      end
    end

    def styled_radio_button_tag(name, value, checked = false, options = {})
      apply_css_class_to_options(options, 'form--radio-button')
      wrap_field 'radio-button', options do
        radio_button_tag(name, value, checked, options)
      end
    end

    def styled_submit_tag(value = 'Save changes', options = {})
      apply_css_class_to_options(options, 'button')
      submit_tag(value, options)
    end

    def styled_button_tag(content_or_options = nil, options = nil, &block)
      apply_css_class_to_options(
        block_given? && content_or_options.is_a?(Hash) ? content_or_options : (options ||= {}),
        'button'
      )
      button_tag(content_or_options, options, &block)
    end

    def styled_field_set_tag(legend = nil, options = nil, &block)
      apply_css_class_to_options(options, 'form--fieldset')
      field_set_tag(legend, options, &block)
    end

    def styled_search_field_tag(name, value = nil, options = {})
      apply_css_class_to_options(options, 'form--search-field')
      wrap_field 'search-field', options do
        search_field_tag(name, value, options)
      end
    end

    TEXT_LIKE_FIELDS.each do |field|
      define_method :"styled_#{field}_tag" do |name, value = nil, options = {}|
        apply_css_class_to_options(options, "form--text-field -#{field.gsub(/_field$/, '')}")
        wrap_field field, options do
          __send__(:"#{field}_tag", name, value, options)
        end
      end
    end

    def styled_range_field_tag(name, value = nil, options = {})
      apply_css_class_to_options(options, 'form--range-field')
      wrap_field 'range-field', options do
        range_field_tag(name, value, options)
      end
    end

    private

    def wrap_field(name, options, &block)
      content_tag(:span, class: field_container_css_class(name, options), &block)
    end

    def apply_css_class_to_options(options, css_class)
      options[:class] = Array(options[:class]) + Array(css_class)
    end

    def field_container_css_class(selector, options)
      classes = if TEXT_LIKE_FIELDS.include?(selector)
                  'form--text-field-container'
                else
                  "form--#{selector.tr('_', '-')}-container"
                end

      classes << ' ' + options.fetch(:container_class, '')

      classes.strip
    end
  end
end
