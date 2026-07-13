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

module GitlabIntegration
  module Admin
    class SettingsForm < ApplicationForm
      form do |f|
        f.autocompleter(
          name: :gitlab_user_id,
          label: I18n.t(:label_gitlab_actor),
          caption: I18n.t(:text_gitlab_actor_info),
          autocomplete_options: {
            component: "opce-user-autocompleter",
            allowEmpty: true,
            defaultData: false,
            model: @comment_user_model
          }
        )

        f.text_field(
          name: :webhook_secret,
          label: I18n.t(:label_gitlab_webhook_secret),
          caption: I18n.t(:text_gitlab_webhook_secret_info),
          value: @webhook_secret,
          input_width: :xxlarge
        )

        f.submit(
          name: :submit,
          label: I18n.t(:button_save),
          scheme: :primary
        )
      end

      def initialize(comment_user: nil, webhook_secret: nil)
        super()
        @comment_user_model = comment_user.present? ? { id: comment_user.id, name: comment_user.name } : nil
        @webhook_secret = webhook_secret
      end
    end
  end
end
