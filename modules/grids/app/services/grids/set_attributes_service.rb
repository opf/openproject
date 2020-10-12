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

class Grids::SetAttributesService < ::BaseServices::SetAttributes
  include Attachments::SetReplacements

  private

  def set_attributes(attributes)
    widget_attributes = attributes.delete(:widgets)

    ret = super(attributes)

    update_widgets(widget_attributes)

    cleanup_prohibited_widgets(widget_attributes)

    ret
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
      model.widgets.build widget.attributes.except('id')
    end

    update_map.each do |existing, provided|
      existing.attributes = provided.attributes.except('id', 'grid_id')
    end
  end

  def classify_widgets(widgets)
    if model.widgets.empty?
      classify_create_all(widgets)
    else
      classify_preserve_existing(widgets)
    end
  end

  def classify_create_all(widgets)
    [widgets, [], []]
  end

  def classify_preserve_existing(widgets)
    widget_map = model.widgets.map { |w| [w, nil] }.to_h
    to_create = []

    widgets.each do |widget|
      matching_map_key = match_widget(widget_map, widget)

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

  def match_widget(widget_map, widget)
    available_map_keys = widget_map.select { |_, v| v.nil? }.keys

    if model.persisted?
      available_map_keys.find { |w| w.id == widget.id }
    else
      available_map_keys.find { |w| w.identifier == widget.identifier }
    end
  end

  # Removes prohibited widgets from the grid.
  # That way, a valid subset of the default widgets is returned e.g. in the form
  # or on a create request without widgets.
  # Will only work on new records and only if no widgets have been specified.
  def cleanup_prohibited_widgets(widgets)
    return if widgets&.any? || model.persisted?

    # As it is a new record, we can do direct assignments without risking saving.
    model.widgets = model.widgets.select(&method(:allowed_widget?))
  end

  def allowed_widget?(widget)
    project = model.respond_to?(:project) ? model.project : nil

    Grids::Configuration.allowed_widget?(model.class, widget.identifier, user, project)
  end
end
