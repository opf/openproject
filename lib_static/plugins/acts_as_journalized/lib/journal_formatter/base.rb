#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

module JournalFormatter
  class Base
    include Redmine::I18n
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TextHelper
    include Rails.application.routes.url_helpers
    include ERB::Util

    # We break the values between from and to values
    # in the formatter if the length of one of the values
    # exceeds this magic number of characters
    LINEBREAK_ON_VALUE_LENGTH = 100

    def initialize(journal)
      @journal = journal
    end

    def render(key, values, options = { html: true })
      label, old_value, value = format_details(key, values)

      if options[:html]
        label, old_value, value = *format_html_details(label, old_value, value)
      end

      render_ternary_detail_text(label, value, old_value, options)
    end

    private

    def format_details(key, values, _options = {})
      label = label(key)

      old_value = values.first
      value = values.last

      [label, old_value, value]
    end

    def format_html_details(label, old_value, value)
      label = content_tag(:strong, label)
      old_value = content_tag("i", h(old_value)) if old_value.present?
      old_value = content_tag("strike", old_value) if old_value and value.blank?
      value = content_tag("i", h(value)) if value.present?
      value ||= ""

      [label, old_value, value]
    end

    def label(key)
      @journal.journable.class.human_attribute_name(key)
    end

    def render_ternary_detail_text(label, value, old_value, options)
      return I18n.t(:text_journal_deleted, label:, old: old_value) if value.blank?
      return I18n.t(:text_journal_set_to, label:, value:) if old_value.blank?

      if should_linebreak?(old_value.to_s, value.to_s)
        linebreak = options[:html] ? "<br/>".html_safe : "\n"
      end

      I18n.t(:text_journal_changed_plain,
             label:,
             linebreak:,
             old: old_value,
             new: value)
    end

    def render_binary_detail_text(label, value, old_value)
      if value.blank?
        I18n.t(:text_journal_deleted, label:, old: old_value)
      else
        I18n.t(:text_journal_added, label:, value:)
      end
    end

    def should_linebreak?(old_value, new_value)
      [old_value, new_value].any? do |val|
        val.length >= LINEBREAK_ON_VALUE_LENGTH
      end
    end
  end
end
