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

RSpec.describe WorkPackageTypes::DuplicateService, with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:color) { create(:color) }

  let(:source) do
    create(:type_with_workflow,
           name: "Bug",
           color:,
           is_milestone: true,
           is_in_roadmap: false,
           description: "The source description")
  end

  subject(:service_call) { described_class.new(type: source, user: admin).call }

  before do
    login_as(admin)
    RequestStore.clear!

    source.attribute_groups = [["custom group", %w[assignee responsible]]]
    source.save!
    source.reload
  end

  it "is successful and creates a new type" do
    expect { service_call }.to change(Type, :count).by(1)
    expect(service_call).to be_success
  end

  it "names the copy after the source" do
    copy = service_call.result

    expect(copy.own_name).to eq("Copy of Bug")
    expect(source.reload.own_name).to eq("Bug")
  end

  it "copies the source's core settings" do
    copy = service_call.result

    expect(copy.color_id).to eq(color.id)
    expect(copy).to be_is_milestone
    expect(copy).not_to be_is_in_roadmap
  end

  it "creates the copy as a root type" do
    copy = service_call.result

    expect(copy).not_to be_variant
  end

  it "copies the configuration aspects" do
    copy = service_call.result.reload

    expect(copy.attribute_groups.map(&:key)).to include("custom group")
    expect(copy.description).to eq("The source description")
    expect(copy.own_workflows).to be_present
  end

  context "when a copy with the default name already exists" do
    before { create(:type, name: "Copy of Bug") }

    it "appends a counter to keep the name unique" do
      expect(service_call.result.own_name).to eq("Copy of Bug (2)")
    end
  end

  it "positions the copy directly below the source" do
    source
    later_sibling = create(:type, name: "Later")

    expect(source.position).to be < later_sibling.position

    copy = service_call.result

    expect(copy.position).to eq(source.reload.position + 1)
    expect(later_sibling.reload.position).to be > copy.position
  end

  context "when the source has a linked aspect" do
    shared_let(:link_target) { create(:type, name: "Shared config") }

    before { source.link!(Type::ConfigurationLink::WORKFLOWS, source: link_target) }

    it "replicates the link on the copy" do
      copy = service_call.result

      expect(copy.source_for(Type::ConfigurationLink::WORKFLOWS)).to eq(link_target)
    end
  end

  context "when duplicating a variant" do
    let(:root) { create(:type, name: "Task", color:, is_milestone: true) }
    let(:variant) { create(:type, name: "Urgent", parent: root) }

    subject(:service_call) { described_class.new(type: variant, user: admin).call }

    it "creates a new variant under the same parent" do
      copy = service_call.result

      expect(service_call).to be_success
      expect(copy.own_name).to eq("Copy of Urgent")
      expect(copy.parent_id).to eq(root.id)
    end

    it "inherits the parent's core settings rather than writing its own" do
      copy = service_call.result

      expect(copy.color_id).to eq(color.id)
      expect(copy).to be_is_milestone
    end
  end
end
