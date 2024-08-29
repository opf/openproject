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

# Handles /api/v3/work_packages/:work_package_id/file_links as defined
# in modules/storages/lib/api/v3/file_links/work_packages_file_links_api.rb
#
# Multiple classes are involved during its lifecycle:
#   - Storages::Peripherals::ParseCreateParamsService
#   - API::V3::FileLinks::FileLinkCollectionRepresenter
#   - Storages::FileLinks::CreateService
#
# These classes are either deduced from the model class, or given as parameter
# on class instantiation.
class API::V3::FileLinks::CreateEndpoint < API::Utilities::Endpoints::Create
  include ::API::V3::Utilities::Endpoints::V3Deductions
  include ::API::V3::Utilities::Endpoints::V3PresentSingle

  # As this endpoint receives a list of file links to create, it calls the
  # create service multiple times, one time for each file link to create. The
  # call is done by calling the `super` method. Results are aggregated in
  # global_result using the `add_dependent!` method.
  def process(request, params_elements)
    global_result = ServiceResult.success

    Storages::FileLink.transaction do
      params_elements.each do |params|
        # call the default API::Utilities::Endpoints::Create#process
        # implementation for each of the params_element array
        one_result = super(request, params)
        # merge service result in one
        global_result.add_dependent!(one_result)
      end

      # rollback records created if an error occurred (validation failed)
      raise ActiveRecord::Rollback if global_result.failure?
    end

    global_result
  end

  def present_success(request, service_call)
    file_links = service_call.all_results.map do |file_link|
      file_link.origin_status = :view_allowed
      file_link
    end

    render_representer.create(
      file_links,
      self_link: self_link(request),
      current_user: request.current_user
    )
  end

  private

  def self_link(_request)
    "#{::API::V3::URN_PREFIX}file_links:no_link_provided"
  end
end
