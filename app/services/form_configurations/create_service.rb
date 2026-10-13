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

module FormConfigurations
  class CreateService < ::BaseServices::Create
    protected

    def instance_class = FormConfiguration

    def default_contract_class = CreateContract

    def set_attributes_params(params) = super.except(:copy_from_id)

    def after_perform(service_call)
      source = FormConfiguration.find_by(id: params[:copy_from_id])
      return service_call if source.nil?

      copy_from(service_call.result, source)
    end

    private

    def copy_from(form, source)
      unless source.stored_attribute_groups.nil?
        groups = copied_groups(source)
        return groups if groups.failure?

        form.attribute_groups = groups.result
      end

      form.save ? ServiceResult.success(result: form) : ServiceResult.failure(result: form, errors: form.errors)
    end

    def copied_groups(source)
      groups = source.attribute_groups.map do |group|
        members = group.is_a?(Type::QueryGroup) ? copied_query(group) : group.attributes.dup
        return members if members.is_a?(ServiceResult)

        [group.key, members, group.display_name.presence].compact
      end

      ServiceResult.success(result: groups)
    end

    def copied_query(group)
      query = WorkPackageTypes::FormConfiguration::EmbeddedQueryBuilder.rebuild(query: group.query, user:)
      query.success? ? [query.result] : query
    end
  end
end
