#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

class ProjectSettingsController < ApplicationController
  menu_item :settings

  before_action :find_project
  before_action :authorize
  before_action :check_valid_tab
  before_action :get_tab_settings

  def show
  end

  private

  def settings_info
    @altered_project = @project
  end

  def settings_custom_fields
    @issue_custom_fields = WorkPackageCustomField.order("#{CustomField.table_name}.position")
  end

  def settings_repository
    @repository = @project.repository || new_repository
  end

  def new_repository
    return unless params[:scm_vendor]

    service = Scm::RepositoryFactoryService.new(@project, params)
    if service.build_temporary
      @repository = service.repository
    else
      logger.error("Cannot create repository for #{params[:scm_vendor]}")
      flash[:error] = service.build_error
      nil
    end
  end

  def settings_types
    @types = ::Type.all
  end

  def check_valid_tab
    @selected_tab =
      if params[:tab]
        helpers.project_settings_tabs.detect { |t| t[:name] == params[:tab] }
      else
        helpers.project_settings_tabs.first
      end

    unless @selected_tab
      render_404
    end
  end

  ##
  # Only load the needed elements for the current tab
  def get_tab_settings
    callback = "settings_#{@selected_tab[:name]}"
    if respond_to?(callback, true)
      send(callback)
    end
  end

  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
