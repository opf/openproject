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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module TestManagement
  module Automation
    class CaseCreator
      ROOT_FOLDER = "Automated"

      def initialize(user:, project:)
        @user = user
        @project = project
        @folders = {}
      end

      def call(record)
        project.tm_test_cases.create!(
          title: record.display_title.to_s.first(255),
          suite: folder_for(record.file),
          automated: true,
          automation_reference: record.reference.to_s.first(1024),
          author: user,
          status: "ready",
          priority: "medium"
        )
      end

      private

      attr_reader :user, :project

      def folder_for(file)
        @folders[file] ||= begin
          root = find_or_create_folder(ROOT_FOLDER, nil)
          file.present? ? find_or_create_folder(file.to_s.first(255), root) : root
        end
      end

      def find_or_create_folder(name, parent)
        project.tm_suites.find_or_create_by!(name:, parent_id: parent&.id)
      end
    end
  end
end
