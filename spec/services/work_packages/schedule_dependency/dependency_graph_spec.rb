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

require "rails_helper"

RSpec.describe WorkPackages::ScheduleDependency::DependencyGraph do
  create_shared_association_defaults_for_work_package_factory

  describe "#depends_on?" do
    context "with simple linear predecessor/successor dependencies" do
      # create a linear dependency: wp1 -> wp2 -> wp3
      let_work_packages(<<~TABLE)
        hierarchy | scheduling mode | successors
        wp1       | manual          | wp2
        wp2       | automatic       | wp3
        wp3       | automatic       |
      TABLE

      let(:schedule_dependency) { WorkPackages::ScheduleDependency.new([wp1]) }
      let(:wp1_dependency) { WorkPackages::ScheduleDependency::Dependency.new(wp1, schedule_dependency) }
      let(:wp2_dependency) { WorkPackages::ScheduleDependency::Dependency.new(wp2, schedule_dependency) }
      let(:wp3_dependency) { WorkPackages::ScheduleDependency::Dependency.new(wp3, schedule_dependency) }
      let(:dependencies) { [wp1_dependency, wp2_dependency, wp3_dependency] }

      it "returns true when a given work package depends on the work package from the given dependency" do
        dependency_graph = described_class.new(dependencies)

        expect(dependency_graph.depends_on?(wp1, wp1_dependency)).to be(false)
        expect(dependency_graph.depends_on?(wp1, wp2_dependency)).to be(false)
        expect(dependency_graph.depends_on?(wp1, wp3_dependency)).to be(false)

        expect(dependency_graph.depends_on?(wp2, wp1_dependency)).to be(true)
        expect(dependency_graph.depends_on?(wp2, wp2_dependency)).to be(false)
        expect(dependency_graph.depends_on?(wp2, wp3_dependency)).to be(false)

        expect(dependency_graph.depends_on?(wp3, wp1_dependency)).to be(true)
        expect(dependency_graph.depends_on?(wp3, wp2_dependency)).to be(true)
        expect(dependency_graph.depends_on?(wp3, wp3_dependency)).to be(false)
      end
    end

    context "with circular dependencies between two work packages" do
      # Create circular dependency: wp1 -> wp2 -> wp1
      let_work_packages(<<~TABLE)
        subject | scheduling mode | successors
        wp1     | automatic       | wp2
        wp2     | automatic       | wp1
      TABLE

      let(:schedule_dependency) { WorkPackages::ScheduleDependency.new([wp1]) }
      let(:wp1_dependency) { WorkPackages::ScheduleDependency::Dependency.new(wp1, schedule_dependency) }
      let(:wp2_dependency) { WorkPackages::ScheduleDependency::Dependency.new(wp2, schedule_dependency) }
      let(:dependencies) { [wp1_dependency, wp2_dependency] }

      it "avoids infinite recursion and returns true when given a dependent dependency" do
        dependency_graph = described_class.new(dependencies)

        expect(dependency_graph.depends_on?(wp1, wp1_dependency)).to be(false)
        expect(dependency_graph.depends_on?(wp1, wp2_dependency)).to be(true)

        expect(dependency_graph.depends_on?(wp2, wp1_dependency)).to be(true)
        expect(dependency_graph.depends_on?(wp2, wp2_dependency)).to be(false)
      end
    end

    context "with circular dependency between one work package" do
      # Create circular dependency: wp1 -> wp2 -> wp1
      let_work_packages(<<~TABLE)
        subject | scheduling mode | successors
        wp1     | automatic       | wp1
      TABLE

      let(:schedule_dependency) { WorkPackages::ScheduleDependency.new([wp1]) }
      let(:wp1_dependency) { WorkPackages::ScheduleDependency::Dependency.new(wp1, schedule_dependency) }
      let(:dependencies) { [wp1_dependency] }

      it "avoids infinite recursion and returns false when given itsef as a dependency" do
        dependency_graph = described_class.new(dependencies)

        expect(dependency_graph.depends_on?(wp1, wp1_dependency)).to be(false)
      end
    end
  end
end
