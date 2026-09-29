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
  class BlockNoteEditorForm < ApplicationForm
    form do |f|
      f.block_note_editor(
        name: :content_binary,
        label: I18n.t("label_document_description"),
        readonly: readonly,
        visually_hide_label: true,
        value: model.content_binary,
        attachments_upload_url:,
        attachments_collection_key:,
        project_id: model.project_id
      )
    end

    attr_reader :token_payload, :readonly

    def initialize(token_payload: nil, readonly: false)
      super()
      @token_payload = token_payload
      @readonly = readonly
    end

    private

    def attachments_upload_url
      if OpenProject::Configuration.direct_uploads?
        ::API::V3::Utilities::PathHelper::ApiV3Path.prepare_attachments_by_document(model.id)
      else
        ::API::V3::Utilities::PathHelper::ApiV3Path.attachments_by_document(model.id)
      end
    end

    def attachments_collection_key
      ::API::V3::Utilities::PathHelper::ApiV3Path.attachments_by_document(model.id)
    end
  end
end
