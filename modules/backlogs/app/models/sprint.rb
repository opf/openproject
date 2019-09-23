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

require 'date'

class Sprint < Version
  scope :open_sprints, lambda { |project|
    where(["versions.status = 'open' and versions.project_id = ?", project.id])
      .order(Arel.sql("COALESCE(start_date, CAST('4000-12-30' as date)) ASC, COALESCE(effective_date, CAST('4000-12-30' as date)) ASC"))
  }

  # null last ordering
  scope :order_by_date, -> {
    order Arel.sql("COALESCE(start_date, CAST('4000-12-30' as date)) ASC, COALESCE(effective_date, CAST('4000-12-30' as date)) ASC")
  }
  scope :order_by_name, -> {
    order Arel.sql("#{Version.table_name}.name ASC")
  }

  scope :apply_to, lambda { |project|
    where("#{Version.table_name}.project_id = #{project.id}" +
        " OR (#{Project.table_name}.status = #{Project::STATUS_ACTIVE} AND (" +
        " #{Version.table_name}.sharing = 'system'" +
        " OR (#{Project.table_name}.lft >= #{project.root.lft} AND #{Project.table_name}.rgt <= #{project.root.rgt} AND #{Version.table_name}.sharing = 'tree')" +
        " OR (#{Project.table_name}.lft < #{project.lft} AND #{Project.table_name}.rgt > #{project.rgt} AND #{Version.table_name}.sharing IN ('hierarchy', 'descendants'))" +
        " OR (#{Project.table_name}.lft > #{project.lft} AND #{Project.table_name}.rgt < #{project.rgt} AND #{Version.table_name}.sharing = 'hierarchy')" +
        '))')
      .includes(:project)
      .references(:projects)
  }

  scope :displayed_left, lambda { |project|
    joins(sanitize_sql_array([
      "LEFT OUTER JOIN (SELECT * from #{VersionSetting.table_name}" +
        ' WHERE project_id = ? ) version_settings' +
        ' ON version_settings.version_id = versions.id',
      project.id])
    )
      .where([
        '(version_settings.project_id = ? AND version_settings.display = ?)' +
          ' OR (version_settings.project_id is NULL)',
        project.id,
        VersionSetting::DISPLAY_LEFT
      ])
      .joins("
        LEFT OUTER JOIN (SELECT * FROM #{VersionSetting.table_name}) AS vs
        ON vs.version_id = #{Version.table_name}.id AND vs.project_id = #{Version.table_name}.project_id
      ") # next take only those versions which define 'display left' in their home project or the given project (or don't define anything)
      .where(
        "(version_settings.display = ? OR vs.display = ? OR vs.display IS NULL)",
        VersionSetting::DISPLAY_LEFT,
        VersionSetting::DISPLAY_LEFT
      )
  }

  scope :displayed_right, lambda { |project|
    where(['version_settings.project_id = ? AND version_settings.display = ?',
           project.id, VersionSetting::DISPLAY_RIGHT])
      .includes(:version_settings)
      .references(:version_settings)
  }

  def stories(project, options = {})
    Story.sprint_backlog(project, self, options)
  end

  def points
    stories.inject(0) { |sum, story| sum + story.story_points.to_i }
  end

  def has_wiki_page
    return false if wiki_page_title.blank?

    page = project.wiki.find_page(wiki_page_title)
    return false if !page

    template = project.wiki.find_page(Setting.plugin_openproject_backlogs['wiki_template'])
    return false if template && page.text == template.text

    true
  end

  def wiki_page
    return '' unless project.wiki

    update_attribute(:wiki_page_title, name) if wiki_page_title.blank?

    page = project.wiki.find_page(wiki_page_title)
    template = project.wiki.find_page(Setting.plugin_openproject_backlogs['wiki_template'])

    if template and not page
      page = project.wiki.pages.build(title: wiki_page_title)
      page.build_content(text: "h1. #{name}\n\n#{template.text}")
      page.save!
    end

    wiki_page_title
  end

  def days(cutoff = nil, alldays = false)
    # TODO: Assumes mon-fri are working days, sat-sun are not. This assumption
    # is not globally right, we need to make this configurable.
    cutoff = effective_date if cutoff.nil?

    (start_date..cutoff).select { |d| alldays || (d.wday > 0 and d.wday < 6) }
  end

  def has_burndown?
    !!(effective_date and start_date)
  end

  def activity
    bd = burndown('up')
    return false if bd.blank?

    # Assume a sprint is active if it's only 2 days old
    return true if bd.remaining_hours.size <= 2

    WorkPackage.exists?(['fixed_version_id = ? and ((updated_on between ? and ?) or (created_on between ? and ?))',
                         id, -2.days.from_now, Time.now, -2.days.from_now, Time.now])
  end

  def burndown(project, burn_direction = nil)
    return nil unless self.has_burndown?

    @cached_burndown ||= Burndown.new(self, project, burn_direction)
  end

  def self.generate_burndown(only_current = true)
    if only_current
      conditions = ['? BETWEEN start_date AND effective_date', Date.today]
    else
      conditions = '1 = 1'
    end

    Version.where(conditions).each(&:burndown)
  end

  def impediments(project)
    # for reasons beyond me,
    # the default_scope needs to be explicitly applied.
    Impediment.default_scope.where(fixed_version_id: self, project_id: project)
  end
end
