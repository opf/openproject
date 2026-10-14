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

module API
  module V3
    module Notifications
      # Reduced representation of a notification returned to the user creating it
      # (POST /api/v3/notifications), e.g. when mentioning someone in a document.
      #
      # The notification belongs to its recipient, not to the creating user. The full
      # NotificationRepresenter would therefore advertise links the creator cannot follow:
      # the self link (GET /api/v3/notifications/:id is scoped to the recipient and 404s
      # for anyone else) as well as the readIAN/unreadIAN actions. This representer only
      # renders the id and the links to the resource and the recipient, both of which the
      # creator is allowed to see. Nothing is embedded.
      class NotificationCreatedRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource
        extend API::Decorators::PolymorphicResource

        property :id

        polymorphic_resource :resource,
                             link_title_attribute: :title

        associated_resource :recipient,
                            representer: ::API::V3::Users::UserRepresenter,
                            v3_path: :user

        def _type
          "Notification"
        end
      end
    end
  end
end
