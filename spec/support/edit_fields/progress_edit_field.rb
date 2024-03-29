# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2024 the OpenProject GmbH
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

require_relative "edit_field"

class ProgressEditField < EditField
  MODAL_SELECTOR = "#work_package_progress_modal"
  FIELD_NAME_MAP = {
    "estimatedTime" => :estimated_hours,
    "remainingTime" => :remaining_hours
  }.freeze

  def initialize(context,
                 property_name,
                 selector: nil)
    super(context, property_name, selector:)
    @field_name = "work_package_#{FIELD_NAME_MAP.fetch(@property_name)}"
  end

  def update(value, save: true, expect_failure: false)
    super
  end

  def active?
    page.has_selector?(MODAL_SELECTOR, wait: 1)
  end

  def set_value(value)
    page.fill_in field_name, with: value
  end

  def input_element
    modal_element.find_field(field_name)
  end

  def save!
    submit_by_enter
  end

  def submit_by_enter
    input_element.native.send_keys :return
  end

  def expect_active!
    expect(page).to have_css(MODAL_SELECTOR, :visible)
  end

  def expect_inactive!
    expect(page).to have_no_css(MODAL_SELECTOR)
  end

  private

  attr_reader :field_name

  def modal_element
    page.find(MODAL_SELECTOR)
  end
end
