# frozen_string_literal: true

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

class OpenProject::JournalFormatter::FileLink < JournalFormatter::Base
  include OpenProject::ObjectLinking

  def render(key, values, options = { html: true })
    id = key.to_s.sub("file_links_", "").to_i
    label, old_value, value, storage = format_details(id, values)

    if options[:html]
      label, old_value, value = format_html_details(label, old_value, value)
      value = format_html_file_link_detail(id, value)
    end

    render_file_link_detail_text(label, value, old_value, storage)
  end

  private

  def format_details(id, values)
    old_value, current_value = values
    [
      label(nil),
      old_value&.fetch("link_name"),
      current_value&.fetch("link_name"),
      storage(id, old_value, current_value)
    ]
  end

  def storage(id, old, current)
    non_nil_value = [old, current].compact.first
    file_link = file_link_for(id, non_nil_value)

    non_nil_value["storage_name"] ||
    file_link&.storage&.name ||
    I18n.t("unknown_storage", scope: "my_account.access_tokens.storages")
  end

  def render_file_link_detail_text(label, value, old_value, storage)
    if value.blank?
      I18n.t(:text_journal_file_link_deleted, label:, old: old_value, storage:)
    else
      I18n.t(:text_journal_file_link_added, label:, value:, storage:)
    end
  end

  # Based this off the Attachment formatter. Not sure if it is the best approach
  def label(_key) = I18n.t("activerecord.models.file_link")

  def file_link_for(key, value)
    value.present? && ::Storages::FileLink.find_by(id: key)
  end

  def format_html_file_link_detail(key, value)
    if file_link = file_link_for(key, value)
      link_to_file_link(file_link, only_path: false)
    elsif value.present?
      value
    end
  end

  def link_to_file_link(file_link, options = {})
    text = options.delete(:text) || file_link.origin_name

    link_to text,
            url_to_file_link(file_link, only_path: options.delete(:only_path) { true }),
            options
  end
end
