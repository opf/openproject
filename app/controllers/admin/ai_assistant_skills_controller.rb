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

module Admin
  class AIAssistantSkillsController < ::ApplicationController
    include AIAssistance::RequireFeature

    before_action :require_admin
    before_action :find_assistant
    before_action :find_skill, only: %i[edit update destroy]

    menu_item :ai_assistants

    layout "admin"

    def new
      @skill = @assistant.skills.build(skill_key: AI::AssistantSkills::Registry.keys.first)
    end

    def edit; end

    def create
      @skill = @assistant.skills.build(skill_params.merge(skill_key: params.dig(:ai_assistant_skill, :skill_key),
                                                          position: (@assistant.skills.maximum(:position) || 0) + 1))

      if @skill.save
        flash[:notice] = t(:notice_successful_create)
        redirect_to edit_admin_ai_assistant_path(@assistant)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @skill.update(skill_params)
        flash[:notice] = t(:notice_successful_update)
        redirect_to edit_admin_ai_assistant_path(@assistant)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @skill.destroy
      flash[:notice] = t(:notice_successful_delete)
      redirect_to edit_admin_ai_assistant_path(@assistant)
    end

    private

    def find_assistant
      @assistant = AI::Assistant.find(params[:ai_assistant_id])
    end

    def find_skill
      @skill = @assistant.skills.find(params[:id])
    end

    # The key is set once, on create: runs refer to the skill by it.
    def skill_params
      params.expect(ai_assistant_skill: %i[label description prompt output_rules template_ref proposal_scope active])
    end
  end
end
