# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
# ++

module DevelopmentData
  class WorkPackagesSeeder < Seeder
    def seed_data!
      print_status ' ↳ Creating development work packages...'

      print_status '   -Creating/Resetting development work packages'

      reset_work_packages
    end

    def applicable?
      WorkPackage.where(subject: work_package_subjects).empty?
    end

    private

    def reset_work_packages
      WorkPackage.where(subject: work_package_subjects).destroy_all

      work_package_attributes.map do |attributes|
        work_package = WorkPackage.new attributes

        if attributes[:subject] == '[dev] Defeat Bane'
          work_package.parent = WorkPackage.find_by(subject: '[dev] Save Gotham')
        end

        work_package.save!
        work_package
      end
    end

    def work_package_subjects
      ['[dev] Save Gotham', '[dev] Defeat Bane', '[dev] Find Waldo', '[dev] Organize game night']
    end

    def work_package_attributes
      work_package_data.map { _1.reverse_merge(base_work_package_data) }
    end

    def work_package_data
      [
        { subject: '[dev] Save Gotham',
          description: "Gotham is in trouble. It's your job to save it!",
          type: epic_type,
          priority: immediate_priority },
        { subject: '[dev] Defeat Bane',
          description: 'Must be stopped before Gotham is doomed.',
          priority: immediate_priority },
        { subject: '[dev] Find Waldo',
          description: 'This one is tricky!' },
        { subject: '[dev] Organize game night',
          description: 'Find a time that suits everyone.',
          status: in_progress_status }
      ]
    end

    def base_work_package_data
      {
        project:,
        author: admin_user,
        status: default_status,
        type: default_type,
        priority: default_priority
      }
    end

    def project
      @project ||= Project.find_by(identifier: 'dev-work-package-sharing')
    end

    def default_status
      @default_status ||= Status.default
    end

    def in_progress_status
      @in_progress_status ||= Status.find_by(name: 'In progress')
    end

    def default_type
      @default_type ||= Type.find_by(name: 'Task')
    end

    def epic_type
      @epic_type ||= Type.find_by(name: 'Epic')
    end

    def default_priority
      @default_priority ||= IssuePriority.default
    end

    def immediate_priority
      @immediate_priority ||= IssuePriority.find_by(name: 'Immediate')
    end
  end
end
