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

RSpec.describe WorkPackageAssociatedVersion do
  subject(:record) { described_class.new(work_package:, version:, kind: "target") }

  let(:work_package) { create(:work_package) }
  let(:version) { create(:version, project: work_package.project) }

  describe "associations" do
    it { is_expected.to belong_to(:work_package) }
    it { is_expected.to belong_to(:version) }
  end

  describe "validations" do
    it { is_expected.to be_valid }

    it "is invalid with an unknown kind" do
      record.kind = "unknown"
      expect(record).not_to be_valid
      expect(record.errors[:kind]).to be_present
    end

    it "is valid with kind 'target'" do
      record.kind = "target"
      expect(record).to be_valid
    end

    it "is valid with kind 'observed_in'" do
      record.kind = "observed_in"
      expect(record).to be_valid
    end
  end

  describe "kind scoping via through associations" do
    let(:other_version) { create(:version, project: work_package.project) }

    before do
      described_class.create!(work_package:, version:, kind: "target")
      described_class.create!(work_package:, version: other_version, kind: "observed_in")
    end

    it "target version appears in target_versions but not observed_in_versions" do
      expect(work_package.target_versions).to include(version)
      expect(work_package.observed_in_versions).not_to include(version)
    end

    it "observed_in version appears in observed_in_versions but not target_versions" do
      expect(work_package.observed_in_versions).to include(other_version)
      expect(work_package.target_versions).not_to include(other_version)
    end

    it "all versions appear in associated_versions" do
      expect(work_package.associated_versions).to include(version, other_version)
    end
  end
end
