#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class DesignColor < ApplicationRecord
  include ::Colors::HexColor

  before_validation :normalize_hexcode
  after_commit -> do
    # CustomStyle.current.updated_at determines the cache key for inline_css
    # in which the CSS color variables will be overwritten. That is why we need
    # to ensure that a CustomStyle.current exists and that the time stamps change
    # whenever we change a color_variable.
    if CustomStyle.current
      CustomStyle.current.touch
    else
      CustomStyle.create
    end
  end

  validates :variable, uniqueness: true
  validates :hexcode, :variable, presence: true
  validates :hexcode, format: { with: /\A#[0-9A-F]{6}\z/, unless: lambda { |e| e.hexcode.blank? } }

  class << self
    def setables
      overwritten_values = overwritten
      OpenProject::CustomStyles::Design.customizable_variables.map do |varname|
        overwritten_value = overwritten_values.detect { |var| var.variable == varname }
        overwritten_value || new(variable: varname)
      end
    end

    def overwritten
      overridable = OpenProject::CustomStyles::Design.customizable_variables

      all.to_a.select do |color|
        overridable.include?(color.variable) && color.hexcode.present?
      end
    end
  end
end
