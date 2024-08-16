# frozen_string_literal: true

# -- copyright
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
# ++

class Projects::IndexPageHeaderComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers
  include Primer::FetchOrFallbackHelper
  include OpTurbo::Streamable

  attr_accessor :current_user,
                :query,
                :state,
                :params

  STATE_DEFAULT = :show
  STATE_EDIT = :edit

  delegate :projects_query_params, to: :helpers

  def initialize(current_user:, query:, params:, state: STATE_DEFAULT)
    super

    self.current_user = current_user
    self.query = query
    self.state = case state
                 when :edit, :rename
                   STATE_EDIT
                 else
                   STATE_DEFAULT
                 end
    self.params = params
  end

  def self.wrapper_key
    "projects-index-page-header"
  end

  def gantt_portfolio_query_link
    generator = ::Projects::GanttQueryGeneratorService.new(gantt_portfolio_project_ids)
    gantt_index_path query_props: generator.call
  end

  def gantt_portfolio_project_ids
    @gantt_portfolio_project_ids ||= @query
                                     .results
                                     .where(active: true)
                                     .pluck(:id)
                                     .uniq
  end

  def page_title
    query.name || t(:label_project_plural)
  end

  def may_save_as? = current_user.logged?

  def can_save_as? = may_save_as? && query.changed?

  def can_save?
    return false unless current_user.logged?
    return false unless query.persisted?
    return false unless query.changed?

    query.editable?
  end

  def can_rename?
    return false unless current_user.logged?
    return false unless query.persisted?
    return false if query.changed?

    query.editable?
  end

  def show_state?
    state == :show
  end

  def can_access_shares?
    query.persisted?
  end

  def can_toggle_favor? = query.persisted?

  def currently_favored? = query.favored_by?(current_user)

  def breadcrumb_items
    [
      { href: projects_path, text: t(:label_project_plural) },
      current_breadcrumb_element
    ]
  end

  def current_breadcrumb_element
    return page_title if query.name.blank?

    if current_section && current_section.header.present?
      I18n.t("menus.breadcrumb.nested_element", section_header: current_section.header, title: query.name).html_safe
    else
      page_title
    end
  end

  def current_section
    return @current_section if defined?(@current_section)

    projects_menu = Projects::Menu.new(controller_path:, params:, current_user:)

    @current_section = projects_menu.menu_items.find { |section| section.children.any?(&:selected) }
  end

  def header_save_action(header:, message:, label:, href:, method: nil)
    header.with_action_text { message }

    header.with_action_link(
      mobile_icon: nil, # Do not show on mobile as it is already part of the menu
      mobile_label: nil,
      href:,
      data: { "turbo-stream": true, method: },
      target: ""
    ) do
      render(
        Primer::Beta::Octicon.new(
          icon: "op-save",
          align_self: :center,
          "aria-label": label,
          mr: 1
        )
      ) + content_tag(:span, label)
    end
  end

  def menu_save_item(menu:, label:, href:, method: nil)
    menu.with_item(
      label:,
      href:,
      content_arguments: {
        data: { "turbo-stream": true, method: }
      }
    ) do |item|
      item.with_leading_visual_icon(icon: :"op-save")
    end
  end
end
