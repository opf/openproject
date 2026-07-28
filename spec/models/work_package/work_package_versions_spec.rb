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

RSpec.describe WorkPackage, "legacy version_id mirror" do
  let(:project) { create(:project) }
  let!(:lower_version) { create(:version, project:) }
  let!(:higher_version) { create(:version, project:) }
  let(:work_package) { create(:work_package, project:) }

  # The interim primary version is `target_versions.first`, which reads the
  # lowest version id. The mirror column must agree regardless of the order
  # the target versions were assigned in.
  it "mirrors the lowest target version id regardless of assignment order" do
    work_package.target_version_ids_replacements = [higher_version.id, lower_version.id]
    work_package.save!

    expect(work_package.reload.version_id).to eq(lower_version.id)
    expect(work_package.version_id).to eq(work_package.target_versions.first.id)
  end

  it "clears the mirror when all target versions are removed" do
    work_package.target_version_ids_replacements = [lower_version.id]
    work_package.save!

    work_package.target_version_ids_replacements = []
    work_package.save!

    expect(work_package.reload.version_id).to be_nil
  end
end
