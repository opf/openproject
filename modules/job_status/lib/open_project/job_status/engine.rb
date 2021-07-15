#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'open_project/plugins'

module OpenProject::JobStatus
  class Engine < ::Rails::Engine
    engine_name :openproject_job_status

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-job_status',
             author_url: 'https://www.openproject.org',
             bundled: true

    add_api_endpoint 'API::V3::Root' do
      mount ::API::V3::JobStatus::JobStatusAPI
    end

    add_api_path :job_status do |uuid|
      "#{root}/job_statuses/#{uuid}"
    end

    initializer 'job_status.event_listener' do
      # Extends the ActiveJob adapter in use (DelayedJob) by a Status which lives
      # indenpendently from the job itself (which is deleted once successful or after max attempts).
      # That way, the result of a background job is available even after the original job is gone.
      EventListener.register!
    end

    config.to_prepare do
      # Register the cron job to clear statuses periodically
      ::Cron::CronJob.register! ::JobStatus::Cron::ClearOldJobStatusJob
    end
  end
end
