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
  module Admin
    module Settings
      class DocumentCollaborationSettingsController < ::Admin::SettingsController
        include OpTurbo::ComponentStream

        menu_item :document_collaboration_settings

        def create
          toggle_collaboration(enabled: true)
        end

        def delete_dialog
          respond_with_dialog Documents::Admin::CollaborationSettings::DisableTextCollaborationDialogComponent.new
        end

        def destroy
          toggle_collaboration(enabled: false)
        end

        private

        def failure_callback(call)
          @errors = call.errors
          render :show, status: :unprocessable_entity
        end

        def update_service
          Documents::Admin::Settings::CollaborationServerSettingsUpdateService
        end

        def toggle_collaboration(enabled:)
          call = update_service
            .new(user: current_user)
            .call(real_time_text_collaboration_enabled: enabled.to_s)

          if call.success?
            flash[:notice] = I18n.t(success_key_for(enabled))
          else
            flash[:error] = call.errors.full_messages.to_sentence
          end

          redirect_to action: :show
        end

        def success_key_for(enabled)
          base = "documents.admin"
          if enabled
            "#{base}.enable_text_collaboration.success"
          else
            "#{base}.disable_text_collaboration_dialog.success"
          end
        end
      end
    end
  end
end
