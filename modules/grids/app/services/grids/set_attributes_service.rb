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

class Grids::SetAttributesService
  include Concerns::Contracted

  attr_accessor :user,
                :grid,
                :contract_class

  def initialize(user:, grid:, contract_class:)
    self.user = user
    self.grid = grid
    self.contract_class = contract_class
  end

  def call(attributes)
    widget_attributes = attributes.delete(:widgets)

    set_attributes(attributes)
    update_widgets(widget_attributes)

    validate_and_result
  end

  private

  def validate_and_result
    success, errors = validate(grid, user)

    ServiceResult.new(success: success,
                      errors: errors,
                      result: grid)
  end

  def set_attributes(attributes)
    grid.attributes = attributes
  end

  # Updates grid's widget but does not persist the changes:
  # * new ones are build
  # * removed ones are marked_for_destruction
  # * updated ones are not saved
  # Goes through all provided widgets to find widgets with the same identifier but disregarding the id.
  # All widgets identified as such are updated.
  # Provided widgets that do not correspond to an existing widget are created.
  # Widgets in the set of existing widgets that do not have a corresponding provided widget are deleted.
  #
  # All this is done to maximize reuse of widgets without having to expose the id.
  #
  # Do not use any methods changing the widgets array as those get persisted to the db right away.
  def update_widgets(widgets)
    return unless widgets

    to_create, to_destroy, update_map = classify_widgets(widgets)

    to_destroy.each(&:mark_for_destruction)

    to_create.each do |widget|
      grid.widgets.build widget.attributes.except('id')
    end

    update_map.each do |existing, provided|
      existing.attributes = provided.attributes.except('id', 'grid_id')
    end
  end

  def classify_widgets(widgets)
    if grid.widgets.empty?
      classify_create_all(widgets)
    else
      classify_preserve_existing(widgets)
    end
  end

  def classify_create_all(widgets)
    [widgets, [], []]
  end

  def classify_preserve_existing(widgets)
    widget_map = grid.widgets.map { |w| [w, nil] }.to_h
    to_create = []

    widgets.each do |widget|
      matching_map_key = first_unclaimed_by_identifier(widget_map, widget)

      if matching_map_key
        widget_map[matching_map_key] = widget
      else
        to_create << widget
      end
    end

    [to_create,
     widget_map.select { |_, v| v.nil? }.keys,
     widget_map.compact]
  end

  def first_unclaimed_by_identifier(widget_map, widget)
    available_map_keys = widget_map.select { |_, v| v.nil? }.keys

    available_map_keys.find { |w| w.identifier == widget.identifier }
  end
end
