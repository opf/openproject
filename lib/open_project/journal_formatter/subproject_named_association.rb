#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
class OpenProject::JournalFormatter::SubprojectNamedAssociation < JournalFormatter::NamedAssociation
  private

  def format_details(key, values, cache:)
    if values.first.nil?
      label = label(key)
    elsif values.last.nil?
      label = I18n.t("activerecord.attributes.project.parent_no_longer")
    else
      label = I18n.t("activerecord.attributes.project.parent_without_of")
    end

    old_value, value = *format_values(values, key, cache:)

    [label, old_value, value]
  end

  def render_ternary_detail_text(label, value, old_value, options)
    return I18n.t(:text_journal_deleted_custom_subproject, label:, old: old_value) if value.blank?
    return I18n.t(:text_journal_of, label:, value:) if old_value.blank?

    linebreak = should_linebreak?(old_value.to_s, value.to_s)

    if options[:html]
      I18n.t(:text_journal_changed_html,
             label:,
             linebreak: linebreak ? "<br/>".html_safe : '',
             old: old_value,
             new: value)
    else
      I18n.t(:text_journal_changed_plain,
             label:,
             linebreak: linebreak ? "\n" : '',
             old: old_value,
             new: value)
    end
  end
end
