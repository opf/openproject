#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

module Grids
  class BaseContract < ::ModelContract
    include OpenProject::StaticRouting::UrlHelpers
    include AssignableValuesContract
    include ::Attachments::ValidateReplacements

    attribute :row_count do
      validate_positive_integer(:row_count)
    end

    attribute :column_count do
      validate_positive_integer(:column_count)
    end

    attribute_alias :type, :scope

    def validate
      validate_allowed
      validate_registered_widgets
      validate_widget_collisions
      validate_widgets_within
      validate_widgets_start_before_end

      run_registration_validations

      super
    end

    attribute :widgets

    attribute :name

    attribute :options

    def self.model
      Grid
    end

    def edit_allowed?
      config.writable?(model, user)
    end

    def assignable_widgets
      all_allowed_widget_identifiers(user)
    end

    private

    def validate_allowed
      unless edit_allowed?
        # scope because that is what is exposed to the outside
        errors.add(:scope, :inclusion)
      end
    end

    def validate_registered_widgets
      return unless config.registered_grid?(grid_class)

      widgets_to_be_created.each do |widget|
        next if config.allowed_widget?(grid_class, widget.identifier, user, grid_project)

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

    def run_registration_validations
      validations = config.validations(model, self.class.name.demodulize.gsub('Contract', '').underscore.to_sym)

      validations.each do |validation|
        instance_eval(&validation)
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

    def widgets_to_be_created
      undestroyed_widgets.select(&:new_record?)
    end

    def all_allowed_widget_identifiers(user)
      config.all_widget_identifiers(grid_class).select do |identifier|
        config.allowed_widget?(grid_class, identifier, user, grid_project)
      end
    end

    def grid_class
      model.class
    end

    def config
      Grids::Configuration
    end

    def grid_project
      model.respond_to?(:project) ? model.project : nil
    end
  end
end
