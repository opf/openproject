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

module JobStatus
  module ApplicationJobWithStatus
    # Delayed jobs can have a status:
    # Delayed::Job::Status
    # which is related to the job via a reference which is an AR model instance.
    def status_reference
      nil
    end

    ##
    # Determine whether to store a status object for this job
    # By default, will only store if status_reference is present
    def store_status?
      !status_reference.nil?
    end

    ##
    # For more complex handling of status updates
    # jobs can do success messages themselves.
    #
    # In case of exceptions being caught by activejob
    # the status will be modified outside.
    def updates_own_status?
      false
    end

    protected

    ##
    # Crafts a payload for a redirection result
    def redirect_payload(path)
      { redirect: path }
    end

    ##
    # Crafts a payload for a download result
    def download_payload(path)
      { download: path }
    end

    ##
    # Updates the associated status object
    def update_status(**args)
      ::JobStatus::Status
        .where(job_id: job_id)
        .update_all(args)
    end
  end
end
