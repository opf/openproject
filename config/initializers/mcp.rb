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

MCP.configure do |config|
  config.exception_reporter = lambda do |exception, server_context|
    cause = exception.cause
    message = "Unhandled exception occured during MCP request: #{exception}"
    message += if cause
                 ", caused by #{cause} at #{cause.backtrace.first}"
               else
                 " at #{exception.backtrace.first}"
               end

    Rails.logger.error message
    OpenProject::Appsignal.trace_exception(exception, server_context) if OpenProject::Appsignal.enabled?
    OpenProject::OpenTelemetry.trace_exception(exception, server_context) if OpenProject::OpenTelemetry.enabled?
  end
end

Rails.application.config.to_prepare do
  McpTools.register McpTools::CreateWorkPackage,
                    McpTools::CreateWorkPackageComment,
                    McpTools::CreateWorkPackageRelation,
                    McpTools::CurrentUser,
                    McpTools::DeleteWorkPackageRelation,
                    McpTools::ListStatuses,
                    McpTools::ListTypes,
                    McpTools::ListWorkPackageComments,
                    McpTools::ListWorkPackageRelations,
                    McpTools::SearchCustomFields,
                    McpTools::SearchCustomFieldItems,
                    McpTools::SearchPortfolios,
                    McpTools::SearchPrograms,
                    McpTools::SearchProjects,
                    McpTools::SearchUsers,
                    McpTools::SearchVersions,
                    McpTools::SearchWorkPackages,
                    McpTools::UpdateWorkPackage,
                    McpTools::UpdateWorkPackageRelation

  McpResources.register McpResources::CurrentUser,
                        McpResources::CustomField,
                        McpResources::Project,
                        McpResources::Status,
                        McpResources::StatusList,
                        McpResources::Type,
                        McpResources::TypeList,
                        McpResources::User,
                        McpResources::Version,
                        McpResources::WorkPackage
end
