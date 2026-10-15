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

# The skill pages of an assistant, shared by Administration and My account. The
# controller supplies assistant_scope.
module AIAssistance::AssistantSkillsActions
  extend ActiveSupport::Concern

  included do
    include AIAssistance::RequireFeature

    before_action :find_assistant
    before_action :find_skill, only: %i[edit update destroy copy]

    helper_method :pages
  end

  def new
    @skill = @assistant.skills.build(skill_key: AI::AssistantSkills::Conversation::Skill.key)
    render "ai_assistant_skills/new"
  end

  def edit
    render "ai_assistant_skills/edit"
  end

  def create
    @skill = @assistant.skills.build(skill_attributes.merge(skill_key: AI::AssistantSkills::Conversation::Skill.key,
                                                            position: next_position))

    if @skill.save
      flash[:notice] = t(:notice_successful_create)
      redirect_to pages.edit_assistant_path(@assistant)
    else
      render "ai_assistant_skills/new", status: :unprocessable_entity
    end
  end

  def update
    if @skill.update(skill_attributes)
      flash[:notice] = t(:notice_successful_update)
      redirect_to pages.edit_assistant_path(@assistant)
    else
      render "ai_assistant_skills/edit", status: :unprocessable_entity
    end
  end

  def copy
    copy = @skill.copy!
    flash[:notice] = t("admin.ai_assistants.skills.copied")
    redirect_to pages.edit_skill_path(@assistant, copy)
  end

  # Back to the assistant list when the delete started there.
  def destroy
    @skill.destroy!
    flash[:notice] = t(:notice_successful_delete)
    redirect_to params[:back] == "list" ? pages.assistants_path : pages.edit_assistant_path(@assistant)
  end

  private

  # Admin::… or My::…: the namespace says where the pages live.
  def pages
    @pages ||= AIAssistance::Pages.new(helpers, self.class.module_parent_name.underscore.to_sym)
  end

  def find_assistant
    @assistant = assistant_scope.find(params[:ai_assistant_id])
  end

  def find_skill
    @skill = @assistant.skills.find(params[:id])
  end

  def skill_params
    params.expect(ai_assistant_skill: %i[label description icon offered_on prompt proposal_scope active
                                         answers_at_once use_tools])
  end

  # The condition inputs are outside the model scope: each posts a list of ids, and a
  # hidden blank so that a cleared input clears the condition.
  def skill_attributes
    conditions = AI::AssistantSkill::CONDITION_KEYS.filter_map do |key|
      [key, params[:"condition_#{key}"]] if params.key?(:"condition_#{key}")
    end
    conditions.any? ? skill_params.merge(conditions: @skill&.conditions.to_h.merge(conditions.to_h)) : skill_params
  end

  def next_position
    (@assistant.skills.maximum(:position) || 0) + 1
  end
end
