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
    module Capabilities
      class CapabilitySqlRepresenter
        include API::Decorators::Sql::Hal
        include API::Decorators::Sql::HalAssociatedResource

        property :_type,
                 representation: ->(*) { "'Capability'" }

        property :id,
                 representation: ->(*) {
                   <<~SQL.squish
                     CASE
                     WHEN context_id IS NULL THEN action || '/g-' || principal_id
                     ELSE action || '/p' || context_id || '-' || principal_id
                     END
                   SQL
                 }

        link :self,
             path: { api: :capability, params: %w(action) },
             column: -> {
               <<~SQL.squish
                 CASE
                 WHEN context_id IS NULL THEN action || '/g-' || principal_id
                 ELSE action || '/p' || context_id || '-' || principal_id
                 END
               SQL
             },
             title: -> {}

        link :action,
             path: { api: :action, params: %w(action) },
             title: -> {}

        link :context,
             href: ->(*) {
               <<~SQL.squish
                 CASE
                 WHEN context_id IS NULL THEN '#{api_v3_paths.capabilities_contexts_global}'
                 ELSE format('#{api_v3_paths.project('%s')}', context_id)
                 END
               SQL
             },
             title: ->(*) {
               <<~SQL.squish
                 CASE
                 WHEN context_id IS NULL THEN '#{I18n.t('activerecord.errors.models.capability.context.global')}'
                 ELSE context_name
                 END
               SQL
             },
             join: { table: :projects,
                     condition: "contexts.id = capabilities.context_id",
                     select: ["contexts.name context_name"] }

        associated_user_link :principal
      end
    end
  end
end
