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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin
  class SecurityLevelSchemesController < ::ApplicationController
    before_action :require_admin
    before_action :find_scheme, only: %i[edit update destroy]

    menu_item :security_level_schemes

    layout "admin"

    def index
      @schemes = SecurityLevelScheme.includes(:security_levels).order(:name)
      @project_counts = Project.where.not(security_level_scheme_id: nil).group(:security_level_scheme_id).count
    end

    def new
      @scheme = SecurityLevelScheme.new
    end

    def edit; end

    def create
      @scheme = SecurityLevelScheme.new(scheme_params)

      if @scheme.save
        flash[:notice] = t(:notice_successful_create)
        redirect_to edit_admin_security_level_scheme_path(@scheme)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @scheme.update(scheme_params)
        flash[:notice] = t(:notice_successful_update)
        redirect_to edit_admin_security_level_scheme_path(@scheme)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @scheme.destroy!
      flash[:notice] = t(:notice_successful_delete)
      redirect_to admin_security_level_schemes_path
    end

    private

    def find_scheme
      @scheme = SecurityLevelScheme.find(params.expect(:id))
    end

    def scheme_params
      params.expect(security_level_scheme: %i[name description])
    end
  end
end
