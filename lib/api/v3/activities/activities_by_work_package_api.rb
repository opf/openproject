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

require "api/v3/activities/activity_representer"

module API
  module V3
    module Activities
      class ActivitiesByWorkPackageAPI < ::API::OpenProjectAPI
        resource :activities do
          get do
            self_link = api_v3_paths.work_package_activities @work_package.id
            journals = @work_package.journals.includes(:data,
                                                       :customizable_journals,
                                                       :attachable_journals,
                                                       :storable_journals,
                                                       :bcf_comment)

            Activities::ActivityCollectionRepresenter.new(journals,
                                                          self_link:,
                                                          current_user:)
          end

          params do
            requires :comment, type: Hash
          end
          post do
            authorize_in_work_package({ controller: :journals, action: :new }, work_package: @work_package) do
              raise ::API::Errors::NotFound.new
            end

            call = AddWorkPackageNoteService
                       .new(user: current_user,
                            work_package: @work_package)
                       .call(params[:comment][:raw],
                             send_notifications: !(params.has_key?(:notify) && params[:notify] == "false"))

            if call.success?
              Activities::ActivityRepresenter.new(call.result, current_user:)
            else
              fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
            end
          end
        end
      end
    end
  end
end
