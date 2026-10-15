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

module Primer
  module OpenProject
    module Forms
      module Dsl
        class BlockNoteEditorInput < Primer::Forms::Dsl::Input
          attr_reader :name,
                      :label,
                      :value,
                      :readonly,
                      :classes,
                      :attachments_upload_url,
                      :attachments_collection_key,
                      :project_id

          ##
          # @param name [String] The name of the input field.
          # @param label [String] The label for the input field.
          # @param value [String] The initial value of the input in base64 format.
          # @param attachments_upload_url [String] The URL to which attachments will be uploaded.
          # @param attachments_collection_key [String] The collection key for attachments.
          # @param project_id [Integer] The project the edited document belongs to.
          def initialize(name:, label:, value:, readonly: false, attachments_upload_url: "", attachments_collection_key: "",
                         project_id: nil, **system_arguments)
            @name = name
            @label = label
            @value = value
            @readonly = readonly
            @classes = system_arguments[:classes]
            @attachments_upload_url = attachments_upload_url
            @attachments_collection_key = attachments_collection_key
            @project_id = project_id

            super(**system_arguments)
          end

          def to_component
            BlockNoteEditor.new(input: self, value:, readonly:, attachments_upload_url:, attachments_collection_key:,
                                project_id:)
          end

          def type
            :block_note_editor
          end

          def focusable?
            true
          end
        end
      end
    end
  end
end
