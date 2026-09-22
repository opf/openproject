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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module API
  module V3
    module HourlyRates
      class HourlyRateRepresenter < ::API::Decorators::Single
        include ::API::Decorators::DateProperty
        include ::API::Decorators::LinkedResource

        link :self do
          {
            href: api_v3_paths.hourly_rate(represented.user_id, represented.id)
          }
        end

        # Rendered rather than parsed: the principal comes from the url the
        # collection hangs off. There is no /principals/:id resource, so the
        # link resolves to the concrete type.
        link :principal do
          {
            href: api_v3_paths.send(::API::V3::Principals::PrincipalType.for(represented.principal),
                                    represented.user_id),
            title: represented.principal&.name
          }
        end

        # A rate without a project is the principal's default rate, applying
        # wherever no project rate does. The link's absence is what tells the
        # two apart.
        associated_resource :project,
                            skip_render: ->(*) { represented.project_id.blank? }

        property :id

        date_property :valid_from

        property :rate,
                 exec_context: :decorator,
                 getter: ->(*) { represented.rate&.to_f },
                 setter: ->(fragment:, represented:, **) { represented.rate = fragment }

        def _type
          "HourlyRate"
        end
      end
    end
  end
end
