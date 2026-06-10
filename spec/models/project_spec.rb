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

RSpec.describe Project do
  include BecomeMember

  shared_let(:admin) { create(:admin) }

  let(:active) { true }
  let(:project) { create(:project, active:) }
  let(:build_project) { build(:project, active:) }
  let(:user) { create(:user) }

  describe ".templated" do
    let!(:projects) { create_list(:project, 2) }
    let!(:templated_projects) { create_list(:template_project, 1) }

    it "returns templated projects only" do
      expect(described_class.templated).to match_array(templated_projects)
    end
  end

  describe "template associations" do
    let(:template) { create(:template_project) }
    let(:project_from_template) { create(:project, template:) }

    it { is_expected.to belong_to(:template).class_name("Project").optional }
    it { is_expected.to have_many(:templated_projects).class_name("Project").with_foreign_key("template_id") }

    it "allows a project to reference its template" do
      expect(project_from_template.template).to eq(template)
    end

    it "allows a template to access projects created from it" do
      expect(template.templated_projects).to include(project_from_template)
    end
  end

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

    context "with whitespace in the name" do
      it "normalizes excess whitespace" do
        expect(subject).to normalize(:name).from(name).to("Hello World")
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

  describe "workspace_type" do
    it "is set to nil by default, to force having errors when it has not been set" do
      # Would it make sense to have "project" as default value?
      project = described_class.new
      expect(project.workspace_type).to be_nil
    end

    it "must be one of the allowed values: #{described_class.workspace_types.keys}" do
      expect(project).to validate_inclusion_of(:workspace_type).in_array(%w[project program portfolio])
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

  describe "#project_phases" do
    it { is_expected.to have_many(:phases).class_name("Project::Phase").dependent(:destroy) }

    it "has many available_phases" do
      expect(subject).to have_many(:available_phases)
                    .class_name("Project::Phase")
                    .inverse_of(:project)
                    .dependent(nil)
                    .order("project_phase_definitions.position ASC")
    end

    it "checks for active flag" do
      expect(subject.available_phases.to_sql)
        .to include("\"project_phases\".\"active\" = TRUE")
    end

    it "checks for :view_project_phases permission" do
      project_condition = described_class.allowed_to(User.current, :view_project_phases).select(:id)

      expect(subject.available_phases.to_sql).to include(project_condition.to_sql)
    end

    it "eager loads :definition" do
      expect(subject.available_phases.to_sql)
        .to include("LEFT OUTER JOIN \"project_phase_definitions\" ON")
    end

    describe ".validates_associated" do
      let(:user) do
        create(:user, member_with_permissions: { project => %i(view_project view_project_phases) })
      end
      let!(:project_phase) do
        create :project_phase, :skip_validate, project:, start_date: Date.new(3000, 1, 1), finish_date: Date.new(2000, 1, 1)
      end

      current_user { user }

      it "is valid without a validation context" do
        expect(project).to be_valid
      end

      it "is invalid with the :saving_phases validation context" do
        expect(project).not_to be_valid(:saving_phases)
      end
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

  it_behaves_like "acts_as_favoritable included" do
    let(:instance) { project }
  end

  it_behaves_like "acts_as_customizable included", admin_only_allowed: true, comments: true do
    let!(:model_instance) { project }
    let!(:new_model_instance) { build_project }
    let!(:custom_field) { create(:string_project_custom_field) }

    before do
      allow(project).to receive(:available_custom_fields) { ProjectCustomField.all }
      allow(new_model_instance).to receive(:available_custom_fields) { ProjectCustomField.all }
    end

    describe "valid?" do
      let(:custom_field) { create(:string_project_custom_field, is_required: true) }

      before do
        model_instance.custom_field_values = { custom_field.id => "test" }
        model_instance.save
        model_instance.custom_field_values = { custom_field.id => nil }
        # Ensure the custom values are validated.
        # Note: Since the default behavior is to not validate custom values unless they are
        # received from the user input, the :saving_custom_fields validation context might
        # not be required anymore.
        model_instance.custom_values_to_validate = model_instance.custom_field_values
      end

      context "without a validation context" do
        it "does not validates the custom fields" do
          expect(model_instance).to be_valid
        end

        it "does not includes the default validation context in the validation_context" do
          model_instance.send(:validation_context=, :custom_context)
          expect(model_instance.validation_context).to eq(:custom_context)
        end
      end

      context "with the :saving_custom_fields validation context" do
        it "validates the custom fields" do
          expect(model_instance).not_to be_valid(:saving_custom_fields)
        end

        it "includes the default validation context too in the validation_context" do
          model_instance.send(:validation_context=, :saving_custom_fields)
          expect(model_instance.validation_context).to eq(%i(saving_custom_fields update))
        end
      end
    end
  end

  describe "#custom_values_for_custom_field" do
    let(:custom_field) { create(:list_project_custom_field, multi_value: true) }
    # intentionally out of order
    let!(:cv2) { create(:custom_value, id: 1002, customized: project, custom_field:) }
    let!(:cv1) { create(:custom_value, id: 1001, customized: project, custom_field:) }
    let!(:cv3) { create(:custom_value, id: 1003, customized: project, custom_field:) }

    before do
      allow(project).to receive(:available_custom_fields) { ProjectCustomField.all }
    end

    it "returns values ordered by id" do
      values = project.custom_values_for_custom_field(custom_field)
      expect(values).to eq([cv1, cv2, cv3])
    end
  end

  describe "#allowed_parent_workspace_types" do
    {
      project: %i[portfolio program project],
      program: %i[portfolio],
      portfolio: %i[]
    }.each do |workspace_type, allowed_parent_workspace_types|
      context "for workspace type #{workspace_type}" do
        let(:project) { described_class.new(workspace_type:) }

        subject { project.allowed_parent_workspace_types }

        it { is_expected.to match_array(allowed_parent_workspace_types) }
      end
    end

    context "for unknown workspace type" do
      let(:project) { described_class.new(workspace_type: :unknown) }

      subject { project.allowed_parent_workspace_types }

      it { is_expected.to eq [] }
    end
  end

  describe "#parent_allowed?" do
    context "for a project" do
      let(:workspace) { build_stubbed(:project) }

      it "is truthy" do
        expect(workspace).to be_parent_allowed
      end
    end

    context "for a program" do
      let(:workspace) { build_stubbed(:program) }

      it "is truthy" do
        expect(workspace).to be_parent_allowed
      end
    end

    context "for a portfolio" do
      let(:workspace) { build_stubbed(:portfolio) }

      it "is falsey" do
        expect(workspace).not_to be_parent_allowed
      end
    end
  end

  describe "projects.identifier unique database constraint" do
    let!(:other_project) { create(:project, identifier: "my-app") }
    let(:project) { build(:project, identifier: "my-app") }

    it "ensures uniqueness with disabled validation" do
      expect { project.save!(validate: false) }.to raise_error(
        ActiveRecord::RecordNotUnique,
        /PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint "index_projects_on_lower_identifier"\n/
      )
    end
  end
end
