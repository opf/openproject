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

module Actions::Scopes
  module Default
    extend ActiveSupport::Concern

    class_methods do
      def default
        RequestStore[:action_default_scope] ||= begin
          actions_sql = <<~SQL.squish
            (SELECT id, permission, global, module, grant_to_admin, public
             FROM (VALUES #{action_map}) AS t(id, permission, global, module, grant_to_admin, public)) actions
          SQL

          unscoped # prevent triggering the default scope again
            .select('actions.*')
            .from(actions_sql)
        end
      end

      private

      def action_map
        OpenProject::AccessControl
          .contract_actions_map
          .map { |permission, v| map_actions(permission, **v) }
          .flatten
          .join(', ')
      end

      def map_actions(permission, actions:, global:, module_name:, grant_to_admin:, public:)
        actions.map do |namespace, actions|
          actions.map do |action|
            values = [
              quote_string("#{action_v3_name(namespace)}/#{action}"),
              quote_string(permission),
              global,
              module_name ? quote_string(module_name) : 'NULL',
              grant_to_admin,
              public
            ].join(', ')

            "(#{values})"
          end
        end
      end

      def action_v3_name(name)
        API::Utilities::PropertyNameConverter.from_ar_name(name.to_s.singularize).pluralize.underscore
      end

      def quote_string(string)
        ActiveRecord::Base.connection.quote(string.to_s)
      end
    end
  end
end
