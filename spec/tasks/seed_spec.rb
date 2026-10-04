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

require "spec_helper"

RSpec.describe "db:seed" do # rubocop:disable RSpec/DescribeClass
  include_context "rake"
  let(:task_path) { "lib/tasks/seed" }

  describe "db:seed:only" do
    before do
      allow($stdout).to receive(:puts)
    end

    it "fails if seeder is not specified" do
      expect { subject.invoke }
        .to raise_error "Specify a seeder class name 'rake db:seed:only[Some::ClassName]'"
    end

    it "runs the specified seeder" do
      subject.invoke("BasicData::WorkPackageRoleSeeder")
      expect(WorkPackageRole.count).to eq 3
    end

    it "displays an error if the given seeder class name does not exist" do
      expect { subject.invoke("BasicData::BadSeeder") }
        .to raise_error ArgumentError, "No seeder with class name BasicData::BadSeeder"
    end

    it "displays an error if the given class name is not a seeder" do
      expect { subject.invoke("Queries::Queries::QueryQuery") }
        .to raise_error ArgumentError, "Queries::Queries::QueryQuery is not a seeder"
    end

    it "does not raise an error on only invoking the project seeder but also does not create projects" do
      # The project seeder requires the "project admin" role to be present.
      # It used to fail hard in the absence of that role.
      # But since people might completely remove the role from the database and
      # seeds are run for every deployment, executing the task needs to be stable.
      expect { subject.invoke("DevelopmentData::ProjectsSeeder") }
        .not_to raise_error ActiveRecord::RecordNotFound
      expect(Project.count).to eq 0
    end
  end
end
