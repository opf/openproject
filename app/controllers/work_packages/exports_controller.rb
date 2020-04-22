#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class WorkPackages::ExportsController < ApplicationController
  self._model_object = WorkPackages::Export

  before_action :find_model_object,
                :authorize_current_user

  before_action :find_job_status, only: :status

  def show
    if @export.ready?
      redirect_to attachment_content_path
    else
      headers['Link'] = "<#{status_work_packages_export_path(@export.id, format: :json)}> rel=\"status\""
      head 202
    end
  end

  def status
    if @job_status.success?
      headers['Link'] = "<#{attachment_content_path}> rel=\"download\""
    end

    respond_to do |format|
      format.json do
        render json: status_json_body(@job_status),
               status: 200
      end
    end
  end

  private

  def status_json_body(job)
    body = { status: job_status(job), message: job.message }

    if job.success?
      body[:link] = attachment_content_path
    end

    body
  end

  def job_status(job)
    if job.success?
      'Completed'
    elsif job.failure? || job.error?
      'Error'
    else
      'Processing'
    end
  end

  def authorize_current_user
    deny_access(not_found: true) unless @export.visible?(current_user)
  end

  def attachment_content_path
    # Not including the API PathHelper here as it messes up error rendering probably due to it
    # including the url helper again.
    ::API::V3::Utilities::PathHelper::ApiV3Path.attachment_content(@export.attachments.first.id)
  end

  def find_job_status
    @job_status = Delayed::Job::Status.of_reference(@export).first
  end
end
