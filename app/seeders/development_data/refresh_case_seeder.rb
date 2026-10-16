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
  # The Refresh work package demo (ai_refresh_case): a conference work package whose comments
  # moved on while its subject, description and fields did not. Runs after the demo data.
  class RefreshCaseSeeder < Seeder
    def seed_data!
      print_status "   -Preparing the Refresh work package demo" do
        Journal::NotificationConfiguration.with(false) do
          update_work_package
          add_comments
          add_children
        end
      end
    end

    def applicable?
      work_package.present? &&
        seed_data.all_references_exist?(comments.pluck("author")) &&
        Journal.where(journable: work_package).where(notes: comments.first["notes"]).none?
    end

    private

    def update_work_package
      work_package.update!(
        subject: value("subject"),
        description: value("description"),
        priority: seed_data.find_reference(value("priority")),
        responsible: seed_data.find_reference(value("responsible"), default: nil)
      )
    end

    def add_comments
      comments.each do |comment|
        author = seed_data.find_reference(comment["author"])
        work_package.reload.add_journal(user: author, notes: comment["notes"])
        work_package.save_journals
      end
    end

    def add_children
      Array(value("children")).each do |child|
        WorkPackage.create!(subject: child["subject"], type: seed_data.find_reference(child["type"]), **child_defaults)
      end
    end

    def child_defaults
      { project: work_package.project, parent: work_package, author: work_package.author,
        status: seed_data.find_reference(:default_status_new), priority: work_package.priority }
    end

    def comments
      Array(value("comments"))
    end

    def value(key)
      seed_data.lookup("ai_refresh_case.#{key}")
    end

    def work_package
      seed_data.find_reference(value("work_package"), default: nil)
    end
  end
end
