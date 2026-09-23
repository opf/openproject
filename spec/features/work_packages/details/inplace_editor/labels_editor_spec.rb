# frozen_string_literal: true

require "spec_helper"
require "features/work_packages/details/inplace_editor/shared_examples"
require "features/work_packages/shared_contexts"
require "support/edit_fields/edit_field"
require "features/work_packages/work_packages_page"

RSpec.describe "labels inplace editor", :js, with_flag: :work_package_labels do
  let(:project) { create(:project) }
  let!(:label) { create(:label, name: "Bug") }
  let!(:other_label) { create(:label, name: "Feature") }
  let(:work_package) { create(:work_package, project:) }
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages edit_work_packages] })
  end

  before do
    create(:labeling, label:, labelable: work_package)
    login_as(user)
  end

  context "in the full view" do
    let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }
    let(:field) { work_package_page.edit_field(:labels) }

    before do
      work_package_page.visit!
      work_package_page.ensure_page_loaded
    end

    it "allows picking a label and removing another in the same edit, saving in one request" do
      field.expect_state_text(label.name)

      field.activate!
      field.set_value(other_label.name)
      field.expect_selected_values(label.name, other_label.name)
      field.unset_value(label.name, multi: true)
      field.submit_by_dashboard

      field.expect_state_text(other_label.name)
      expect(field.field_container).to have_no_text(label.name)
      expect(work_package.reload.labels).to contain_exactly(other_label)
    end
  end

  context "in the split view" do
    let(:work_package_page) { Pages::PrimerizedSplitWorkPackage.new(work_package, project) }
    let(:field) { work_package_page.edit_field(:labels) }

    before do
      work_package_page.visit!
      work_package_page.ensure_page_loaded
    end

    it "allows picking another label and saving it" do
      field.expect_state_text(label.name)

      field.activate!
      field.set_value(other_label.name)
      field.expect_selected_values(label.name, other_label.name)
      field.submit_by_dashboard

      expect(work_package.reload.labels).to contain_exactly(label, other_label)
      field.expect_state_text(other_label.name)
    end
  end
end
