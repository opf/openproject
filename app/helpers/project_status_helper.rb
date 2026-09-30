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

module ProjectStatusHelper
  NOT_SET = "not_set"
  private_constant :NOT_SET

  ##
  # Returns the CSS class (BEM modifier) for the Project Status.
  # Can be used in conjunction with `.project-status--name` or
  # `.project-status--bulb` (BEM element) classes.
  #
  # @param status_code [String | Symbol | nil] Project Status code
  # @return [String] the CSS class.
  def project_status_css_class(status_code)
    "-#{(status_code&.to_s || NOT_SET).dasherize}"
  end

  ##
  # Returns the localized Project Status name.
  #
  # @param status_code [String | Symbol | nil] Project Status code
  # @return [String] the localized name.
  def project_status_name(status_code)
    I18n.t(status_code || NOT_SET, scope: "js.grid.widgets.project_status")
  end
end
