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

class OpenProject::JournalFormatter::SubprojectNamedAssociation < JournalFormatter::NamedAssociation
  private

  def format_details(key, values, cache:)
    label = if values.first.nil?
              label(key)
            elsif values.last.nil?
              I18n.t("activity.item.parent_no_longer")
            else
              I18n.t("activity.item.parent_without_of")
            end

    old_value, value = *format_values(values, key, cache:)

    [label, old_value, value]
  end

  def format_html_details(label, old_value, value)
    label = content_tag(:strong, label)
    old_value = content_tag("i", h(old_value)) if old_value.present?
    value = content_tag("i", h(value)) if value.present?
    value ||= ""

    [label, old_value, value]
  end

  def render_ternary_detail_text(label, value, old_value, options)
    return I18n.t(:text_journal_deleted_subproject, label:, old: old_value) if value.blank?
    return I18n.t(:text_journal_of, label:, value:) if old_value.blank?

    super
  end
end
