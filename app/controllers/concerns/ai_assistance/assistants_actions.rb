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

# The assistant pages, shared by Administration and My account. The controller supplies
# assistant_scope, assistant_params and new_assistant.
module AIAssistance::AssistantsActions
  extend ActiveSupport::Concern

  included do
    include AIAssistance::RequireFeature

    before_action :find_assistant, only: %i[edit update destroy]

    helper_method :pages
  end

  def index
    @assistants = assistant_scope.ordered.includes(:skills)
    render "ai_assistants/index"
  end

  def new
    @assistant = new_assistant
    render "ai_assistants/new"
  end

  def edit
    render "ai_assistants/edit"
  end

  def create
    @assistant = new_assistant(assistant_params)
    @assistant.position = (AI::Assistant.where(user_id: @assistant.user_id).maximum(:position) || 0) + 1

    if @assistant.save
      flash[:notice] = t(:notice_successful_create)
      redirect_to pages.edit_assistant_path(@assistant)
    else
      render "ai_assistants/new", status: :unprocessable_entity
    end
  end

  def update
    if @assistant.update(assistant_params)
      flash[:notice] = t(:notice_successful_update)
      redirect_to pages.assistants_path
    else
      render "ai_assistants/edit", status: :unprocessable_entity
    end
  end

  def destroy
    @assistant.destroy!
    flash[:notice] = t(:notice_successful_delete)
    redirect_to pages.assistants_path
  end

  private

  # Admin::… or My::…: the namespace says where the pages live.
  def pages
    @pages ||= AIAssistance::Pages.new(helpers, self.class.module_parent_name.underscore.to_sym)
  end

  def find_assistant
    @assistant = assistant_scope.find(params[:id])
  end
end
