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
  DEFAULTS = {
    "primary-color"       => "#3493B3",
    "primary-color-dark"  => "#06799F",
    "alternative-color"   => "#35C53F"
  }

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
      return DEFAULTS
    end

    def setables
      groups = overwritten.group_by(&:variable)
      return DEFAULTS.map do |variable, hexcode|
        if groups[variable].try(:any?)
          groups[variable].first
        else
          new variable: variable
        end
      end
    end

    def overwritten
      all.to_a.delete_if do |color_variable|
        DEFAULTS.keys.exclude? color_variable.variable
      end
    end

  end

  # shortcut to get the color's value
  def get_hexcode
    if hexcode.present?
      return hexcode
    else
      self.class.defaults[variable]
    end
  end

  protected

  # TODO: Make it DRY! This method is taken from model PlanningElementTypeColor.
  def normalize_hexcode
    if hexcode.present? and hexcode_changed?
      self.hexcode = hexcode.strip.upcase

      unless hexcode.starts_with? '#'
        self.hexcode = '#' + hexcode
      end

      if hexcode.size == 4  # =~ /#.../
        self.hexcode = hexcode.gsub(/([^#])/, '\1\1')
      end
    end
  end

end
