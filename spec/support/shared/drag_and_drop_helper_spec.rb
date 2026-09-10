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

def start_dragging(from, offset_x: nil, offset_y: nil)
  scroll_to_element(from)
  page
    .driver
    .browser
    .action
    .move_to(from.native, offset_x, offset_y)
    .click_and_hold
    .perform
end

def drag_element_to(to, offset_x: nil, offset_y: nil)
  scroll_to_element(to)
  page
    .driver
    .browser
    .action
    .move_to(to.native, offset_x, offset_y)
    .perform
end

def drag_release
  page
    .driver
    .browser
    .action
    .release
    .perform
end

def drag_n_drop_element(from:, to:, offset_x: nil, offset_y: nil)
  start_dragging(from)
  drag_element_to(to, offset_x:, offset_y:)
  drag_release
end

# Single-sequence primitive for native HTML5 drags (Pragmatic drag and drop):
# once the native drag loop starts, Chrome swallows input from later action
# chains, so multi-`perform` sequences never deliver the drop. Offsets are
# relative to the target element's center (callers pick the exact drop point
# for edge targeting), so callers don't need to keep the target scrolled into
# view before computing them.
def perform_native_drag(source:, target:, offset_x: 0, offset_y: 0)
  # Ensure both elements are on the page, note this works only if the screen
  # size can fit both.
  scroll_to_element(source, block: :nearest)
  scroll_to_element(target, block: :nearest)

  page
    .driver
    .browser
    .action
    .move_to(source.native)
    .click_and_hold(source.native)
    .pause(duration: 0.1)
    .move_to(target.native, offset_x, offset_y)
    .pause(duration: 0.1)
    .release
    .perform
end

def drag_by_pixel(element:, by_x:, by_y:)
  scroll_to_element(element, block: :center)

  page
    .driver
    .browser
    .action
    .move_to(element.native)
    .click_and_hold(element.native)
    .perform

  page
    .driver
    .browser
    .action
    .move_by(by_x, by_y)
    .release
    .perform
end
