#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class DesignColor < ActiveRecord::Base
  after_commit -> do
    # CustomStyle.current.updated_at determins the cache key for inline_css
    # in which the CSS color variables will be overwritten. That is why we need
    # to ensure that a CustomStyle.current exists and that the time stamps change
    # whenever we chagen a color_variable.
    if CustomStyle.current
      CustomStyle.current.touch
    else
      CustomStyle.create
    end
  end

  before_validation :normalize_hexcode

  validates_uniqueness_of :variable
  validates_presence_of :hexcode, :variable
  validates_format_of :hexcode, with: /\A#[0-9A-F]{6}\z/, unless: lambda { |e| e.hexcode.blank? }

  class << self
    def defaults
      OpenProject::Design.resolved_variables
    end

    def setables
      overwritten_values = self.overwritten
      OpenProject::Design.customizable_variables.map do |varname|
        overwritten_value = overwritten_values.detect { |var| var.variable == varname }
        overwritten_value || new(variable: varname)
      end
    end

    def overwritten
      overridable = OpenProject::Design.customizable_variables

      all.to_a.select do |color|
        overridable.include?(color.variable) && self.defaults[color] != color.get_hexcode
      end
    end
  end

  # shortcut to get the color's value
  def get_hexcode
    hexcode.presence || self.class.defaults[variable]
  end

  protected

  # This could be DRY! This method is taken from model PlanningElementTypeColor.
  def normalize_hexcode
    if hexcode.present? and hexcode_changed?
      self.hexcode = hexcode.strip.upcase

      unless hexcode.starts_with? '#'
        self.hexcode = '#' + hexcode
      end

      if hexcode.size == 4 # =~ /#.../
        self.hexcode = hexcode.gsub(/([^#])/, '\1\1')
      end
    end
  end
end
