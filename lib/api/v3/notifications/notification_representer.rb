#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
      class NotificationRepresenter < ::API::Decorators::Single
        include API::Decorators::DateProperty
        include API::Decorators::LinkedResource
        extend API::Decorators::PolymorphicResource

        self_link title_getter: ->(*) { represented.subject }

        property :id
        property :subject

        property :read_ian,
                 as: :readIAN

        property :reason

        date_time_property :created_at

        date_time_property :updated_at

        link :readIAN do
          next if represented.read_ian

          {
            href: api_v3_paths.notification_read_ian(represented.id),
            method: :post
          }
        end

        link :unreadIAN do
          next unless represented.read_ian

          {
            href: api_v3_paths.notification_unread_ian(represented.id),
            method: :post
          }
        end

        associated_resource :actor,
                            representer: ::API::V3::Users::UserRepresenter,
                            skip_render: ->(*) { represented.actor.nil? },
                            v3_path: :user

        associated_resource :project

        associated_resource :journal,
                            as: :activity,
                            representer: ::API::V3::Activities::ActivityRepresenter,
                            v3_path: :activity,
                            skip_render: ->(*) { represented.journal_id.nil? }

        polymorphic_resource :resource

        def _type
          'Notification'
        end

        self.to_eager_load = %i[project actor]
      end
    end
  end
end
