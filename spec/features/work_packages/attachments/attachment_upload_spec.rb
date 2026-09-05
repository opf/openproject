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
require "features/page_objects/notification"

RSpec.describe "Upload attachment to work package", :js, :selenium do
  let(:role) do
    create(:project_role,
           permissions: %i[view_work_packages add_work_packages edit_work_packages add_work_package_comments])
  end
  let(:dev) do
    create(:user,
           firstname: "Dev",
           lastname: "Guy",
           member_with_roles: { project => role })
  end
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:, description: "Initial description") }
  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }
  let(:attachments) { Components::Attachments.new }
  let(:field) { TextEditorField.new wp_page, "description" }
  let(:image_fixture) { UploadedFile.load_from("spec/fixtures/files/image.png") }
  let(:editor) { Components::WysiwygEditor.new }

  before do
    login_as(dev)
    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  describe "wysiwyg editor" do
    context "when on an existing page" do
      before do
        wp_page.visit!
        wp_page.ensure_page_loaded
        wp_page.wait_for_activity_tab
      end

      it "can upload an image via drag & drop" do
        # Activate the edit field
        field.activate!

        editor.expect_button "Upload image from computer"

        editor.drag_attachment image_fixture.path, "Some image caption"

        field.submit_by_click

        expect(field.display_element).to have_css("img")
        expect(field.display_element).to have_content("Some image caption")
      end
    end

    context "when on a split page" do
      let!(:type) { create(:type_task) }
      let!(:status) { create(:status, is_default: true) }
      let!(:priority) { create(:priority, is_default: true) }
      let!(:project) do
        create(:project, types: [type])
      end
      let!(:table) { Pages::WorkPackagesTable.new project }

      it "can add two work packages in a row when uploading (Regression #42933)" do |_example|
        table.visit!
        new_page = table.create_wp_by_button type
        subject = new_page.edit_field :subject
        subject.set_value "My subject"

        target = find(".ck-content")
        attachments.drag_and_drop_file(target, image_fixture.path)

        sleep 2 unless using_cuprite? # rubocop:disable OpenProject/NoSleepInFeatureSpecs
        editor.wait_until_upload_progress_toaster_cleared

        editor.in_editor do |_container, editable|
          expect(editable).to have_css('img[src*="/api/v3/attachments/"]', wait: 20)
          expect(editable).to have_no_css(".ck-upload-placeholder-loader")
        end

        sleep 2 unless using_cuprite? # rubocop:disable OpenProject/NoSleepInFeatureSpecs

        scroll_to_and_click find_by_id("work-packages--edit-actions-save")

        new_page.expect_and_dismiss_toaster(
          message: "Successful creation."
        )

        split_view = Pages::PrimerizedSplitWorkPackage.new(WorkPackage.last)

        field = split_view.edit_field :description
        expect(field.display_element).to have_css("img")

        wp = WorkPackage.last
        expect(wp.subject).to eq("My subject")
        expect(wp.attachments.count).to eq(1)

        # create another one
        new_page = table.create_wp_by_button type
        subject = new_page.edit_field :subject
        subject.set_value "A second task"

        scroll_to_and_click find_by_id("work-packages--edit-actions-save")

        new_page.expect_toast(
          message: "Successful creation."
        )

        last = WorkPackage.last
        expect(last.subject).to eq("A second task")
        expect(last.attachments.count).to eq(0)

        wp.reload
        expect(wp.attachments.count).to eq(1)
      end
    end

    context "when on a new page" do
      shared_examples "it supports image uploads via drag & drop" do
        let!(:new_page) { Pages::FullWorkPackageCreate.new }
        let!(:type) { create(:type_task) }
        let!(:status) { create(:status, is_default: true) }
        let!(:priority) { create(:priority, is_default: true) }
        let!(:project) do
          create(:project, types: [type])
        end

        let(:post_conditions) { nil }

        before do
          visit new_project_work_packages_path(project.identifier, type: type.id)
        end

        it "can upload an image via drag & drop (Regression #28189)" do |_example|
          subject = new_page.edit_field :subject
          subject.set_value "My subject"

          target = find(".ck-content")
          attachments.drag_and_drop_file(target, image_fixture.path)

          sleep 2 unless using_cuprite? # rubocop:disable OpenProject/NoSleepInFeatureSpecs
          editor.wait_until_upload_progress_toaster_cleared

          editor.in_editor do |_container, editable|
            expect(editable).to have_css('img[src*="/api/v3/attachments/"]', wait: 20)
            expect(editable).to have_no_css(".ck-upload-placeholder-loader")
          end

          sleep 2 unless using_cuprite? # rubocop:disable OpenProject/NoSleepInFeatureSpecs

          scroll_to_and_click find_by_id("work-packages--edit-actions-save")

          wp_page.expect_toast(
            message: "Successful creation."
          )

          field = wp_page.edit_field :description
          expect(field.display_element).to have_css("img")

          wp = WorkPackage.last
          expect(wp.subject).to eq("My subject")
          expect(wp.attachments.count).to eq(1)

          post_conditions
        end
      end

      it_behaves_like "it supports image uploads via drag & drop"

      # We do a complete integration test for direct uploads on this example.
      # If this works all parts in the backend and frontend work properly together.
      # Technically one could test this not only for new work packages, but also for existing
      # ones, and for new and existing other attachable resources. But the code is the same
      # everywhere so if this works it should work everywhere else too.
      # TODO: Add better_cuprite_billy. I'm not sure what needs to be set up so the request to AWS passes.
      # Need help
      context "with direct uploads", :js, :with_direct_uploads do
        before do
          allow_any_instance_of(Attachment).to receive(:diskfile).and_return Struct.new(:path).new(image_fixture.path.to_s)
        end

        it_behaves_like "it supports image uploads via drag & drop" do
          let(:post_conditions) do
            # check the attachment was created successfully
            expect(Attachment.count).to eq 1
            a = Attachment.first
            expect(a[:file]).to eq image_fixture.basename.to_s

            # check /api/v3/attachments/:id/uploaded was called
            expect(Attachments::FinishDirectUploadJob).to have_been_enqueued
          end
        end
      end
    end
  end

  describe "attachment dropzone" do
    shared_examples "attachment dropzone common" do
      it "can drag something to the files tab and have it open" do
        wp_page.switch_to_tab(tab: "Files")
        wait_for_network_idle

        wp_page = Pages::FullWorkPackage.new(work_package, project)
        wp_page.ensure_page_loaded
        wp_page.expect_tab "Files"

        attachments = Components::Attachments.new
        attachments.drag_and_drop_file test_selector("op-attachments--drop-box"),
                                       image_fixture.path,
                                       :center,
                                       page.find('[data-qa-tab-id="files"]'),
                                       delay_dragleave: true

        editor.wait_until_upload_progress_toaster_cleared
        expect(page).to have_test_selector("op-files-tab--file-list-item-title", text: "image.png", wait: 10)
        wp_page.expect_tab "Files"
      end

      it "can drag something from the files tab and create a comment with it" do
        wp_page.switch_to_tab(tab: "Activity")
        wait_for_network_idle
        wp_page = Pages::FullWorkPackage.new(work_package, project)
        wp_page.ensure_page_loaded
        wp_page.wait_for_activity_tab

        attachments.drag_and_drop_file ".work-package-comment",
                                       image_fixture.path,
                                       :center,
                                       page.find('[data-qa-tab-id="activity"]'),
                                       delay_dragleave: true

        wp_page.expect_tab "Activity"
      end
    end

    include_examples "attachment dropzone common"

    context "with a user that is allowed to add attachments but not edit WP (#29203)" do
      let(:role) do
        create(:project_role,
               permissions: %i[view_work_packages add_work_package_attachments add_work_package_comments])
      end

      include_examples "attachment dropzone common"
    end

    # This one is not shared, because it requires edit WP
    it "can upload an image via attaching and drag & drop" do
      wp_page.switch_to_tab(tab: "files")
      container = page.find_test_selector("op-attachments--drop-box")

      ##
      # Attach file manually
      expect(page).not_to have_test_selector("op-files-tab--file-list-item-title")
      attachments.attach_file_on_input(image_fixture.path)
      editor.wait_until_upload_progress_toaster_cleared
      expect(page)
        .to have_test_selector("op-files-tab--file-list-item-title",
                               text: "image.png",
                               wait: 5)

      # Drop zone should become hidden again
      expect(container).not_to be_visible

      # Drop zone should become hidden again
      expect(container).not_to be_visible

      ##
      # and via drag & drop
      attachments.drag_and_drop_file(container, image_fixture.path)
      editor.wait_until_upload_progress_toaster_cleared
      expect(page)
        .to have_test_selector("op-files-tab--file-list-item-title",
                               text: "image.png",
                               count: 2,
                               wait: 5)

      # Drop zone should become hidden again
      expect(container).not_to be_visible

      ##
      # and via drag & drop having a stopover over a ckEditor input field (Regression#49507)
      attachments.drag_and_drop_file container,
                                     image_fixture.path,
                                     :center,
                                     ["#{field.selector} #{field.display_selector}", ".work-package--single-view"]

      editor.wait_until_upload_progress_toaster_cleared
      expect(page)
        .to have_test_selector("op-files-tab--file-list-item-title",
                               text: "image.png",
                               count: 3,
                               wait: 5)

      # Drop zone should become hidden again
      expect(container).not_to be_visible

      ##
      # and via drag & drop having a stopover and canceling the action, should restore the drop zones
      # (Regression#45782)
      attachments.drag_and_drop_file container,
                                     image_fixture.path,
                                     :center,
                                     field.input_element,
                                     cancel_drop: true

      editor.wait_until_upload_progress_toaster_cleared
      expect(page)
        .to have_test_selector("op-files-tab--file-list-item-title",
                               text: "image.png",
                               count: 3,
                               wait: 5)

      # Drop zone should become hidden again
      expect(container).not_to be_visible
    end
  end
end
