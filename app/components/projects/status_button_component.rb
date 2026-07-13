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

class Projects::StatusButtonComponent < ApplicationComponent
  include ApplicationHelper
  include OpTurbo::Streamable
  include OpPrimer::ComponentHelpers
  include ProjectStatusHelper

  attr_reader :project, :user, :hide_help_text, :hide_help_text_caption
  alias :hide_help_text? :hide_help_text
  alias :hide_help_text_caption? :hide_help_text_caption

  def initialize(project:, user:, size: :medium, hide_help_text: false, hide_help_text_caption: false)
    super

    @project = project
    @user = user
    @size = size
    @hide_help_text = hide_help_text
    @hide_help_text_caption = hide_help_text_caption

    @status = find_status(project.status_code)
  end

  def wrapper_uniq_by
    project
  end

  private

  def edit_enabled?
    user.allowed_in_project?(:edit_project, project)
  end

  def find_status(code)
    Projects::Statuses::AVAILABLE.find(-> { Projects::Statuses::NOT_SET }) { it.code&.to_s == code }
  end

  def build_items
    Projects::Statuses::AVAILABLE.map { build_item(it) }
  end

  def build_item(status)
    OpPrimer::StatusButtonOption.new(
      name: project_status_name(status.code),
      color_namespace: :project_status,
      color_ref: status.id,
      icon: status.icon,
      item_id: status.id,
      tag: :a,
      href: project_status_path(project, status_code: status.value, status_size: @size),
      content_arguments: {
        data: { turbo_method: status.value ? :put : :delete },
        aria: { current: (true if status == @status) }
      }
    )
  end
end
