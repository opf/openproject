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

module WorkPackageTypes
  module FormConfigurationGroups
    class CreateService < ::BaseServices::BaseCallable
      include ::WorkPackageTypes::FormConfiguration::Concern

      def perform
        name = resolve_group_name

        if query_group?
          query_call = build_query(params[:query_props], name: "Embedded table: #{name}")
          return query_call if query_call.failure?
        end

        group = build_group(name, query_result: query_call&.result)

        groups = active_groups
        groups.unshift(group)

        persist_groups(groups).tap do |call|
          call.result = group if call.success?
        end
      end

      private

      def resolve_group_name
        name = params[:name].to_s.strip
        return name if name.present?

        seen_keys = active_groups.map { |g| g.key.to_s }
        Type::FormGroup.next_untitled_key(seen_keys)
      end

      def query_group?
        params[:group_type].to_s == "query"
      end

      def build_group(name, query_result: nil)
        if query_result
          ::Type::QueryGroup.new(type, name, query_result)
        else
          ::Type::AttributeGroup.new(type, name, [])
        end
      end
    end
  end
end
