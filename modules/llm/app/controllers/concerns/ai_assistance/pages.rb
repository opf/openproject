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

# The URLs, titles and breadcrumbs of the assistant pages, in Administration (:admin) or
# in My account (:my). The pages are the same; only where they live differs.
class AIAssistance::Pages
  attr_reader :prefix

  def initialize(helpers, prefix)
    @helpers = helpers
    @prefix = prefix
  end

  def admin?
    prefix == :admin
  end

  def assistants_path(**) = route("#{prefix}_ai_assistants_path", **)
  def new_assistant_path = route("new_#{prefix}_ai_assistant_path")
  def assistant_path(assistant) = route("#{prefix}_ai_assistant_path", assistant)
  def edit_assistant_path(assistant) = route("edit_#{prefix}_ai_assistant_path", assistant)
  def skills_path(assistant) = route("#{prefix}_ai_assistant_skills_path", assistant)
  def new_skill_path(assistant) = route("new_#{prefix}_ai_assistant_skill_path", assistant)
  def skill_path(assistant, skill) = route("#{prefix}_ai_assistant_skill_path", assistant, skill)
  def edit_skill_path(assistant, skill) = route("edit_#{prefix}_ai_assistant_skill_path", assistant, skill)
  def copy_assistant_path(assistant) = route("copy_#{prefix}_ai_assistant_path", assistant)
  def copy_skill_path(assistant, skill) = route("copy_#{prefix}_ai_assistant_skill_path", assistant, skill)

  def title
    admin? ? I18n.t("menus.admin.ai_assistants") : I18n.t("my_account.ai_assistants.title")
  end

  # The parts of the HTML title before the page's own.
  def html_title_parts
    [admin? ? I18n.t(:label_administration) : I18n.t(:label_my_account), title]
  end

  # The breadcrumbs of a page below the list, or of the list itself when trail is empty.
  def breadcrumbs(*trail)
    return parents + [title] if trail.empty?

    parents + [{ href: assistants_path, text: title }] + trail
  end

  private

  def parents
    if admin?
      [{ href: @helpers.admin_index_path, text: I18n.t(:label_administration) },
       { href: @helpers.mcp_configurations_path, text: I18n.t("menus.admin.ai") }]
    else
      [{ href: @helpers.my_account_path, text: I18n.t(:label_my_account) }]
    end
  end

  def route(name, *, **)
    @helpers.public_send(name, *, **)
  end
end
