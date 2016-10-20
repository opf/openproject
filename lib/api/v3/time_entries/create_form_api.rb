#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module TimeEntries
      class CreateFormAPI < ::API::OpenProjectAPI
        resource :form do
          post do
            time_entry = merge_hash_into_time_entry!(request_body, TimeEntry.new)
            time_entry = TimeEntry.new(user: current_user,
                                       project: work_package.project
                                       work_package: work_package,
                                       spend_on: User.current.today)

            create_time_entry_form(time_entry,
                                   form_class: CreateFormRepresenter,
                                   action: :create)
          end
        end

        private

        def merge_hash_into_time_entry!(hash, work_package)
          payload = ::API::V3::WorkPackages::WorkPackagePayloadRepresenter.create(work_package)
          payload.from_hash(hash)
        end

        def create_time_entry_form(time_entry, contract_class:, form_class:, action: :update)
          contract = contract_class.new(time_entry, 
                                        user: time_entry.user, 
                                        project: time_entry.project,
                                        work_package: time_entry.work_package,
                                        spend_on: User.current.today)
          contract.validate

          api_errors = ::API::Errors::ErrorBase.create_errors(contract.errors)

          # errors for invalid data (e.g. validation errors) are handled inside the form
          if only_validation_errors(api_errors)
            status 200
            form_class.new(time_entry,
                           current_user: current_user,
                           errors: api_errors,
                           action: action)
          else
            fail ::API::Errors::MultipleErrors.create_if_many(api_errors)
          end
        end
      end
    end
  end
end




















  def create
    @time_entry ||= TimeEntry.new(project: @project, work_package: @issue, user: User.current, spent_on: User.current.today)
    @time_entry.attributes = permitted_params.time_entry

    call_hook(:controller_timelog_edit_before_save,  params: params, time_entry: @time_entry)

    if @time_entry.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default action: 'index', project_id: @time_entry.project
        end
      end
    else
      respond_to do |format|
        format.html do
          render action: 'edit'
        end
      end
    end
  end
