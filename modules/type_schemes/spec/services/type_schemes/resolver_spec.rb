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

RSpec.describe TypeSchemes::Resolver do
  let(:project) { create(:project, types: [epic, story, bug]) }
  let(:epic)  { create(:type, name: "Epic") }
  let(:story) { create(:type, name: "Story") }
  let(:bug)   { create(:type, name: "Bug") }

  it "returns nil and native types without a scheme" do
    expect(described_class.for_project(project)).to be_nil
    expect(described_class.allowed_types(project)).to match_array([epic, story, bug])
  end

  context "with an assigned scheme [story*, epic]" do
    before do
      scheme = create(:type_scheme, types: [story, epic])
      ProjectTypeScheme.create!(project:, scheme:)
    end

    it "filters, orders and puts default first" do
      expect(described_class.allowed_types(project).to_a).to eq([story, epic])
    end

    it "falls back to native types when scheme types are not enabled in the project" do
      other = create(:project, types: [bug])
      ProjectTypeScheme.create!(project: other, scheme: TypeScheme.last)
      expect(described_class.allowed_types(other).to_a).to eq([bug])
    end

    it "ignores inactive schemes" do
      TypeScheme.last.update_columns(active: false)
      expect(described_class.for_project(project)).to be_nil
    end
  end
end
