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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module GitlabIntegration
  class MergeRequestComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers

    alias_method :merge_request, :model

    private

    def state_scheme
      case merge_request.state.to_sym
      when :opened
        :success
      when :closed, :locked
        :danger
      when :merged
        :done
      else
        raise ArgumentError, "Unsupported merge request state #{state}"
      end
    end

    def state_icon
      case merge_request.state.to_sym
      when :opened
        :"git-pull-request"
      when :closed
        :"git-pull-request-closed"
      when :locked
        :lock
      when :merged
        :"git-merge"
      else
        raise ArgumentError, "Unsupported merge request state #{state}"
      end
    end

    def state_label
      t(".states.#{merge_request.state}")
    end

    def latest_pipeline
      @latest_pipeline ||= merge_request.gitlab_pipelines.order(started_at: :asc).last
    end

    def pipeline_status
      return nil unless latest_pipeline

      latest_pipeline.status.to_sym
    end

    def pipeline_status_scheme
      case pipeline_status
      when :success
        :success
      when :failed
        :danger
      when :skipped, :created, :waiting_for_resource, :preparing, :waiting_for_callback, :pending, :scheduled
        :attention
      when :running
        :done # TODO: BLUE!
      else
        :default
      end
    end

    def pipeline_status_icon
      case pipeline_status
      when :success
        :check
      when :failed
        :alert
      when :created, :waiting_for_resource, :preparing, :waiting_for_callback, :pending, :scheduled
        :clock
      when :skipped
        :skip
      when :running
        :loop
      when :canceling, :canceled
        :stop
      else
        :question
      end
    end

    def pipeline_status_label
      t(".pipeline_statuses.#{pipeline_status}")
    end
  end
end
