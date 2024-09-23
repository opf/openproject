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
module JobStatus
  module ApplicationJobWithStatus
    # Background jobs can have a status JobStatus::Status
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

    ##
    # Get the current status object, if any
    def job_status
      ::JobStatus::Status
        .find_by(job_id:)
    end

    ##
    # Update the status code for a given job
    def upsert_status(status:, **args)
      resource = ::JobStatus::Status.find_or_initialize_by(job_id:)

      if resource.new_record?
        resource.user = User.current # needed so `resource.user` works below
        resource.user_id = User.current.id
        resource.reference = status_reference
      end

      # Update properties with the language of the user
      # to ensure things like the title are correct
      OpenProject::LocaleHelper.with_locale_for(resource.user) do
        resource.attributes = build_status_attributes(args.merge(status:))
      end

      # There is a possible race condition because of unique job_statuses.job_id
      # Can't use upsert easily, because before updating we need to know user_id
      # to set proper locale. Probably, it is possible to get it from
      # a job's payload, then it would be possible to correctly prepare attributes before using upsert.
      # Therefore, it is up to possible optimization in future. Now the race condition is handled with
      # handling ActiveRecord::RecordNotUnique and trying again.
      resource.save!
    rescue ActiveRecord::RecordNotUnique
      OpenProject.logger.info("Retrying ApplicationJobWithStatus#upsert_status.")
      retry
    end

    protected

    ##
    # Builds the attributes for updating the status
    def build_status_attributes(attributes)
      if title
        attributes[:payload] ||= {}
        attributes[:payload][:title] = title
      end

      attributes.reverse_merge(message: nil, payload: nil)
    end

    ##
    # Title of the job status, optional
    def title
      nil
    end

    ##
    # Crafts a payload for a redirection result
    def redirect_payload(path)
      { redirect: path }
    end

    ##
    # Crafts a payload for a download result
    def download_payload(path, mime_type)
      { download: path, mime_type: }
    end
  end
end
