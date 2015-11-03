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
  class ProjectSeeder

    def self.seed!
      # Careful: The seeding recreates the seeded project before it runs, so any changes
      # on the seeded project will be lost.
      puts ' ↳ Creating seeded project...'

      identifier = I18n.t('seeders.sample_data.project.identifier')

      if delete_me = Project.find_by(identifier: identifier)
        delete_me.destroy
      end

      project = Project.create(name: I18n.t('seeders.sample_data.project.name'),
                               identifier: identifier,
                               description: I18n.t('seeders.sample_data.project.description'),
                               types: Type.all,
                               is_public: true
                              )

      project.enabled_module_names += ['timelines']

      # project's repository
      repository = Repository::Subversion.create!(project: project,
                                                  url: 'file:///tmp/foo/bar.svn',
                                                  scm_type: 'existing')

      # create a default timeline that shows all our work packages
      timeline = Timeline.create
      timeline.project = project
      timeline.name = I18n.t('seeders.sample_data.timeline.name')
      timeline.options.merge!(zoom_factor: ['4'])
      timeline.save

      project
    end

  end
end
