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
    let!(:scheme) { create(:type_scheme, types: [story, epic]) }

    before { ProjectTypeScheme.create!(project:, scheme:) }

    it "filters, orders and puts default first" do
      expect(described_class.allowed_types(project).to_a).to eq([story, epic])
    end

    it "falls back to native types when scheme types are not enabled in the project" do
      other = create(:project, types: [bug])
      ProjectTypeScheme.create!(project: other, scheme:)
      expect(described_class.allowed_types(other).to_a).to eq([bug])
    end

    it "ignores inactive schemes" do
      scheme.update_columns(active: false)
      expect(described_class.for_project(project)).to be_nil
      expect(described_class.allowed_types(project)).to match_array([epic, story, bug])
    end
  end

  context "when the default item has the higher position (epic, story*)" do
    let(:scheme) do
      create(:type_scheme, types: [epic, story]).tap do |s|
        s.items.each { |i| i.update_columns(is_default: i.type_id == story.id) }
      end
    end

    before { ProjectTypeScheme.create!(project:, scheme:) }

    it "puts the default first regardless of position" do
      expect(described_class.allowed_types(project).to_a).to eq([story, epic])
    end
  end

  context "with scheme [story*, epic, bug]" do
    let(:scheme) { create(:type_scheme, types: [story, epic, bug]) }

    before { ProjectTypeScheme.create!(project:, scheme:) }

    it "follows position after the default" do
      expect(described_class.allowed_types(project).to_a).to eq([story, epic, bug])
    end
  end

  context "with scheme [epic, story*]" do
    let(:scheme) do
      create(:type_scheme, types: [epic, story]).tap do |s|
        s.items.each { |i| i.update_columns(is_default: i.type_id == story.id) }
      end
    end

    before { ProjectTypeScheme.create!(project:, scheme:) }

    it "keeps pure position order when default_first is false" do
      expect(described_class.allowed_types(project, default_first: false).to_a).to eq([epic, story])
    end
  end

  describe "request cache" do
    let(:scheme) { create(:type_scheme, types: [story]) }

    it "reuses the lookup and resets after assignment changes" do
      expect(described_class.for_project(project)).to be_nil

      TypeSchemes::SchemeService.assign(project, scheme)
      expect(described_class.for_project(project)).to eq scheme

      TypeSchemes::SchemeService.unassign(project)
      expect(described_class.for_project(project)).to be_nil
    end
  end
end
