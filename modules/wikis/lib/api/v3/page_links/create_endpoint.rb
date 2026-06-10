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
    module PageLinks
      class CreateEndpoint < Utilities::Endpoints::Create
        include Utilities::Endpoints::V3Deductions
        include Utilities::Endpoints::V3PresentSingle

        def process(request, params)
          global_result = ServiceResult.success

          ::Wikis::PageLink.transaction do
            params.each do |attributes|
              global_result.add_dependent!(super(request, attributes))
            end

            raise ActiveRecord::Rollback if global_result.failure?
          end

          global_result
        end

        private

        def present_success(request, service_call)
          ids = service_call.all_results.map(&:id)

          render_representer.create(
            Wikis::PageLink.where(id: ids),
            self_link: self_link(request),
            current_user: request.current_user
          )
        end

        def dependent_error_subject(result) = result.identifier

        def self_link(*)
          "#{URN_PREFIX}wiki_page_links:no_link_provided"
        end
      end
    end
  end
end
