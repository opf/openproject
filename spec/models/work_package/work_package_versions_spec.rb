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

RSpec.describe WorkPackage, "target versions" do
  let(:project) { create(:project) }
  let!(:lower_version) { create(:version, project:) }
  let!(:higher_version) { create(:version, project:) }
  let(:work_package) { create(:work_package, project:) }

  it "returns target versions in id order even when preloaded" do
    work_package.target_version_ids_replacements = [higher_version.id, lower_version.id]
    work_package.save!

    preloaded = described_class.where(id: work_package.id).includes(:target_versions).first
    expect(preloaded.target_versions.map(&:id)).to eq([lower_version.id, higher_version.id])
  end

  it "does not write the deprecated version_id column" do
    work_package.target_version_ids_replacements = [lower_version.id]
    work_package.save!

    expect(work_package.reload.version_id).to be_nil
  end

  it "clears the target versions when they are replaced by an empty set" do
    work_package.target_version_ids_replacements = [lower_version.id]
    work_package.save!

    work_package.target_version_ids_replacements = []
    work_package.save!

    expect(work_package.reload.target_versions).to be_empty
  end
end

RSpec.describe WorkPackage, "observed in versions" do
  let(:project) { create(:project) }
  let!(:lower_version) { create(:version, project:) }
  let!(:higher_version) { create(:version, project:) }
  let(:work_package) { create(:work_package, project:) }

  it "returns observed in versions in id order even when preloaded" do
    work_package.observed_in_version_ids_replacements = [higher_version.id, lower_version.id]
    work_package.save!

    preloaded = described_class.where(id: work_package.id).includes(:observed_in_versions).first
    expect(preloaded.observed_in_versions.map(&:id)).to eq([lower_version.id, higher_version.id])
  end
end
