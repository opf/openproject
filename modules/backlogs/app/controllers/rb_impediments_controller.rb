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

class RbImpedimentsController < RbApplicationController
  def create
    call = Impediments::CreateService
           .new(user: current_user)
           .call(attributes: impediment_params(Impediment.new).merge(project: @project))

    respond_with_impediment call
  end

  def update
    @impediment = Impediment.find(params[:id])

    call = Impediments::UpdateService
           .new(user: current_user, impediment: @impediment)
           .call(attributes: impediment_params(@impediment))

    respond_with_impediment call
  end

  private

  def respond_with_impediment(call)
    status = call.success? ? 200 : 400
    @impediment = call.result

    @include_meta = true

    respond_to do |format|
      format.html { render partial: "impediment", object: @impediment, status:, locals: { errors: call.errors } }
    end
  end

  def impediment_params(instance)
    # We do not need project_id, since ApplicationController will take care of
    # fetching the record.
    params.delete(:project_id)

    hash = params
           .permit(:version_id, :status_id, :id, :sprint_id,
                   :assigned_to_id, :remaining_hours, :subject, :blocks_ids)
           .to_h
           .symbolize_keys

    # We block block_ids only when user is not allowed to create or update the
    # instance passed.
    unless instance && ((instance.new_record? && User.current.allowed_in_project?(:add_work_packages,
                                                                                  @project)) || User.current.allowed_in_any_work_package?(
                                                                                    :edit_work_packages, in_project: @project
                                                                                  ))
      hash.delete(:block_ids)
    end

    hash
  end
end
