#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'model_contract'

module Grids
  class BaseContract < ::ModelContract
    include OpenProject::StaticRouting::UrlHelpers
    # TODO: validate widgets are in array of allowed widgets
    #       validate widgets do not collide
    attribute :row_count do
      validate_positive_integer(:row_count)
    end

    attribute :column_count do
      validate_positive_integer(:column_count)
    end

    attribute_alias :type, :page

    def validate
      validate_registered_subclass
      validate_registered_widgets
      validate_widget_collisions

      super
    end

    attribute :widgets

    def self.model
      Grid
    end

    # TODO tests and check if it should be here
    def assignable_values(_column, _user)
      nil
    end

    private

    def validate_registered_subclass
      unless Grids::Configuration.registered_grid?(model.class)
        # page because that is what is exposed to the outside
        errors.add(:page, :inclusion)
      end
    end

    def validate_registered_widgets
      return unless Grids::Configuration.registered_grid?(model.class)

      model.widgets.each do |widget|
        next if Grids::Configuration.allowed_widget?(model.class, widget.identifier)

        errors.add(:widgets, :inclusion)
      end
    end

    def validate_widget_collisions
      model.widgets.each do |widget|
        overlaps = model
                   .widgets
                   .any? do |other_widget|
                     widget != other_widget &&
                       !widget.marked_for_destruction? &&
                       !other_widget.marked_for_destruction? &&
                       widgets_overlap?(widget, other_widget)
                   end

        if overlaps
          errors.add(:widgets, :overlaps)
        end
      end
    end

    def validate_positive_integer(attribute)
      value = model.send(attribute)

      if !value
        errors.add(attribute, :blank)
      elsif value < 1
        errors.add(attribute, :greater_than, count: 0)
      end
    end

    def widgets_overlap?(widget, other_widget)
      point_in_widget_area(widget, other_widget.start_row, other_widget.start_column) ||
        point_in_widget_area(widget, other_widget.start_row, other_widget.end_column) ||
        point_in_widget_area(widget, other_widget.end_row, other_widget.start_column) ||
        point_in_widget_area(widget, other_widget.end_row, other_widget.end_column)
    end

    def point_in_widget_area(widget, row, column)
      widget.start_row < row && widget.end_row > row &&
        widget.start_column < column && widget.end_column > column
    end
  end
end
