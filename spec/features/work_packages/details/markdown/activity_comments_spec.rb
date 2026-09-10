# frozen_string_literal: true

require "spec_helper"

require "features/work_packages/shared_contexts"
require "features/work_packages/details/inplace_editor/shared_examples"

RSpec.describe "activity comments", :js, :selenium do
  let(:project) { create(:project, public: true) }
  let!(:work_package) do
    create(:work_package,
           project:,
           journal_notes: initial_comment)
  end
  let(:wp_page) { Pages::PrimerizedSplitWorkPackage.new(work_package, project) }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }
  let(:initial_comment) { "the first comment in this WP" }

  RSpec.shared_examples "a field which supports principal autocomplete" do
    let(:role) { create(:project_role, permissions: %i[view_work_packages edit_work_packages]) }
    let!(:user) do
      create(:user,
             member_with_roles: { project => role },
             firstname: "John")
    end
    let!(:mentioned_user) do
      create(:user,
             member_with_roles: { project => role },
             firstname: "Laura",
             lastname: "Foobar")
    end
    let!(:mentioned_group) do
      create(:group, lastname: "Laudators", member_with_roles: { project => role })
    end
    let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }

    shared_examples "principal autocomplete on field" do
      before do
        wp_page.visit!
        wp_page.ensure_page_loaded
        wp_page.switch_to_tab tab: :activity
        wp_page.wait_for_activity_tab
      end

      it "autocompletes links to user profiles" do
        activity_tab.open_new_comment_editor
        activity_tab.get_editor_form_field_element.input_element.send_keys(" @lau")
        expect(page).to have_css(".mention-list-item", text: mentioned_user.name)
        expect(page).to have_css(".mention-list-item", text: mentioned_group.name)
        expect(page).to have_no_css(".mention-list-item", text: user.name)

        # Close the autocompleter
        activity_tab.get_editor_form_field_element.input_element.send_keys :escape
        activity_tab.ckeditor.clear

        sleep 1

        activity_tab.ckeditor.type_slowly "@Laura"
        expect(page).to have_css(".mention-list-item", text: mentioned_user.name)
        expect(page).to have_no_css(".mention-list-item", text: mentioned_group.name)
        expect(page).to have_no_css(".mention-list-item", text: user.name)
      end
    end

    context "with the project page" do
      let(:wp_page) { Pages::PrimerizedSplitWorkPackage.new(work_package, project) }

      it_behaves_like "principal autocomplete on field"
    end

    context "without the project page" do
      let(:wp_page) { Pages::PrimerizedSplitWorkPackage.new(work_package) }

      it_behaves_like "principal autocomplete on field"
    end
  end

  before do
    login_as(current_user)
    allow(current_user.pref).to receive(:warn_on_leaving_unsaved?).and_return(false)
  end

  context "with permission" do
    let(:current_user) { create(:admin) }

    before do
      wp_page.visit!
      wp_page.ensure_page_loaded
      wp_page.switch_to_tab tab: :activity
      wp_page.wait_for_activity_tab
    end

    context "in edit state" do
      describe "submitting comment" do
        it "does not submit with enter" do
          activity_tab.type_comment("this is a comment")
          activity_tab.get_editor_form_field_element.input_element.send_keys :enter
          # Enter key is ignored, so comment should not be submitted
          activity_tab.expect_no_journal_notes(text: "this is a comment")
        end

        it "submits with click" do
          activity_tab.type_comment("this is a comment!1")
          page.find_test_selector("op-submit-work-package-journal-form").click
          activity_tab.expect_journal_notes(text: "this is a comment!1")
        end

        it "submits with ctrl/cmd+enter" do
          activity_tab.type_comment("this is a comment!2")
          activity_tab.get_editor_form_field_element.input_element.send_keys :control, :enter
          activity_tab.expect_journal_notes(text: "this is a comment!2")
        end
      end

      describe "autocomplete" do
        describe "work packages" do
          let!(:wp2) { create(:work_package, project:, subject: "AutoFoo") }

          it "can move to the work package by click (Regression #30928)" do
            activity_tab.type_comment("foo ##{wp2.id}")
            expect(page).to have_css(".mention-list-item", text: wp2.to_s.strip)

            activity_tab.submit_comment
            activity_tab.expect_journal_notes(text: "foo") # check if the comment is saved

            page.find("a.issue", text: wp2.id).click

            other_wp_page = Pages::FullWorkPackage.new wp2
            other_wp_page.ensure_page_loaded
            other_wp_page.edit_field(:subject).expect_text "AutoFoo"
          end
        end

        describe "users" do
          it_behaves_like "a field which supports principal autocomplete"
        end
      end

      describe "with markdown" do
        it "allows to add e.g. bold text" do
          activity_tab.open_new_comment_editor
          # Insert new text, need to do this separately.''
          ["Comment with", " ", "*", "*", "bold text", "*", "*", " ", "in it"].each do |key|
            activity_tab.get_editor_form_field_element.input_element.send_keys key
          end
          activity_tab.submit_comment

          activity_tab.expect_journal_notes(text: "Comment with bold text in it")
          activity_tab.expect_journal_notes(text: "bold text", subselector: "strong")
        end
      end
    end

    describe "referencing another work package" do
      let!(:work_package2) { create(:work_package, project:, type: create(:type)) }

      it "can reference another work package with all methods" do
        activity_tab.open_new_comment_editor

        # Insert a new reference using the autocompleter
        activity_tab.get_editor_form_field_element.input_element.send_keys "Single ##{work_package2.id}"
        expect(page)
          .to have_css(".mention-list-item", text: "#{work_package2.type.name} ##{work_package2.id}:")

        find(".mention-list-item", text: "#{work_package2.type.name} ##{work_package2.id}:").click

        # Insert new text, need to do this separately.
        # No autocompleter used this time.
        [
          :return,
          "Double ###{work_package2.id}",
          :return,
          "Triple ####{work_package2.id}",
          :return
        ].each do |key|
          activity_tab.get_editor_form_field_element.input_element.send_keys key
        end

        activity_tab.submit_comment

        activity_tab.expect_journal_notes(text: "Single ##{work_package2.id}")
        expect(page).to have_css(".work-packages-activities-tab-journals-item-component opce-macro-wp-quickinfo", count: 2)
        expect(page).to have_css(
          ".work-packages-activities-tab-journals-item-component opce-macro-wp-quickinfo",
          count: 2
        )
      end
    end

    it "can move away to another tab, keeping the draft comment" do
      activity_tab.open_new_comment_editor
      activity_tab.get_editor_form_field_element.input_element.send_keys "I'm typing an important message here ..."

      wp_page.switch_to_tab tab: :files
      expect(page).to have_test_selector("op-tab-content--tab-section")

      wp_page.switch_to_tab tab: :activity

      activity_tab.expect_input_field
      activity_tab.ckeditor.expect_value "I'm typing an important message here ..."

      activity_tab.clear_comment
      # Has removed the draft now

      wp_page.switch_to_tab tab: :files
      expect(page).to have_test_selector("op-tab-content--tab-section")

      wp_page.switch_to_tab tab: :activity
      activity_tab.expect_no_input_field
    end
  end
end
