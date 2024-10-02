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

require "active_job"

class ApplicationJob < ActiveJob::Base
  include ::JobStatus::ApplicationJobWithStatus
  include SharedJobSetup

  ##
  # Return a priority number on the given payload
  def self.priority_number(prio = :default)
    case prio
    when :high
      0
    when :notification
      5
    when :above_normal
      7
    when :below_normal
      13
    when :low
      20
    else
      10
    end
  end

  def self.queue_with_priority(value = :default)
    if value.is_a?(Symbol)
      super(priority_number(value))
    else
      super
    end
  end

  def job_scheduled_at
    GoodJob::Job.where(id: job_id).pick(:scheduled_at)
  end
end
