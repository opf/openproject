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

class DangerZone
  include Capybara::DSL
  include Capybara::RSpecMatchers

  attr_reader :page

  def initialize(page)
    @page = page
  end

  def container_selector
    ".danger-zone--verification"
  end

  def confirmation_field
    page.within container_selector do
      find("input[type=text]")
    end
  end

  def danger_button
    page.within container_selector do
      find("button.-primary")
    end
  end

  def cancel_button
    page.within container_selector do
      find("a.icon-cancel")
    end
  end

  ##
  # Set the confirmation field to the given value
  def confirm_with(value)
    confirmation_field.set value
  end

  ##
  delegate :disabled?, to: :danger_button
end
