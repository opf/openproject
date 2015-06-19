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

class PlanningComparisonService
  @@journal_sql = <<SQL
      select #{Journal.table_name}.id
        from #{Journal.table_name}
         inner join (select journable_id, max(created_at) as latest_date, max(id) as latest_id
                       from #{Journal.table_name}
                      where #{Journal.table_name}.created_at <= ?
                        and #{Journal.table_name}.journable_type = 'WorkPackage'
                        and #{Journal.table_name}.journable_id in (?)
                   group by #{Journal.table_name}.journable_id) as latest
                 on #{Journal.table_name}.journable_id=latest.journable_id
         where #{Journal.table_name}.created_at=latest.latest_date
           and #{Journal.table_name}.id=latest.latest_id;
SQL
  @@mapped_attributes = Journal::WorkPackageJournal.journaled_attributes.map { |attribute| "#{Journal::WorkPackageJournal.table_name}.#{attribute}" }.join ','

  @@work_package_select = <<SQL
      Select #{Journal.table_name}.journable_id as id,
             #{Journal.table_name}.created_at as created_at,
             #{Journal.table_name}.created_at as updated_at,
             #{@@mapped_attributes}
        from #{Journal::WorkPackageJournal.table_name}
        left join #{Journal.table_name}
               on #{Journal.table_name}.id = #{Journal::WorkPackageJournal.table_name}.journal_id
       where #{Journal::WorkPackageJournal.table_name}.journal_id in (?)
SQL

  # there is currently no possibility to compare two given dates:
  # the comparison always works on the current date, filters the current workpackages
  # and returns the state of these work_packages at the given time
  # filters are given in the format expected by Query and are just passed through to query
  def self.compare(projects, at_time, filter = {})
    # The query uses three steps to find the journalized entries for the filtered workpackages
    # at the given point in time:
    # 1 filter the ids using query
    # 2 find out the latest journal-entries for the given date belonging to the filtered ids
    # 3 fetch the data for these journals from Journal::WorkPackageData
    # 4 fill theses journal-data into a workpackage

    # 1 either filter the ids using the given filter or pluck all work_package-ids from the project
    work_package_ids = if filter.has_key? :f
                         filtered_work_packages(projects, filter)
                       else
                         unfiltered_work_packages(projects)
                       end

    # 2 fetch latest journal-entries for the given time
    journal_ids = Journal.find_by_sql([@@journal_sql, at_time, work_package_ids])
                  .map(&:id)

    # 3&4 fetch the journaled data and make rails think it is actually a work_package
    work_packages = WorkPackage.find_by_sql([@@work_package_select, journal_ids])

    restore_references(work_packages)
  end

  protected

  def self.filtered_work_packages(projects, filter)
    work_package_scope = WorkPackage.scoped
                         .joins(:status)
                         .joins(:project) # query doesn't provide these joins itself...
                         .for_projects(projects)

    query = Query.new name: 'generated-query'
    query.add_filters(filter[:f], filter[:op], filter[:v])

    work_package_scope.with_query(query)
      .pluck(:id)
  end

  def self.unfiltered_work_packages(projects)
    WorkPackage.for_projects(projects).pluck(:id)
  end

  # This is a very crude way to work around n+1-issues, that are
  # introduced by the json/xml-rendering
  # the simple .includes does not work the work due to the find_by_sql
  def self.restore_references(work_packages)
    projects = resolve_projects(work_packages)
    types    = resolve_types(work_packages)
    statuses = resolve_statuses(work_packages)

    work_packages.each do |wp|
      wp.project = projects[wp.project_id]
      wp.type    = types[wp.type_id]
      wp.status  = statuses[wp.status_id]
    end

    work_packages
  end

  def self.resolve_projects(work_packages)
    project_ids = work_packages.map(&:project_id).uniq.compact
    projects  = Hash[Project.find(project_ids).map { |wp| [wp.id, wp] }]
  end

  def self.resolve_types(work_packages)
    type_ids  = work_packages.map(&:type_id).uniq.compact
    types     = Hash[Type.find(type_ids).map { |type| [type.id, type] }]
  end

  def self.resolve_statuses(work_packages)
    status_ids = work_packages.map(&:status_id).uniq.compact
    statuses  = Hash[Status.find(status_ids).map { |status| [status.id, status] }]
  end
end
