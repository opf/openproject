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

class WorkflowsController < ApplicationController
  include OpTurbo::ComponentStream

  layout "admin"

  before_action :require_admin

  before_action :find_types, only: %i[index]

  before_action :find_type, only: %i[edit]
  before_action :find_optional_roles, only: %i[edit]

  def index; end

  def edit
    @current_tab = current_tab
  end

  private

  def current_tab
    params[:tab] || "always"
  end

  def find_types
    @types = ::Type.order(:position)
  end

  def find_type
    @type = ::Type.find(params[:type_id])
  end

  def find_optional_roles
    ordered = eligible_roles.order(:builtin, :position)
    @roles = ordered.where(id: params[:role_ids])
    @roles = [ordered.first] if @roles.empty?
  end

  def eligible_roles
    @eligible_roles ||= Workflow.eligible_roles
  end
end
