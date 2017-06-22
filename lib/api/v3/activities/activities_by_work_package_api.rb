#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'api/v3/activities/activity_representer'

module API
  module V3
    module Activities
      class ActivitiesByWorkPackageAPI < ::API::OpenProjectAPI
        resource :activities do
          helpers do
            def comment_on_work_package(work_package, notify:, comment:)
              result = AddWorkPackageNoteService
                       .new(user: current_user,
                            work_package: work_package)
                       .call(comment,
                             send_notifications: notify)

              if result.success?
                journals = ::Journal::AggregatedJournal.aggregated_journals(journable: work_package)
                Activities::ActivityRepresenter.new(journals.last, current_user: current_user)
              else
                fail ::API::Errors::ErrorBase.create_and_merge_errors(result.errors)
              end
            end
          end

          get do
            @activities = ::Journal::AggregatedJournal
                          .aggregated_journals(journable: @work_package,
                                               includes: %i(
                                                 customizable_journals
                                                 attachable_journals
                                                 data
                                               ))
            self_link = api_v3_paths.work_package_activities @work_package.id
            Activities::ActivityCollectionRepresenter.new(@activities,
                                                          self_link,
                                                          current_user: current_user)
          end

          params do
            requires :comment, type: Hash
          end
          post do
            authorize({ controller: :journals, action: :new }, context: @work_package.project) do
              raise ::API::Errors::NotFound.new
            end

            comment_on_work_package(
              @work_package,
              notify: !(params.has_key?(:notify) && params[:notify] == 'false'),
              comment: params[:comment][:raw]
            )
          end
        end
      end
    end
  end
end
