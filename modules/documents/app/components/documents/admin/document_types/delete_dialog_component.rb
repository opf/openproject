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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Documents
  module Admin
    module DocumentTypes
      class DeleteDialogComponent < ApplicationComponent
        include OpTurbo::Streamable

        alias_method :document_type, :model

        def danger_dialog(**system_args, &)
          Primer::OpenProject::DangerDialog.new(
            id: "delete-document-type-dialog",
            title: I18n.t("documents.delete_document_type_dialog.title"),
            confirm_button_text: I18n.t(:button_delete_permanently),
            **system_args,
            &
          )
        end

        def with_confirmation_message(dialog)
          dialog.with_confirmation_message do |message|
            message.with_heading(tag: :h2) { I18n.t("documents.delete_document_type_dialog.heading") }
            message.with_description_content(confirmation_message)
          end
        end

        def confirmation_message
          if document_type.in_use?
            count = document_type.documents.count
            I18n.t(
              "documents.delete_document_type_dialog.reassign_message",
              type_name: document_type.name,
              document_count: count,
              count:
            )
          else
            I18n.t(
              "documents.delete_document_type_dialog.confirmation_message",
              type_name: document_type.name
            )
          end
        end

        def other_document_types
          DocumentType.where.not(id: document_type.id).order(:position)
        end
      end
    end
  end
end
