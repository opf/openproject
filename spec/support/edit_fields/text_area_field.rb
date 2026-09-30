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

require_relative "edit_field"

class TextAreaField < EditField
  def input_selector
    "textarea"
  end

  def expect_save_button(enabled: true)
    if enabled
      expect(field_container).to have_no_css("#{control_link}[disabled]")
    else
      expect(field_container).to have_css("#{control_link}[disabled]")
    end
  end

  def save!
    submit_by_click
  end

  def submit_by_click
    target = field_container.find(control_link)
    scroll_to_element(target)
    target.click
  end

  def submit_by_keyboard
    input_element.native.send_keys :tab
  end

  def cancel_by_click
    target = field_container.find(control_link(:cancel))
    scroll_to_element(target)
    target.click
  end

  def field_type
    "textarea"
  end

  def control_link(action = :save)
    raise "Invalid link" unless %i[save cancel].include?(action)

    ".inplace-edit--control--#{action}"
  end
end
