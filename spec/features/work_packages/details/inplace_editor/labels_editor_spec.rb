# frozen_string_literal: true

require "spec_helper"
require "features/work_packages/details/inplace_editor/shared_examples"
require "features/work_packages/shared_contexts"
require "support/edit_fields/edit_field"
require "features/work_packages/work_packages_page"

RSpec.describe "labels inplace editor", :js, with_flag: { work_package_labels: true } do
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

    it "allows picking a label and removing another in the same edit" do
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

    it "creates a new label from the search term via the keyboard and adds it to the selection" do
      new_label_name = "Urgent"
      new_label_suffix = I18n.t("js.autocompleter.new_label")
      create_option_text = "#{new_label_name} #{new_label_suffix}"
      duplicate_option_text = "#{other_label.name.upcase} #{new_label_suffix}"

      field.activate!

      dropdown = field.autocomplete(other_label.name.upcase, select: false)
      expect(dropdown).to have_selector(:list_box_option, text: other_label.name)
      expect(dropdown).to have_no_selector(:list_box_option, text: duplicate_option_text)

      dropdown = field.autocomplete(new_label_name, select: false)
      expect(dropdown).to have_selector(:list_box_option, text: create_option_text)

      field.autocomplete_selector.send_keys(:return)

      field.expect_selected_values(label.name, new_label_name)
      field.submit_by_dashboard

      field.expect_state_text(new_label_name)
      expect(Label.named(new_label_name)).to be_present
      expect(work_package.reload.labels.map(&:name)).to contain_exactly(label.name, new_label_name)
    end

    it "discards the selection when the edit is cancelled" do
      field.activate!
      field.set_value(other_label.name)
      field.expect_selected_values(label.name, other_label.name)

      field.cancel_by_escape

      field.expect_inactive!
      field.expect_state_text(label.name)
      expect(field.field_container).to have_no_text(other_label.name)
      expect(work_package.reload.labels).to contain_exactly(label)
    end

    context "when the user can only view work packages" do
      let(:user) do
        create(:user, member_with_permissions: { project => %i[view_work_packages] })
      end

      it "shows the label names as read only" do
        field.expect_state_text(label.name)
        field.expect_read_only
      end
    end
  end

  context "in the split view" do
    let(:work_package_page) { Pages::PrimerizedSplitWorkPackage.new(work_package, project) }
    let(:field) { work_package_page.edit_field(:labels) }

    before do
      work_package_page.visit!
      work_package_page.ensure_page_loaded
    end

    it "renders and shows the current labels when activated" do
      field.expect_state_text(label.name)

      field.activate!
      field.expect_selected_values(label.name)
    end
  end
end
