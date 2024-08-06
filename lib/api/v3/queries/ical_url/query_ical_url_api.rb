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

require "api/v3/queries/ical_url/query_ical_url_representer"

module API
  module V3
    module Queries
      module ICalUrl
        # API inflection rule prevents ICal inflection rule to be used in this context
        class QueryIcalUrlAPI < ::API::OpenProjectAPI
          namespace :ical_url do
            before do
              raise API::Errors::Unauthorized unless Setting.ical_enabled?
            end

            params do
              requires :token_name, type: String, desc: "The name which should be used for the ical token"
            end

            post do
              authorize_by_policy(:share_via_ical)

              call = ::Calendar::GenerateICalUrlService.new.call(
                user: current_user,
                query_id: @query.id,
                project_id: @query.project_id,
                token_name: params[:token_name]
              )

              if call.failure?
                fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
              end

              status 201

              ical_url_data = Struct.new(:ical_url, :query)

              QueryICalUrlRepresenter.new(
                ical_url_data.new(call.result, @query),
                current_user:
              )
            end
          end
        end
      end
    end
  end
end
