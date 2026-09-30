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

module GitlabIntegration
  module PipelineStatuses
    SUCCESS = GitlabStatus.pipeline_status(code: :success, color: Color.new(hexcode: "#1A7F37"), icon: :"check-circle")
    RUNNING = GitlabStatus.pipeline_status(code: :running, color: Color.new(hexcode: "#8250DF"), icon: :play)
    FAILED = GitlabStatus.pipeline_status(code: :failed, color: Color.new(hexcode: "#CF222E"), icon: :"x-circle")
    SCHEDULED = GitlabStatus.pipeline_status(code: :scheduled,
                                             color: Color.new(hexcode: "#BF3989"),
                                             icon: :"op-auto-date")

    CREATED = GitlabStatus.pipeline_status(code: :created, color: Color.new(hexcode: "#1A67A3"), icon: :hourglass)
    PREPARING = GitlabStatus.pipeline_status(code: :preparing, color: Color.new(hexcode: "#1A67A3"), icon: :hourglass)
    PENDING = GitlabStatus.pipeline_status(code: :pending, color: Color.new(hexcode: "#1A67A3"), icon: :hourglass)
    WAITING_FOR_RESOURCE = GitlabStatus.pipeline_status(code: :waiting_for_resource,
                                                        color: Color.new(hexcode: "#1A67A3"),
                                                        icon: :hourglass)
    WAITING_FOR_CALLBACK = GitlabStatus.pipeline_status(code: :waiting_for_callback,
                                                        color: Color.new(hexcode: "#1A67A3"),
                                                        icon: :hourglass)

    MANUAL = GitlabStatus.pipeline_status(code: :manual, color: Color.new(hexcode: "#1A67A3"), icon: :pencil)
    SKIPPED = GitlabStatus.pipeline_status(code: :skipped, color: Color.new(hexcode: "#24292F"), icon: :tab)
    CANCELLED = GitlabStatus.pipeline_status(code: :cancelled, color: Color.new(hexcode: "#24292F"), icon: :"x-circle")
    CANCELLING = GitlabStatus.pipeline_status(code: :cancelling,
                                              color: Color.new(hexcode: "#24292F"),
                                              icon: :"x-circle")

    AVAILABLE = [
      SUCCESS,
      RUNNING,
      FAILED,
      SCHEDULED,
      CREATED,
      PREPARING,
      PENDING,
      WAITING_FOR_RESOURCE,
      WAITING_FOR_CALLBACK,
      MANUAL,
      SKIPPED,
      CANCELLED,
      CANCELLING
    ].freeze
  end
end
