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

class JobStatusesController < ApplicationController
  include OpTurbo::ComponentStream
  include OpTurbo::DialogStreamHelper

  no_authorization_required! :show, :dialog, :dialog_body
  before_action :validate_job, only: [:dialog_body]

  def show
    render layout: "angular/angular"
  end

  def dialog
    respond_with_dialog ::JobStatus::Dialog::DialogComponent.new(job_uuid: params[:job_uuid])
  end

  def dialog_body
    render ::JobStatus::Dialog::BodyComponent.new(job: @job), layout: false
  end

  private

  def validate_job
    @job = ::JobStatus::Status
             .find_by(job_id: params[:job_uuid], user_id: current_user.id)
  end
end
