#-- encoding: UTF-8
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

module TimelinesHelper
  unloadable

  def icon_for_color(color, options = {})
    return unless color

    options = options.merge(class: 'timelines-phase ' + options[:class].to_s,
                            style: "background-color: #{color.hexcode};" + options[:style].to_s)

    content_tag(:span, ' ', options)
  end

  def parent_id_select_tag(form, planning_element)
    available_parents = planning_element.project.planning_elements.find(:all, order: 'COALESCE(parent_id, id), parent_id')
    available_parents -= [planning_element]

    available_options = available_parents.map do |pe|
      texts = (pe.ancestors.reverse << pe).map { |a| "*#{a.id} #{a.subject}" }
      [texts.join(right_pointing_arrow), pe.id]
    end

    available_options.unshift(['', ''])

    form.select :parent_id, available_options
  end

  def right_pointing_arrow
    ' ▸ '
  end

  def format_date(date, options = nil)
    text = super(date)

    if options.present?
      content_tag(:span, text, options)
    else
      text
    end
  end

  def options_for_colors(colored_thing)
    s = content_tag(:option, '')
    colored_thing.available_colors.each do |c|
      options = {}
      options[:value] = c.id
      options[:selected] = 'selected' if c.id == colored_thing.color_id

      options[:style] = "background-color: #{c.hexcode}; color: #{c.text_hexcode}"

      s << content_tag(:option, h(c.name), options)
    end
    s
  end

  def options_for_timeunits(selected = nil)
    options_for_select([[l('timelines.filter.time_relative.days'), 0],
                        [l('timelines.filter.time_relative.weeks'), '1'],
                        [l('timelines.filter.time_relative.months'), '2']],
                       selected)
  end

  def options_for_project_types
    ProjectType.all.map { |t| [t.name, t.id] }
  end

  def visible_parent_project(project)
    parent = project.parent

    while parent.present? && !parent.visible?
      parent = parent.parent
    end

    parent
  end

  def none_option
    result = [[l('timelines.filter.noneSelection'), -1]]
  end

  def filter_select_i18n_array_with_index_and_none(array, i18n_prefix)
    result = none_option
    index = -1
    result += array.map do |t|
      index += 1
      [l(i18n_prefix + t), index]
    end
  end

  def filter_select_with_none(collection, text, value)
    result = none_option
    result += filter_select(collection, text, value)
  end

  def filter_select(collection, text, value)
    collection.map do |t|
      [t.send(text), t.send(value)]
    end
  end

  def resolve_with_none_option(_const, collection)
    collection
  end

  def list_to_select_object_with_none(collection)
    collection = collection.map do |t|
      {
        name: t,
        id: t
      }
    end
    collection.unshift(
      name: l('timelines.filter.noneElement'),
      id: -1
    )
  end

  def internationalized_columns_select_object(collection)
    collection.map do |t|
      {
        name: l('timelines.filter.column.' + t),
        id: t
      }
    end
  end

  def internationalized_columns_select(collection)
    collection.map do |t|
      [l('timelines.filter.column.' + t), t]
    end
  end

  # Push timeline data to view as JSON via gon

  include Gon::GonHelpers

  def visible_timeline_paths(_visible_timelines = [])
    @visible_timelines.inject({}) do |timeline_paths, timeline|
      timeline_paths.merge(timeline.id => { path: project_timeline_path(@project, timeline) })
    end
  end

  def push_visible_timeline_paths(visible_timelines)
    gon.timelines = visible_timeline_paths visible_timelines
  end

  def push_current_timeline_id(id)
    gon.current_timeline_id = id
  end

  def push_timeline_options(timeline)
    project_id = timeline.project.identifier

    gon.timeline_options ||= {}
    gon.timeline_options[timeline.id] = timeline.options.reverse_merge(project_id: project_id)
  end

  def timeline_options
    OpenStruct.new @timeline.options
  end
end
