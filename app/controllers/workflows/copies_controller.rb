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

class Workflows::CopiesController < ApplicationController
  include OpTurbo::ComponentStream

  layout "admin"

  before_action :require_admin

  before_action :set_source_type
  before_action :set_source_role
  before_action :set_other_types
  before_action :set_all_roles

  def new; end

  private

  def set_source_type
    @source_type = ::Type.find(params[:workflow_type_id])
  end

  def set_source_role
    @source_role = eligible_roles.find_by(id: params[:source_role_id])
  end

  def set_other_types
    @other_types = ::Type.where.not(id: @source_type.id).order(:position)
  end

  def set_all_roles
    @all_roles = eligible_roles
  end

  def eligible_roles
    @eligible_roles ||= Workflow.eligible_roles
  end
end
