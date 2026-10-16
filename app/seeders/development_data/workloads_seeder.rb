# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
#++

module DevelopmentData
  # Open work packages of the COMMS developers in the demo project, so that their workloads
  # differ. Runs after the demo data, which creates the project.
  class WorkloadsSeeder < Seeder
    def seed_data!
      print_status "   -Creating the developers' work packages" do
        project = self.project
        seed_data.each("development_workloads") do |workload|
          assignee = seed_data.find_reference(workload["assigned_to"])
          Array(workload["subjects"]).each { |subject| create_work_package(project, subject, assignee) }
        end
      end
    end

    def applicable?
      project.present? && subjects.any? && WorkPackage.where(subject: subjects).none? &&
        seed_data.all_references_exist?(assignee_references)
    end

    private

    def create_work_package(project, subject, assignee)
      WorkPackage.create!(
        project:,
        author: admin_user,
        subject:,
        assigned_to: assignee,
        status: seed_data.find_reference(:default_status_new),
        type: seed_data.find_reference(:default_type_task),
        priority: IssuePriority.default
      )
    end

    def workloads
      Array(seed_data.lookup("development_workloads"))
    end

    def subjects
      workloads.flat_map { Array(it["subjects"]) }
    end

    def assignee_references
      workloads.pluck("assigned_to")
    end

    def project
      Project.find_by(identifier: "demo-project")
    end
  end
end
