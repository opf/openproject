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
      validate_widgets_within
      validate_widgets_start_before_end

      super
    end

    attribute :widgets

    def self.model
      Grid
    end

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

      undestroyed_widgets.each do |widget|
        next if Grids::Configuration.allowed_widget?(model.class, widget.identifier)

        errors.add(:widgets, :inclusion)
      end
    end

    def validate_widget_collisions
      undestroyed_widgets.each do |widget|
        overlaps = undestroyed_widgets
                   .any? do |other_widget|
                     widget != other_widget &&
                       widgets_overlap?(widget, other_widget)
                   end

        if overlaps
          errors.add(:widgets, :overlaps)
        end
      end
    end

    def validate_widgets_within
      undestroyed_widgets.each do |widget|
        next unless outside?(widget)

        errors.add(:widgets, :outside)
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

    def validate_widgets_start_before_end
      undestroyed_widgets.each do |widget|
        if widget.start_row >= widget.end_row ||
           widget.start_column >= widget.end_column

          errors.add(:widgets, :end_before_start)
        end
      end
    end

    def widgets_overlap?(widget, other_widget)
      top_left_inside?(widget, other_widget) ||
        top_right_inside?(widget, other_widget) ||
        bottom_left_inside?(widget, other_widget) ||
        bottom_right_inside?(widget, other_widget)
    end

    def top_left_inside?(widget, other_widget)
      widget.start_row <= other_widget.start_row && widget.end_row > other_widget.start_row &&
        widget.start_column <= other_widget.start_column && widget.end_column > other_widget.start_column
    end

    def top_right_inside?(widget, other_widget)
      widget.start_row <= other_widget.start_row && widget.end_row > other_widget.start_row &&
        widget.start_column < other_widget.end_column && widget.end_column >= other_widget.end_column
    end

    def bottom_left_inside?(widget, other_widget)
      widget.start_row < other_widget.end_row && widget.end_row >= other_widget.end_row &&
        widget.start_column <= other_widget.start_column && widget.end_column > other_widget.start_column
    end

    def bottom_right_inside?(widget, other_widget)
      widget.start_row < other_widget.end_row && widget.end_row >= other_widget.end_row &&
        widget.start_column < other_widget.end_column && widget.end_column >= other_widget.end_column
    end

    def outside?(widget)
      outside_row(widget.start_row) ||
        outside_row(widget.end_row) ||
        outside_column(widget.start_column) ||
        outside_column(widget.end_column)
    end

    def outside_row(number)
      number > model.row_count + 1 || number < 1
    end

    def outside_column(number)
      number > model.column_count + 1 || number < 1
    end

    def undestroyed_widgets
      model.widgets.reject(&:marked_for_destruction?)
    end
  end
end
