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

require "spec_helper"

RSpec.describe Queries::WorkPackages::Filter::BacklogInboxFilter do
  it_behaves_like "basic query filter" do
    let(:type) { :list }
    let(:class_key) { :backlog_inbox }
    let(:model) { WorkPackage }
    let(:project_permissions) { [:view_sprints] }

    current_user { build_stubbed(:user) }

    before do
      mock_permissions_for current_user do |mock|
        if project
          mock.allow_in_project(*project_permissions, project:)
        else
          mock.allow_in_project(*project_permissions, project: build_stubbed(:project))
        end
      end
    end

    describe "#available?" do
      context "when in a project and the user has the permission" do
        it "is true" do
          expect(instance).to be_available
        end
      end

      context "when in a project and the user lacks the permission" do
        let(:project_permissions) { [] }

        it "is false" do
          expect(instance).not_to be_available
        end
      end

      context "when outside a project and the user has the permission" do
        let(:project) { nil }

        it "is true" do
          expect(instance).to be_available
        end
      end

      context "when outside a project and the user lacks the permission" do
        let(:project) { nil }
        let(:project_permissions) { [] }

        it "is false" do
          expect(instance).not_to be_available
        end
      end
    end

    describe "#where" do
      context 'with operator "=" and value "t"' do
        let(:operator) { "=" }
        let(:values) { [OpenProject::Database::DB_VALUE_TRUE] }

        it "filters to work packages with no sprint and no bucket" do
          expect(instance.where).to eq(
            "work_packages.sprint_id IS NULL AND work_packages.backlog_bucket_id IS NULL"
          )
        end
      end

      context 'with operator "=" and value "f"' do
        let(:operator) { "=" }
        let(:values) { [OpenProject::Database::DB_VALUE_FALSE] }

        it "excludes inbox work packages" do
          expect(instance.where).to eq(
            "work_packages.sprint_id IS NOT NULL OR work_packages.backlog_bucket_id IS NOT NULL"
          )
        end
      end
    end
  end
end
