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

class EnumerationsController < ApplicationController
  layout "admin"

  before_action :require_admin
  before_action :find_enumeration, only: %i[edit update move destroy]

  include CustomFieldsHelper

  def index; end

  def new
    enum_class = enumeration_class(permitted_params.enumeration_type)
    if enum_class
      @enumeration = enum_class.new
    else
      render_400 # bad request
    end
  end

  def edit; end

  def create
    enum_params = permitted_params.enumerations
    type = permitted_params.enumeration_type
    @enumeration = (enumeration_class(type) || Enumeration).new do |e|
      e.attributes = enum_params
    end

    if @enumeration.save
      flash[:notice] = I18n.t(:notice_successful_create)
      redirect_to action: "index", type: @enumeration.type
    else
      render action: :new, status: :unprocessable_entity
    end
  end

  def update
    enum_params = permitted_params.enumerations
    type = permitted_params.enumeration_type
    @enumeration.type = enumeration_class(type).try(:name) || @enumeration.type
    if @enumeration.update enum_params
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to enumerations_path(type: @enumeration.type)
    else
      render action: :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if !@enumeration.in_use?
      # No associated objects
      @enumeration.destroy
      redirect_to action: "index"
      return
    elsif params[:reassign_to_id]
      if reassign_to = @enumeration.class.find_by(id: params[:reassign_to_id])
        @enumeration.destroy(reassign_to)
        redirect_to action: "index"
        return
      end
    end
    @enumerations = @enumeration.class.all - [@enumeration]
  end

  def move
    if @enumeration.update(permitted_params.enumerations_move)
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to enumerations_path
    else
      flash.now[:error] = I18n.t(:error_type_could_not_be_saved)
      render action: :edit, status: :unprocessable_entity
    end
  end

  protected

  def show_local_breadcrumb
    false
  end

  def default_breadcrumb; end

  def find_enumeration
    @enumeration = Enumeration.find(params[:id])
  end

  ##
  # Find an enumeration class with the given name
  def enumeration_class(type)
    Enumeration.registered_subclasses.detect { |cls| cls.name == type }
  end
end
