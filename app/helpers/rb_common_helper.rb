#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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

module RbCommonHelper
  def assignee_id_or_empty(story)
    story.assigned_to_id.to_s
  end

  def assignee_name_or_empty(story)
    story.blank? || story.assigned_to.blank? ? '' : "#{story.assigned_to.firstname} #{story.assigned_to.lastname}"
  end

  def blocks_ids(ids)
    ids.sort.join(',')
  end

  def build_inline_style(task)
    is_assigned_task?(task) ? color_style(task) : ''
  end

  def color_style(task)
    background_color = get_backlogs_preference(task.assigned_to, :task_color)

    "style=\"background-color:#{background_color};\"".html_safe
  end

  def color_contrast_class(task)
    if is_assigned_task?(task)
      color_contrast(background_color_hex(task)) ? 'light' : 'dark'
    else
      ''
    end
  end

  # Return true if the difference between two colors
  # matches the W3C recommendations for readability
  # See http://www.wat-c.org/tools/CCA/1.1/
  def colors_diff_ok?(color_1, color_2)
    cont, bright = find_color_diff color_1, color_2
    (cont > 500) && (bright > 125) # Acceptable diff according to w3c
  end

  def color_contrast(color)
    _, bright = find_color_diff 0x000000, color
    (bright > 128)
  end

  # Return the contrast and brightness difference between two RGB values
  def find_color_diff(c1, c2)
    r1, g1, b1 = break_color c1
    r2, g2, b2 = break_color c2
    cont_diff = (r1 - r2).abs + (g1 - g2).abs + (b1 - b2).abs # Color contrast
    bright1 = (r1 * 299 + g1 * 587 + b1 * 114) / 1000
    bright2 = (r2 * 299 + g2 * 587 + b2 * 114) / 1000
    brt_diff = (bright1 - bright2).abs # Color brightness diff
    [cont_diff, brt_diff]
  end

  # Break a color into the R, G and B components
  def break_color(rgb)
    r = (rgb & 0xff0000) >> 16
    g = (rgb & 0x00ff00) >> 8
    b = rgb & 0x0000ff
    [r, g, b]
  end

  def is_assigned_task?(task)
    !(task.blank? || task.assigned_to.blank?)
  end

  def background_color_hex(task)
    background_color = get_backlogs_preference(task.assigned_to, :task_color)
    background_color_hex = background_color.sub(/\#/, '0x').hex
  end

  def id_or_empty(item)
    item.id.to_s
  end

  def shortened_id(record)
    id = record.id.to_s
    (id.length > 8 ? "#{id[0..1]}...#{id[-4..-1]}" : id)
  end

  def work_package_link_or_empty(work_package)
    modal_link_to_work_package(work_package.id, work_package, class: 'prevent_edit') unless work_package.new_record?
  end

  def modal_link_to_work_package(title, work_package, options = {})
    modal_link_to(title, work_package_path(work_package), options)
  end

  def modal_link_to(title, path, options = {})
    html_id = "modal_work_package_#{SecureRandom.hex(10)}"
    link_to(title, path, options.merge(id: html_id, target: '_blank'))
  end

  def sprint_link_or_empty(item)
    item_id = item.id.to_s
    text = (item_id.length > 8 ? "#{item_id[0..1]}...#{item_id[-4..-1]}" : item_id)
    if item.new_record?
      ''
    else
      link_to(text, backlogs_project_sprint_path(id: item.id, project_id: item.project.identifier), class: 'prevent_edit')
    end
  end

  def mark_if_closed(story)
    !story.new_record? && work_package_status_for_id(story.status_id).is_closed? ? 'closed' : ''
  end

  def story_points_or_empty(story)
    story.story_points.to_s
  end

  def status_id_or_default(story)
    story.new_record? ? new_record_status.id : story.status_id
  end

  def status_label_or_default(story)
    story.new_record? ? new_record_status.name : h(work_package_status_for_id(story.status_id).name)
  end

  def sprint_html_id_or_empty(sprint)
    sprint.id.nil? ? '' : "sprint_#{sprint.id}"
  end

  def story_html_id_or_empty(story)
    story.id.nil? ? '' : "story_#{story.id}"
  end

  def type_id_or_empty(story)
    story.type_id.to_s
  end

  def type_name_or_empty(story)
    story.type.nil? ? '' : h(backlogs_types_by_id[story.type_id].name)
  end

  def updated_on_with_milliseconds(story)
    date_string_with_milliseconds(story.updated_on, 0.001) unless story.blank?
  end

  def date_string_with_milliseconds(d, add = 0)
    return '' if d.blank?
    d.strftime('%B %d, %Y %H:%M:%S') + '.' + (d.to_f % 1 + add).to_s.split('.')[1]
  end

  def remaining_hours(item)
    item.remaining_hours.blank? || item.remaining_hours == 0 ? '' : item.remaining_hours
  end

  def available_story_types
    @available_story_types ||= begin
      types = story_types & @project.types if @project

      types
    end
  end

  def available_statuses_by_type
    @available_statuses_by_type ||= begin
      available_statuses_by_type = Hash.new do |type_hash, type|
        type_hash[type] = Hash.new do |status_hash, status|
          status_hash[status] = [status]
        end
      end

      workflows = all_workflows

      workflows.each do |w|
        type_status = available_statuses_by_type[story_types_by_id[w.type_id]][w.old_status]

        type_status << w.new_status unless type_status.include?(w.new_status)
      end

      available_statuses_by_type
    end
  end

  def show_burndown_link(sprint)
    ret = ''

    ret += link_to(l('backlogs.show_burndown_chart'),
                   {},
                   class: 'show_burndown_chart button')

    ret += nonced_javascript_tag "
            jQuery(document).ready(function(){
              var burndown = RB.Factory.initialize(RB.Burndown, jQuery('.show_burndown_chart'));
              burndown.setSprintId(#{sprint.id});
            });"
    ret.html_safe
  end

  private

  def new_record_status
    @new_record_status ||= all_work_package_status.first
  end

  def default_work_package_status
    @default_work_package_status ||= all_work_package_status.detect(&:is_default)
  end

  def work_package_status_for_id(id)
    @all_work_package_status_by_id ||= begin
      all_work_package_status.inject({}) do |mem, status|
        mem[status.id] = status
        mem
      end
    end

    @all_work_package_status_by_id[id]
  end

  def all_workflows
    @all_workflows ||= Workflow.includes([:new_status, :old_status])
                       .where(role_id: User.current.roles_for_project(@project).map(&:id),
                              type_id: story_types.map(&:id))
  end

  def all_work_package_status
    @all_work_package_status ||= Status.order('position ASC')
  end

  def backlogs_types
    @backlogs_types ||= begin
      backlogs_ids = Setting.plugin_openproject_backlogs['story_types']
      backlogs_ids << Setting.plugin_openproject_backlogs['task_type']

      Type.where(id: backlogs_ids).order('position ASC')
    end
  end

  def backlogs_types_by_id
    @backlogs_types_by_id ||= begin
      backlogs_types.inject({}) do |mem, type|
        mem[type.id] = type
        mem
      end
    end
  end

  def story_types
    @story_types ||= begin
      backlogs_type_ids = Setting.plugin_openproject_backlogs['story_types'].map(&:to_i)

      backlogs_types.select { |t| backlogs_type_ids.include?(t.id) }
    end
  end

  def story_types_by_id
    @story_types_by_id ||= begin
      story_types.inject({}) do |mem, type|
        mem[type.id] = type
        mem
      end
    end
  end

  def get_backlogs_preference(assignee, attr)
    assignee.is_a?(User) ? assignee.backlogs_preference(attr) : '#24B3E7'
  end

  def template_story
    Story.new.tap do |s|
      s.type = available_story_types.first
    end
  end
end
