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
require File.expand_path("../support/shared/become_member", __dir__)

RSpec.describe Project do
  include BecomeMember
  shared_let(:admin) { create(:admin) }

  let(:active) { true }
  let(:project) { create(:project, active:) }
  let(:build_project) { build_stubbed(:project, active:) }
  let(:user) { create(:user) }

  describe "#active?" do
    context "if active" do
      it "is true" do
        expect(project).to be_active
      end
    end

    context "if not active" do
      let(:active) { false }

      it "is false" do
        expect(project).not_to be_active
      end
    end
  end

  describe "#archived?" do
    subject { project.archived? }

    context "if active is true" do
      let(:active) { true }

      it { is_expected.to be false }
    end

    context "if active is false" do
      let(:active) { false }

      it { is_expected.to be true }
    end
  end

  describe "#being_archived?" do
    subject { project.being_archived? }

    context "if active is true" do
      let(:active) { true }

      it { is_expected.to be false }
    end

    context "if active was true and changes to false (marking as archived)" do
      let(:active) { true }

      before do
        project.active = false
      end

      it { is_expected.to be true }
    end

    context "if active is false" do
      let(:active) { false }

      it { is_expected.to be false }
    end

    context "if active was false and changes to true (marking as active)" do
      let(:active) { false }

      before do
        project.active = true
      end

      it { is_expected.to be false }
    end
  end

  context "when the wiki module is enabled" do
    let(:project) { create(:project, disable_modules: "wiki") }

    before do
      project.enabled_module_names = project.enabled_module_names | ["wiki"]
      project.save
      project.reload
    end

    it "creates a wiki" do
      expect(project.wiki).to be_present
    end

    it "creates a wiki menu item named like the default start page" do
      expect(project.wiki.wiki_menu_items).to be_one
      expect(project.wiki.wiki_menu_items.first.title).to eq(project.wiki.start_page)
    end
  end

  describe "#copy_allowed?" do
    let(:user) { build_stubbed(:user) }
    let(:project) { build_stubbed(:project) }
    let(:permission_granted) { true }

    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project :copy_projects, project:
      end

      login_as(user)
    end

    context "with copy project permission" do
      it "is true" do
        expect(project).to be_copy_allowed
      end
    end

    context "without copy project permission" do
      before { mock_permissions_for(user, &:forbid_everything) }

      it "is false" do
        expect(project).not_to be_copy_allowed
      end
    end
  end

  describe "name" do
    let(:name) { "     Hello    World   " }
    let(:project) { described_class.new attributes_for(:project, name:) }

    context "with white spaces in the name" do
      it "trims the name" do
        project.save
        expect(project.name).to eql("Hello World")
      end
    end

    context "when updating the name" do
      it "persists the update" do
        project.save
        project.name = "A new name"
        project.save
        project.reload

        expect(project.name).to eql("A new name")
      end
    end
  end

  describe "#types_used_by_work_packages" do
    let(:project) { create(:project_with_types) }
    let(:type) { project.types.first }
    let(:other_type) { create(:type) }
    let(:project_work_package) { create(:work_package, type:, project:) }
    let(:other_project) { create(:project, types: [other_type, type]) }
    let(:other_project_work_package) { create(:work_package, type: other_type, project: other_project) }

    it "returns the type used by a work package of the project" do
      project_work_package
      other_project_work_package

      expect(project.types_used_by_work_packages).to contain_exactly(project_work_package.type)
    end
  end

  describe "Views belonging to queries that belong to the project" do
    let(:query) { create(:query, project:) }
    let(:view) { create(:view, query:) }

    it "destroys the views and queries when project gets destroyed" do
      view
      project.destroy

      expect { query.reload }.to raise_error ActiveRecord::RecordNotFound
      expect { view.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  describe "#members" do
    let(:role) { create(:project_role) }
    let(:active_user) { create(:user) }
    let!(:active_member) { create(:member, project:, user: active_user, roles: [role]) }

    let(:inactive_user) { create(:user, status: Principal.statuses[:locked]) }
    let!(:inactive_member) { create(:member, project:, user: inactive_user, roles: [role]) }

    it "only includes active members" do
      expect(project.members)
        .to eq [active_member]
    end
  end

  it_behaves_like "creates an audit trail on destroy" do
    subject { create(:attachment) }
  end

  describe "#users" do
    let(:role) { create(:project_role) }
    let(:active_user) { create(:user) }
    let!(:active_member) { create(:member, project:, user: active_user, roles: [role]) }

    let(:inactive_user) { create(:user, status: Principal.statuses[:locked]) }
    let!(:inactive_member) { create(:member, project:, user: inactive_user, roles: [role]) }

    it "only includes active users" do
      expect(project.users)
        .to eq [active_user]
    end
  end

  describe "#close_completed_versions" do
    let!(:completed_version) do
      create(:version, project:, effective_date: Date.parse("2000-01-01")).tap do |v|
        create(:work_package, version: v, status: create(:closed_status))
      end
    end
    let!(:ineffective_version) do
      create(:version, project:, effective_date: Date.current + 1.day).tap do |v|
        create(:work_package, version: v, status: create(:closed_status))
      end
    end
    let!(:version_with_open_wps) do
      create(:version, project:, effective_date: Date.parse("2000-01-01")).tap do |v|
        create(:work_package, version: v)
      end
    end

    before do
      project.close_completed_versions
    end

    it "closes the completed version" do
      expect(completed_version.reload.status)
        .to eq "closed"
    end

    it "keeps the version with the not yet reached date open" do
      expect(ineffective_version.reload.status)
        .to eq "open"
    end

    it "keeps the version with open work packages open" do
      expect(version_with_open_wps.reload.status)
        .to eq "open"
    end
  end

  describe "hierarchy methods" do
    shared_let(:root_project) { create(:project) }
    shared_let(:parent_project) { create(:project, parent: root_project) }
    shared_let(:child_project1) { create(:project, parent: parent_project) }
    shared_let(:child_project2) { create(:project, parent: parent_project) }

    describe "#parent" do
      it "returns the parent" do
        expect(parent_project.parent)
          .to eq root_project
      end
    end

    describe "#root" do
      it "returns the root of the hierarchy" do
        expect(child_project1.root)
          .to eq root_project
      end
    end

    describe "#ancestors" do
      it "returns the ancestors of the work package" do
        expect(child_project1.ancestors)
          .to eq [root_project, parent_project]
      end

      it "returns empty array if there are no ancestors" do
        expect(root_project.ancestors)
          .to be_empty
      end
    end

    describe "#descendants" do
      it "returns the descendants of the work package" do
        expect(root_project.descendants)
          .to contain_exactly(parent_project, child_project1, child_project2)
      end

      it "returns empty array if there are no descendants" do
        expect(child_project2.descendants)
          .to be_empty
      end
    end

    describe "#children" do
      it "returns the children of the work package" do
        expect(parent_project.children)
          .to contain_exactly(child_project1, child_project2)
      end

      it "returns empty array if there are no descendants" do
        expect(child_project2.children)
          .to be_empty
      end
    end
  end

  describe "#active_subprojects" do
    subject { root_project.active_subprojects }

    shared_let(:root_project) { create(:project) }
    shared_let(:parent_project) { create(:project, parent: root_project) }
    shared_let(:child_project1) { create(:project, parent: parent_project) }

    context "with an archived subproject" do
      before do
        child_project1.active = false
        child_project1.save
      end

      it { is_expected.to eq [parent_project] }
    end

    context "with all active subprojects" do
      it { is_expected.to eq [parent_project, child_project1] }
    end
  end

  describe "#rolled_up_types" do
    let!(:parent) do
      create(:project, types: [parent_type]).tap do |p|
        project.update_attribute(:parent, p)
      end
    end
    let!(:child1) { create(:project, parent: project, types: [child1_type, shared_type]) }
    let!(:child2) { create(:project, parent: project, types: [child2_type], active: false) }

    let!(:unused_type) { create(:type) }
    let!(:parent_type) { create(:type) }
    let!(:child1_type) { create(:type) }
    let!(:child2_type) { create(:type) }
    let!(:shared_type) { create(:type) }

    let!(:project_type) do
      create(:type).tap do |t|
        project.types = [t, shared_type]
      end
    end

    it "includes all types of active projects starting from receiver down to the leaves" do
      project.reload

      expect(project.rolled_up_types)
        .to eq [child1_type, project_type, shared_type].sort_by(&:position)
    end
  end

  describe "#enabled_module_names=", with_settings: { default_projects_modules: %w(work_package_tracking repository) } do
    context "when assigning a new value" do
      let(:new_value) { %w(work_package_tracking news) }

      subject do
        project.enabled_module_names = new_value
      end

      it "sets the value" do
        subject

        expect(project.reload.enabled_module_names.sort)
          .to eql new_value.sort
      end

      it "keeps already assigned modules intact (same id)" do
        expect { subject }
          .not_to change { project.reload.enabled_modules.find { |em| em.name == "work_package_tracking" }.id }
      end
    end
  end

  it_behaves_like "acts_as_favorable included" do
    let(:instance) { project }
  end

  it_behaves_like "acts_as_customizable included" do
    let(:model_instance) { project }
    let(:custom_field) { create(:string_project_custom_field) }
  end

  describe "url identifier" do
    let(:reserved) do
      Rails.application.routes.routes
        .map { |route| route.path.spec.to_s }
        .filter_map { |path| path[%r{^/projects/(\w+)\(\.:format\)$}, 1] }
        .uniq
    end

    it "is set from name" do
      project = described_class.new(name: "foo")

      project.validate

      expect(project.identifier).to eq("foo")
    end

    it "is not allowed to clash with projects routing" do
      expect(reserved).not_to be_empty

      reserved.each do |word|
        project = described_class.new(name: word)

        project.validate

        expect(project.identifier).not_to eq(word)
      end
    end
  end
end
