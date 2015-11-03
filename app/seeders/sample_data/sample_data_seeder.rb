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
module SampleData
  class SampleDataSeeder

    def self.seed!
      project = SampleData::ProjectSeeder.seed!

      SampleData::CustomFieldSeeder.seed!(project)
      SampleData::BoardSeeder.seed!(project)
      SampleData::WikiSeeder.seed!(project)
      SampleData::WorkPackageSeeder.new(project).seed!
      SampleData::NewsSeeder.seed!(project)

      puts "\n"
      puts " #{WorkPackage.where(project_id: project.id).count} issues created."
      puts " #{Message.joins(:board).where(boards: { project_id: project.id }).count} messages created."
      puts " #{News.where(project_id: project.id).count} news created."
      puts " #{WikiContent.joins(page: [:wiki]).where('wikis.project_id = ?', project.id).count} wiki contents created."
      puts " #{TimeEntry.where(project_id: project.id).count} time entries created."
      puts " #{Changeset.joins(:repository).where(repositories: { project_id: project.id }).count} changesets created."
      puts 'Sample data seeding...done.'
    end

  end
end
