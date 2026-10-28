# frozen_string_literal: true

require "spec_helper"
require "features/work_packages/details/inplace_editor/shared_examples"
require "features/work_packages/shared_contexts"
require "support/edit_fields/edit_field"
require "features/work_packages/work_packages_page"
require "features/page_objects/notification"

RSpec.describe "labels inplace editor", :js, with_flag: { work_package_labels: true } do
  let(:project) { create(:project) }
  let!(:label) { create(:label, name: "Bug") }
  let!(:other_label) { create(:label, name: "Feature") }
  let(:work_package) { create(:work_package, project:) }
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages edit_work_packages] })
  end
  let(:too_long_name) { "x" * 256 }

  before do
    login_as(user)
  end

  def create_option_text(name)
    prefix = I18n.t("js.autocompleter.create_label")

    /#{Regexp.escape(prefix)}\s*"#{Regexp.escape(name)}"/
  end

  def pick_new_label(name)
    field.autocomplete(name, select: false)
    field.autocomplete_selector.send_keys(:return)
  end

  def expect_too_long_label_rejected
    PageObjects::Notifications.new(page)
      .expect_error("Labels #{I18n.t('activerecord.errors.messages.too_long', count: 255)}")
    field.expect_error
    expect(Label.named(too_long_name)).to be_empty
  end

  context "in the full view" do
    let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }
    let(:field) { work_package_page.edit_field(:labels) }

    before do
      create(:labeling, label:, labelable: work_package)
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

      field.activate!

      dropdown = field.autocomplete(new_label_name, select: false)
      expect(dropdown).to have_selector(:list_box_option, text: create_option_text(new_label_name))

      field.autocomplete_selector.send_keys(:return)

      field.expect_selected_values(label.name, new_label_name)
      expect(Label.named(new_label_name)).to be_empty

      field.submit_by_dashboard

      field.expect_state_text(new_label_name)
      expect(Label.named(new_label_name).count).to eq(1)
      expect(work_package.reload.labels.map(&:name)).to contain_exactly(label.name, new_label_name)
    end

    it "does not create a label when the edit with a new label is cancelled" do
      new_label_name = "Urgent"

      field.activate!
      field.autocomplete(new_label_name, select: false)
      field.autocomplete_selector.send_keys(:return)
      field.expect_selected_values(label.name, new_label_name)

      field.cancel_by_escape

      field.expect_inactive!
      field.expect_state_text(label.name)
      expect(Label.named(new_label_name)).to be_empty
      expect(work_package.reload.labels).to contain_exactly(label)
    end

    it "offers no create option for an existing name in a different case" do
      field.activate!

      dropdown = field.autocomplete(other_label.name.upcase, select: false)
      expect(dropdown).to have_selector(:list_box_option, text: other_label.name)
      expect(dropdown).to have_no_selector(:list_box_option, text: create_option_text(other_label.name.upcase))
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
      create(:labeling, label:, labelable: work_package)
      work_package_page.visit!
      work_package_page.ensure_page_loaded
    end

    it "renders and shows the current labels when activated" do
      field.expect_state_text(label.name)

      field.activate!
      field.expect_selected_values(label.name)
    end

    it "shows the validation error when a new label name is too long" do
      field.activate!
      pick_new_label(too_long_name)
      field.expect_selected_values(label.name, too_long_name)

      field.submit_by_dashboard

      expect_too_long_label_rejected
    end
  end

  context "in the create form" do
    let!(:status) { create(:default_status) }
    let!(:priority) { create(:default_priority) }
    let(:work_package_page) { Pages::FullWorkPackageCreate.new(project:) }
    let(:field) { work_package_page.edit_field(:labels) }

    before { work_package_page.visit! }

    context "without edit_work_packages" do
      let(:user) do
        create(:user, member_with_permissions: { project => %i[view_work_packages add_work_packages] })
      end

      it "allows picking existing labels but offers no option to create one" do
        field.set_value(label.name)
        field.expect_selected_values(label.name)

        dropdown = field.autocomplete(other_label.name.upcase, select: false)
        expect(dropdown).to have_selector(:list_box_option, text: other_label.name)

        dropdown = field.autocomplete("Unknown", select: false)
        expect(dropdown).to have_no_selector(:list_box_option, text: create_option_text("Unknown"))
      end
    end

    context "with edit_work_packages" do
      let(:user) do
        create(:user,
               member_with_permissions: { project => %i[view_work_packages add_work_packages edit_work_packages] })
      end

      it "creates a new label from the search term and assigns it" do
        new_label_name = "Urgent"

        dropdown = field.autocomplete(new_label_name, select: false)
        expect(dropdown).to have_selector(:list_box_option, text: create_option_text(new_label_name))

        field.autocomplete_selector.send_keys(:return)

        field.expect_selected_values(new_label_name)
        expect(Label.named(new_label_name)).to be_empty

        work_package_page.set_attributes({ subject: "Work package with a new label" })
        work_package_page.save!
        work_package_page.expect_and_dismiss_toaster(message: "Successful creation.")

        expect(Label.named(new_label_name).count).to eq(1)
        expect(WorkPackage.last.labels.map(&:name)).to contain_exactly(new_label_name)
      end

      it "shows the validation error when a new label name is too long" do
        pick_new_label(too_long_name)
        field.expect_selected_values(too_long_name)

        work_package_page.set_attributes({ subject: "Work package with a too long label" })
        work_package_page.save!

        expect_too_long_label_rejected
        expect(WorkPackage.where(subject: "Work package with a too long label")).to be_empty
      end
    end
  end

  context "in the work package table" do
    let(:wp_table) { Pages::WorkPackagesTable.new(project) }
    let(:field) { wp_table.edit_field(work_package, :labels) }
    let!(:query) do
      create(:query, user:, project:, column_names: %w[id subject labels])
    end

    before do
      create(:labeling, label:, labelable: work_package)
      wp_table.visit_query query
      wp_table.expect_work_package_listed work_package
    end

    it "shows the validation error when a new label name is too long" do
      field.activate!
      pick_new_label(too_long_name)
      field.expect_selected_values(label.name, too_long_name)

      field.submit_by_dashboard

      expect_too_long_label_rejected
    end
  end
end
