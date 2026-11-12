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

module API
  module V3
    module EmojiReactions
      class EmojiReactionRepresenter < ::API::Decorators::Single
        include API::Decorators::DateProperty
        include API::Decorators::LinkedResource

        def self.associated_reactable_getter
          ->(*) {
            next unless embed_links && reactable_representer

            reactable_representer
              .create(represented.reactable, current_user:)
          }
        end

        def self.associated_reactable_link
          ->(*) {
            return nil unless v3_reactable_name == "nil_class" || api_v3_paths.respond_to?(v3_reactable_name)

            ::API::Decorators::LinkObject
              .new(represented,
                   path: v3_reactable_name,
                   property_name: :reactable)
              .to_hash
          }
        end

        links :reactingUsers do
          represented.reacting_users.map do |(id, name)|
            {
              href: api_v3_paths.user(id),
              title: name
            }
          end
        end

        property :id,
                 exec_context: :decorator,
                 getter: ->(*) { "#{represented.reactable_id}-#{represented.reaction}" }
        property :reaction
        property :emoji
        property :reactions_count

        date_time_property :first_created_at, as: :firstReactionAt

        associated_resource :reactable,
                            getter: associated_reactable_getter,
                            link: associated_reactable_link

        def _type
          "EmojiReaction"
        end

        def reactable_representer
          name = v3_reactable_name.camelcase

          "::API::V3::#{name.pluralize}::#{name}Representer".constantize
        rescue NameError
          nil
        end

        def v3_reactable_name
          ar_name = represented.reactable_type.underscore

          ::API::Utilities::PropertyNameConverter.from_ar_name_with_aliases(ar_name, "journal" => "activity").underscore
        end
      end
    end
  end
end
