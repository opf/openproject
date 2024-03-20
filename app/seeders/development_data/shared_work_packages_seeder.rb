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
  class SharedWorkPackagesSeeder < Seeder
    def seed_data!
      print_status ' ↳ Creating development work packages...'

      print_status '   -Creating/Resetting development work packages'
      reset_work_packages

      print_status '   -Sharing work packages'
      share_work_packages
    end

    def applicable?
      return false if project.nil?

      WorkPackage.where(subject: work_package_subjects).empty?
    end

    private

    def work_package_subjects
      ['[dev] Save Gotham', '[dev] Defeat Bane', '[dev] Find Waldo', '[dev] Organize game night']
    end

    def reset_work_packages
      WorkPackage.where(subject: work_package_subjects).destroy_all

      work_package_attributes.map do |attributes|
        identifier = attributes.delete(:reference)

        work_package = WorkPackage.new attributes

        if identifier == :defeat_bane
          work_package.parent = seed_data.find_reference(:save_gotham)
        end

        work_package.save!
        seed_data.store_reference(identifier, work_package)

        work_package
      end
    end

    # rubocop:disable Metrics/AbcSize
    def work_package_attributes
      [
        {
          project:,
          author:,
          subject: '[dev] Save Gotham',
          reference: :save_gotham,
          description: "Gotham is in trouble. It's your job to save it!",
          status: seed_data.find_reference(:default_status_new),
          type: seed_data.find_reference(:default_type_epic, :default_type_phase),
          priority: seed_data.find_reference(:default_priority_immediate, :default_priority_high)
        },
        {
          project:,
          author:,
          subject: '[dev] Defeat Bane',
          reference: :defeat_bane,
          description: 'Must be stopped before Gotham is doomed.',
          status: seed_data.find_reference(:default_status_new),
          type: seed_data.find_reference(:default_type_task),
          priority: seed_data.find_reference(:default_priority_immediate, :default_priority_high)
        },
        {
          project:,
          author:,
          subject: '[dev] Find Waldo',
          reference: :find_waldo,
          status: seed_data.find_reference(:default_status_new),
          type: seed_data.find_reference(:default_type_task),
          description: 'This one is tricky!',
          priority: IssuePriority.default
        },
        {
          project:,
          author:,
          subject: '[dev] Organize game night',
          reference: :organize_game_night,
          description: 'Find a time that suits everyone.',
          status: seed_data.find_reference(:default_status_in_progress),
          type: seed_data.find_reference(:default_type_task),
          priority: IssuePriority.default
        }
      ]
    end
    # rubocop:enable Metrics/AbcSize

    def project
      @project ||= seed_data.find_reference(:dev_work_package_sharing, default: nil)
    end

    def author
      @author ||= admin_user
    end

    def share_work_packages
      work_package_sharing_attributes.each do |sharing_attributes|
        share(**sharing_attributes)
      end
    end

    def work_package_sharing_attributes
      [
        {
          work_package: seed_data.find_reference(:defeat_bane),
          role: seed_data.find_reference(:default_role_work_package_editor)
        },
        {
          work_package: seed_data.find_reference(:organize_game_night),
          role: seed_data.find_reference(:default_role_work_package_commenter)
        },
        {
          work_package: seed_data.find_reference(:find_waldo),
          role: seed_data.find_reference(:default_role_work_package_viewer)
        }
      ]
    end

    def share(work_package:, role:)
      Member.create!(project:,
                     principal:,
                     entity: work_package,
                     roles: Array(role))
    end

    def principal
      @principal ||= seed_data.find_reference(:work_packager)
    end
  end
end
