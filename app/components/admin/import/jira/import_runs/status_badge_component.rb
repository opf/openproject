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

module Admin::Import::Jira::ImportRuns
  class StatusBadgeComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(status, **system_arguments)
      super

      @title = I18n.t(status.to_s, default: "", scope: "admin.jira.run.status")
      @system_arguments = system_arguments.merge({ bg: status_color_scheme(status) })
    end

    def status_color_scheme(status)
      case status
      when Import::JiraImportStateMachine::IMPORT_ERROR,
           Import::JiraImportStateMachine::REVERT_ERROR,
           Import::JiraImportStateMachine::INSTANCE_META_ERROR,
           Import::JiraImportStateMachine::PROJECTS_META_ERROR,
           Import::JiraImportStateMachine::FINALIZING_ERROR
        :danger
      when Import::JiraImportStateMachine::FINALIZING_DONE,
           Import::JiraImportStateMachine::REVERTED
        :success
      when Import::JiraImportStateMachine::INSTANCE_META_FETCHING,
           Import::JiraImportStateMachine::PROJECTS_META_FETCHING,
           Import::JiraImportStateMachine::IMPORTING,
           Import::JiraImportStateMachine::FINALIZING,
           Import::JiraImportStateMachine::REVERTING,
           Import::JiraImportStateMachine::REVERT_CANCELLING
        :accent
      else
        :attention
      end
    end
  end
end
