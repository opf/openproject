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

module ::Avatars
  class AvatarController < ::ApplicationController
    before_action :ensure_enabled
    before_action :find_avatar

    no_authorization_required! :show

    def show
      send_file @avatar.diskfile,
                filename: filename_for_content_disposition(@avatar.filename),
                type: @avatar.content_type,
                disposition: "inline"
    rescue StandardError => e
      Rails.logger.error "Failed to render avatar for #{@avatar&.id}: #{e.message}"
      head :not_found
    end

    def breadcrumb_items
      [{ href: admin_index_path, text: t("label_administration") },
       { href: admin_settings_users_path, text: t(:label_user_settings) },
       @plugin.name]
    end

    helper_method :breadcrumb_items

    private

    def find_avatar
      @avatar = User.get_local_avatar(params[:id])

      unless @avatar
        head :not_found
        false
      end
    end

    def ensure_enabled
      unless ::OpenProject::Avatars::AvatarManager.local_avatars_enabled?
        head :not_found
        false
      end
    end
  end
end
