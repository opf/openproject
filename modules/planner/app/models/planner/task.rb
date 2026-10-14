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

module Planner
  class Task
    attr_reader :work_package, :references, :user

    delegate :closed?, to: :work_package

    def initialize(work_package, references:, user:)
      @work_package = work_package
      @references = references
      @user = user
    end

    # The subject as text, with each visible referenced work package in place of its reference.
    def subject_parts
      @subject_parts ||= work_package.subject.split(References::PATTERN).each_with_index.map do |part, index|
        index.even? ? part : references.fetch(part) { "##{part}" }
      end
    end

    def planned_work_package
      return @planned_work_package if defined?(@planned_work_package)

      @planned_work_package = References.planned_id(work_package.subject)&.then { references[it] }
    end

    def meeting_command
      return @meeting_command if defined?(@meeting_command)

      @meeting_command = (MeetingCommand.for(work_package, user) unless closed?)
    end
  end
end
