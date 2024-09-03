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

class SendCopyProjectStatusEmailJob < ApplicationJob
  # Job is to be used as a callback to the CopyProjectJob batch

  def perform(batch, _args)
    if copy_job_succeeded?(batch) && batch.properties[:target_project]
      send_success_email(batch)
    else
      send_failure_email(batch)
    end
  end

  private

  def copy_job_succeeded?(batch)
    job = batch.active_jobs.find { |batch_job| batch_job.instance_of?(CopyProjectJob) }

    job.job_status.success?
  end

  def send_failure_email(batch)
    ProjectMailer.copy_project_failed(
      batch.properties[:user],
      batch.properties[:source_project],
      batch.properties[:target_project_name],
      batch.properties[:errors]
    ).deliver_later
  end

  def send_success_email(batch)
    ProjectMailer.copy_project_succeeded(
      batch.properties[:user],
      batch.properties[:source_project],
      batch.properties[:target_project],
      batch.properties[:errors]
    ).deliver_later
  end
end
