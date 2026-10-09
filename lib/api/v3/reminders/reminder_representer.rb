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

module API
  module V3
    module Reminders
      class ReminderRepresenter < ::API::Decorators::Single
        include API::Decorators::DateProperty
        include API::Decorators::LinkedResource

        def self.associated_remindable_getter
          ->(*) {
            next unless embed_links && remindable_representer

            remindable_representer
              .create(represented.remindable, current_user:)
          }
        end

        def self.associated_remindable_link
          ->(*) {
            return nil unless v3_remindable_name == "nil_class" || api_v3_paths.respond_to?(v3_remindable_name)

            ::API::Decorators::LinkObject
              .new(represented,
                   path: v3_remindable_name,
                   property_name: :remindable)
              .to_hash
          }
        end

        link :self do
          { href: api_v3_paths.reminder(represented.id) }
        end

        property :id

        date_time_property :remind_at

        property :note

        associated_resource :creator,
                            v3_path: :user,
                            representer: ::API::V3::Users::UserRepresenter

        associated_resource :remindable,
                            getter: associated_remindable_getter,
                            link: associated_remindable_link

        def _type
          "Reminder"
        end

        def remindable_representer
          name = v3_remindable_name.camelcase

          "::API::V3::#{name.pluralize}::#{name}Representer".constantize
        rescue NameError
          nil
        end

        def v3_remindable_name
          ar_name = represented.remindable_type.underscore

          ::API::Utilities::PropertyNameConverter.from_ar_name(ar_name).underscore
        end
      end
    end
  end
end
