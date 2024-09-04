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

class Admin::CustomFields::CustomFieldProjectsController < ApplicationController
  layout "admin"

  model_object CustomField

  before_action :require_admin
  before_action :find_model_object

  menu_item :custom_fields

  def index
    @available_custom_fields_projects_query = ProjectQuery.new(
      name: "custom-fields-projects-#{@custom_field.id}"
    ) do |query|
      query.where(:available_custom_fields_projects, "=", [@custom_field.id])
      query.select(:name)
      query.order("lft" => "asc")
    end
  end

  def default_breadcrumb; end

  def show_local_breadcrumb
    false
  end

  private

  def find_model_object(object_id = :custom_field_id)
    super
    @custom_field = @object
  end
end
