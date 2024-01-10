# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module OAuth
  module Applications
    class RowComponent < ::RowComponent
      property :confidential

      def application
        model
      end

      def name
        link_to application.name, oauth_application_path(application)
      end

      def owner
        link_to application.owner.name, user_path(application.owner)
      end

      def confidential
        if application.confidential?
          helpers.op_icon 'icon icon-checkmark'
        end
      end

      def redirect_uri
        urls = application.redirect_uri.split("\n")
        safe_join urls, '<br/>'.html_safe
      end

      def client_credentials
        if user_id = application.client_credentials_user_id
          helpers.link_to_user User.find(user_id)
        else
          '-'
        end
      end

      def edit_link
        link_to(
          I18n.t(:button_edit),
          edit_oauth_application_path(application),
          class: "oauth-application--edit-link icon icon-edit"
        )
      end

      def button_links
        [edit_link, helpers.delete_link(oauth_application_path(application))]
      end
    end
  end
end
