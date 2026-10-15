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

RSpec.describe ProjectType, "activating an owned variant" do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:type) { create(:type, name: "Bug") }

  it "activates a variant the project owns" do
    ours = create(:project_owned_type_variant, type:, project:)

    expect(build(:project_type, project:, type:, variant: ours)).to be_valid
  end

  it "activates a global variant anywhere" do
    global = create(:type_variant, type:)

    expect(build(:project_type, project:, type:, variant: global)).to be_valid
  end

  # The acceptance criterion: an owned variant is only ever activated in the project owning it.
  # Enforced on the record rather than only in the UI, so no service or console call slips past.
  it "refuses a variant another project owns" do
    theirs = create(:project_owned_type_variant, type:, project: other_project)

    project_type = build(:project_type, project:, type:, variant: theirs)

    expect(project_type).not_to be_valid
    expect(project_type.errors[:variant]).to include("must not be a variant another project owns.")
  end

  it "refuses it for an instance administrator too, who can see every variant" do
    theirs = create(:project_owned_type_variant, type:, project: other_project)

    expect { create(:project_type, project:, type:, variant: theirs) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end
end
