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

require "spec_helper"

RSpec.describe Rake::Task do
  shared_let(:custom_field) do
    create(:wp_custom_field, :list, name: "Bug found in version", possible_values: %w[1.0.x 2.0.x])
  end

  def observe(work_package, option_value)
    create(:custom_value,
           custom_field:,
           customized: work_package,
           value: custom_field.value_of(option_value).to_s)
  end

  def observed_in_version_ids(work_package)
    WorkPackageVersion.where(work_package:, kind: "observed_in").pluck(:version_id)
  end

  describe "bug_found_in_version:copy" do
    include_context "rake" do
      let(:task_name) { "bug_found_in_version:copy" }
    end

    it "copies a version found in the same project" do
      project = create(:project)
      version = create(:version, project:, name: "1.0.0")
      work_package = create(:work_package, project:)
      observe(work_package, "1.0.x")

      expect { subject.invoke }.to output(/Copied: 1/).to_stdout

      expect(observed_in_version_ids(work_package)).to contain_exactly(version.id)
    end

    it "does not copy a version from another, unshared project" do
      project = create(:project)
      other_project = create(:project)
      create(:version, project: other_project, name: "1.0.0") # sharing: "none" by default
      work_package = create(:work_package, project:)
      observe(work_package, "1.0.x")

      expect { subject.invoke }.to output(/Copied: 0.*Skipped \(no matching version\): 1/m).to_stdout

      expect(observed_in_version_ids(work_package)).to be_empty
    end

    it "copies a version shared from another project" do
      project = create(:project)
      other_project = create(:project)
      version = create(:version, project: other_project, name: "1.0.0", sharing: "system")
      work_package = create(:work_package, project:)
      observe(work_package, "1.0.x")

      expect { subject.invoke }.to output(/Copied: 1/).to_stdout

      expect(observed_in_version_ids(work_package)).to contain_exactly(version.id)
    end

    it "skips when the version name is ambiguous between two assignable versions" do
      project = create(:project)
      other_project = create(:project)
      create(:version, project:, name: "1.0.0")
      create(:version, project: other_project, name: "1.0.0", sharing: "system")
      work_package = create(:work_package, project:)
      observe(work_package, "1.0.x")

      expect { subject.invoke }
        .to output(/Copied: 0.*Skipped \(ambiguous - multiple versions share the name\): 1/m).to_stdout

      expect(observed_in_version_ids(work_package)).to be_empty
    end

    it "skips a work package that already has the matching observed_in_versions version" do
      project = create(:project)
      version = create(:version, project:, name: "1.0.0")
      work_package = create(:work_package, project:)
      observe(work_package, "1.0.x")
      create(:work_package_version, work_package:, version:, kind: "observed_in")

      expect { subject.invoke }.to output(/Copied: 0.*Skipped \(already observed\): 1/m).to_stdout

      expect(observed_in_version_ids(work_package)).to contain_exactly(version.id)
    end
  end
end
