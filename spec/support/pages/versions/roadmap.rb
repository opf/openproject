# frozen_string_literal: true

# -- copyright
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
# ++

require "support/pages/page"

module Pages
  module Versions
    class Roadmap < Pages::Page
      attr_reader :project

      def initialize(project:)
        super()

        @project = project
      end

      def apply_filter(filter_name)
        within "#menu-sidebar" do
          check filter_name
          click_on "Apply"
        end
      end

      def remove_filter(filter_name)
        within "#menu-sidebar" do
          uncheck filter_name
          click_on "Apply"
        end
      end

      def expect_filter_set(filter_name)
        within "#menu-sidebar" do
          expect(page).to have_checked_field(filter_name)
        end
      end

      def expect_filter_not_set(filter_name)
        within "#menu-sidebar" do
          expect(page).to have_no_checked_field(filter_name)
        end
      end

      def expect_versions_listed(*versions)
        within "#roadmap" do
          versions.each do |version|
            expect(page).to have_content version.name
          end
        end
      end

      def expect_versions_not_listed(*versions)
        within "#roadmap" do
          versions.each do |version|
            expect(page).to have_no_content version.name
          end
        end
      end

      def path
        project_roadmap_path(project)
      end
    end
  end
end
