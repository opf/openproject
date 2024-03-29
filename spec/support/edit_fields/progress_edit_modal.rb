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

class ProgressEditModal
  include Capybara::DSL
  include Capybara::RSpecMatchers
  include RSpec::Matchers

  MODAL_ID = "work_package_progress_modal"
  FIELD_NAME_MAP = {
    "estimatedTime" => :estimated_hours,
    "remainingTime" => :remaining_hours
  }.freeze

  def initialize(container,
                 property_name,
                 selector: nil)
    # This is the container for the display field. The input field is in the
    # modal, attached to the page.
    @container = container
    @property_name = property_name.to_s
    @field_name = "work_package_#{FIELD_NAME_MAP[@property_name]}"
    @selector = selector || ".inline-edit--display-field.#{@property_name}"
  end

  # Generate
  def update(value, save: true, expect_failure: false)
    retry_block do
      activate_modal

      within_modal do
        set_value value
        save! if save
        expect_state! open: expect_failure || !save
      end
    end
  end

  private

  attr_reader :container,
              :property_name,
              :field_name,
              :selector

  def activate_modal
    display_field.click
  end

  def display_field
    container.find(selector)
  end

  def within_modal(&)
    within(modal, &)
  end

  def modal
    page.find_by_id(MODAL_ID)
  end

  def set_value(value)
    page.fill_in field_name, with: value
  end

  def field
    page.find_field(field_name)
  end

  def save!
    submit_by_enter
  end

  def submit_by_enter
    field.native.send_keys :return
  end

  def expect_state!(open:)
    if open
      expect(page).to have_css("##{MODAL_ID}", :visible)
    else
      expect(page).to have_no_css("##{MODAL_ID}", wait: 0)
    end
  end
end
