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

# frozen_string_literal: true

require "spec_helper"

RSpec.describe ProjectTypeScheme do
  let(:project) { create(:project) }
  let(:scheme) { create(:type_scheme) }

  it "is valid with a project and an active scheme" do
    expect(described_class.new(project:, scheme:)).to be_valid
  end

  it "allows only one scheme per project" do
    described_class.create!(project:, scheme:)
    other = described_class.new(project:, scheme: create(:type_scheme))
    expect(other).not_to be_valid
    expect(other.errors[:project_id]).to be_present
  end

  it "rejects an inactive scheme" do
    inactive = create(:type_scheme, active: false)
    assignment = described_class.new(project:, scheme: inactive)
    expect(assignment).not_to be_valid
    expect(assignment.errors[:scheme]).to be_present
  end
end
