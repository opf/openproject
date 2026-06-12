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

module Documents
  module VersionsTab
    class ItemComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      alias_method :journal, :model

      options :document, :max_version
      options active_journal_id: nil

      def author
        journal.user
      end

      def version_url
        if journal.version == max_version
          document_path(document, tab: :versions)
        else
          document_path(document, version: journal.id, tab: :versions)
        end
      end

      def content_changed?
        journal.version == 1 ||
          journal.details.key?("content_binary") ||
          journal.details.key?("description") ||
          restore_journal? ||
          (document.collaborative? && journal.data.content_binary.present?)
      end

      def restore_journal?
        journal.cause&.dig("type") == "document_version_restored"
      end

      # Simple text-only change descriptions (content, restored, etc.)
      def simple_changes
        return [I18n.t("documents.versions.created")] if journal.version == 1

        details = []
        details << I18n.t("documents.versions.content_updated") if journal.details.key?("content_binary")
        details << I18n.t("documents.versions.description_updated") if journal.details.key?("description")
        details << I18n.t("documents.versions.restored") if restore_journal?
        details
      end

      # Structured attribute changes with old/new values for title and type
      def attribute_changes
        changes = []

        if (title_vals = journal.details["title"])
          changes << { label: Document.human_attribute_name(:title), old: title_vals.first, new_val: title_vals.last }
        end

        if (type_vals = journal.details["type_id"])
          old_type = DocumentType.find_by(id: type_vals.first)
          new_type = DocumentType.find_by(id: type_vals.last)
          changes << { label: Document.human_attribute_name(:type_id), old: old_type&.name, new_val: new_type&.name }
        end

        changes
      end

      def format_attribute_change(label:, old:, new_val:)
        label_html = content_tag(:strong, label)
        if old.present? && new_val.present?
          safe_join([label_html, " changed from ", content_tag(:em, old), " to ", content_tag(:em, new_val)])
        elsif new_val.present?
          safe_join([label_html, " set to ", content_tag(:em, new_val)])
        elsif old.present?
          safe_join([label_html, " deleted (", content_tag(:em, old), ")"])
        end
      end
    end
  end
end
