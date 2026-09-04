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
           default_work_package_description: "The source description")
  end

  subject(:service_call) { described_class.new(type: source, user: admin).call }

  before do
    login_as(admin)
    RequestStore.clear!

    source.default_variant.attribute_groups = [["custom group", %w[assignee responsible]]]
    source.default_variant.save!
  end

  it "is successful and creates a new type" do
    expect { service_call }.to change(Type, :count).by(1)
    expect(service_call).to be_success
  end

  it "names the copy after the source" do
    copy = service_call.result

    expect(copy.name).to eq("Copy of Bug")
    expect(source.reload.name).to eq("Bug")
  end

  it "copies the source's core settings" do
    copy = service_call.result

    expect(copy.color_id).to eq(color.id)
    expect(copy).to be_is_milestone
    expect(copy).not_to be_is_in_roadmap
  end

  it "copies the configuration aspects onto the copy's base variant" do
    copy = service_call.result.reload
    copy_variant = copy.default_variant

    expect(copy_variant.attribute_groups.map(&:key)).to include("custom group")
    expect(copy_variant.default_work_package_description).to eq("The source description")
    expect(copy_variant.own_workflows).to be_present
  end

  context "when a copy with the default name already exists" do
    before { create(:type, name: "Copy of Bug") }

    it "appends a counter to keep the name unique" do
      expect(service_call.result.name).to eq("Copy of Bug (2)")
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

    before { link_configuration(source, source: link_target, aspect: TypeVariant::WORKFLOWS) }

    it "replicates the link on the copy's base variant" do
      copy = service_call.result

      expect(copy.default_variant.source_for(TypeVariant::WORKFLOWS)).to eq(link_target.default_variant)
    end
  end

  context "with project assignments" do
    shared_let(:project_a) { create(:project) }
    shared_let(:project_b) { create(:project) }

    before do
      source.projects = [project_a, project_b]
      source.save!
    end

    it "copies the source's enabled projects exactly" do
      copy = service_call.result.reload

      expect(copy.project_ids).to contain_exactly(project_a.id, project_b.id)
    end

    context "when the source's form configuration holds a custom field" do
      shared_let(:custom_field) { create(:wp_custom_field) }

      before do
        source.default_variant.attribute_groups = [["custom group", ["custom_field_#{custom_field.id}"]]]
        source.default_variant.custom_field_ids = [custom_field.id]
        source.default_variant.save!
      end

      it "activates that field in the projects the copy is added to" do
        service_call

        expect(project_a.reload.work_package_custom_field_ids).to include(custom_field.id)
        expect(project_b.reload.work_package_custom_field_ids).to include(custom_field.id)
      end
    end
  end
end
