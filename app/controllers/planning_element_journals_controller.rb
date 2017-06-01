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

class PlanningElementJournalsController < ApplicationController
  helper :timelines

  include ExtendedHTTP

  before_action :disable_api
  before_action :find_project_by_project_id
  before_action :find_planning_element_by_planning_element_id
  before_action :authorize

  accept_key_auth :index, :create

  def index
    @journals = @planning_element.journals
    respond_to do |format|
      format.html do
        render_404
      end
    end
  end

  def create
    raise NotImplementedError
  end

  protected

  def find_planning_element_by_planning_element_id
    raise ActiveRecord::RecordNotFound if @project.blank?
    @planning_element = @project.work_packages.find(params[:planning_element_id])
  end
end
