#-- encoding: UTF-8
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

# Does NOT inherit from ApplicationController by design
# so we're free from any before_actions
class HealthCheckController < ActionController::Base
  ##
  # perform a check select on the database and return with HTTP 200 if it
  # succeeded or HTTP 500 if it failed for some reason
  def application
    send_db_ping
    render text: 'ALIVE', status: 200
  rescue => e
    Rails.logger.error "Error during health check: #{e}"
    render text: 'ERROR', status: 500
  end

  ##
  # perform a check to determine whether any delayed jobs are not being run
  def delayed_jobs
    never_ran = Delayed::Job.where('run_at <= ?', 5.minutes.ago).count

    if never_ran > 0
      render text: "#{never_ran} delayed jobs were never executed.", status: 500
    else
      render nothing: true, status: 200
    end
  rescue => e
    Rails.logger.error "Error during delayed_job health check: #{e}"
    render text: 'Internal error', status: 500
  end

  # Do not log the checks into the default log.
  def logger
    @logger ||= Logger.new(StringIO.new)
  end

  # Simplest database alive check
  def send_db_ping
    ActiveRecord::Base.connection.execute('SELECT 1;')
  end
end
