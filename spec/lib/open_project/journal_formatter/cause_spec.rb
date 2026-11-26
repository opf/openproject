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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe OpenProject::JournalFormatter::Cause do
  include_context "with journal cause formatter"
  include WorkPackagesHelper

  shared_let(:work_package) { create(:work_package) }
  let(:work_package_html_link) do
    link_to_work_package(work_package, link_subject: true)
  end
  let(:work_package_raw_link) { work_package.formatted_id }

  shared_examples "XSS-proof rendering of status name" do
    before do
      cause["status_name"] = "<script>alert('xss')</script>"
    end

    it "escapes the status name when rendering HTML" do
      expect(cause).to render_html_variant(a_string_including("&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"))
    end

    it "does not escape the status name when rendering raw text" do
      expect(cause).to render_raw_variant(a_string_including("<script>alert('xss')</script>"))
    end
  end

  context "when the change was caused by a change to the parent" do
    subject(:cause) do
      {
        "type" => "work_package_parent_changed_times",
        "work_package_id" => work_package.id
      }
    end

    context "when the user is able to access the related work package" do
      before do
        allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.where(id: work_package.id))
      end

      it do
        link = work_package_html_link
        expect(cause).to render_html_variant(
          "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
          "#{I18n.t('journals.cause_descriptions.work_package_parent_changed_times', link:)}"
        )
      end

      it do
        link = work_package_raw_link
        expect(cause).to render_raw_variant(
          "#{I18n.t('journals.caused_changes.dates_changed')} " \
          "#{I18n.t('journals.cause_descriptions.work_package_parent_changed_times', link:)}"
        )
      end
    end

    context "when the user is not able to access the related work package" do
      before do
        allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.none)
      end

      it do
        expect(cause).to render_html_variant(
          "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
          "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        )
      end

      it do
        expect(cause).to render_raw_variant(
          "#{I18n.t('journals.caused_changes.dates_changed')} " \
          "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        )
      end
    end

    context "in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      let(:semantic_project) { create(:project, identifier: "MACROPROJ") }
      let(:work_package) { create(:work_package, project: semantic_project) }

      before do
        work_package.allocate_and_register_semantic_id
        allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.where(id: work_package.id))
      end

      it "renders the related work package's formatted_id in raw text mode" do
        wp = work_package.reload
        expect(cause).to render_raw_variant(a_string_including(wp.formatted_id))
        expect(cause).not_to render_raw_variant(a_string_including("##{wp.id}"))
      end

      it "renders the related work package's formatted_id in the link label in HTML mode" do
        wp = work_package.reload
        expect(cause).to render_html_variant(a_string_including("#{wp.formatted_id}:"))
        expect(cause).not_to render_html_variant(a_string_including(" ##{wp.id}:"))
      end
    end
  end

  context "when the change was caused by a change to a predecessor" do
    subject(:cause) do
      {
        "type" => "work_package_predecessor_changed_times",
        "work_package_id" => work_package.id
      }
    end

    context "when the user is able to access the related work package" do
      before do
        allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.where(id: work_package.id))
      end

      it do
        link = work_package_html_link
        expect(cause).to render_html_variant(
          "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
          "#{I18n.t('journals.cause_descriptions.work_package_predecessor_changed_times', link:)}"
        )
      end

      it do
        link = work_package_raw_link
        expect(cause).to render_raw_variant(
          "#{I18n.t('journals.caused_changes.dates_changed')} " \
          "#{I18n.t('journals.cause_descriptions.work_package_predecessor_changed_times', link:)}"
        )
      end
    end

    context "when the user is not able to access the related work package" do
      before do
        allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.none)
      end

      it do
        expect(cause).to render_html_variant(
          "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
          "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        )
      end

      it do
        expect(cause).to render_raw_variant(
          "#{I18n.t('journals.caused_changes.dates_changed')} " \
          "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        )
      end
    end
  end

  context "when the change was caused by a change to a child" do
    subject(:cause) do
      {
        "type" => "work_package_children_changed_times",
        "work_package_id" => work_package.id
      }
    end

    context "when the user is able to access the related work package" do
      before do
        allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.where(id: work_package.id))
      end

      it do
        link = work_package_html_link
        expect(cause).to render_html_variant(
          "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
          "#{I18n.t('journals.cause_descriptions.work_package_children_changed_times', link:)}"
        )
      end

      it do
        link = work_package_raw_link
        expect(cause).to render_raw_variant(
          "#{I18n.t('journals.caused_changes.dates_changed')} " \
          "#{I18n.t('journals.cause_descriptions.work_package_children_changed_times', link:)}"
        )
      end
    end

    context "when the user is not able to access the related work package" do
      before do
        allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.none)
      end

      it do
        expect(cause).to render_html_variant(
          "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
          "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        )
      end

      it do
        expect(cause).to render_raw_variant(
          "#{I18n.t('journals.caused_changes.dates_changed')} " \
          "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        )
      end
    end
  end

  context "when the change was caused by retracting a comment" do
    subject(:cause) do
      {
        "type" => "comment_retracted"
      }
    end

    it do
      expect(cause).to render_html_variant(
        "<strong>#{I18n.t('journals.caused_changes.comment_retracted')}</strong>"
      )
    end

    it do
      expect(cause).to render_raw_variant(I18n.t("journals.caused_changes.comment_retracted"))
    end
  end

  context "when the change was caused by changing values within a child" do
    subject(:cause) do
      {
        "type" => "work_package_children_changed_values",
        "work_package_id" => work_package.id
      }
    end

    context "when the user is able to access the related work package" do
      before do
        allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.where(id: work_package.id))
      end

      it do
        link = work_package_html_link
        expect(cause).to render_html_variant(
          "<strong>#{I18n.t('journals.caused_changes.work_package_children_changed_values')}</strong> " \
          "#{I18n.t('journals.cause_descriptions.work_package_children_changed_values', link:)}"
        )
      end

      it do
        link = work_package_raw_link
        expect(cause).to render_raw_variant(
          "#{I18n.t('journals.caused_changes.work_package_children_changed_values')} " \
          "#{I18n.t('journals.cause_descriptions.work_package_children_changed_values', link:)}"
        )
      end
    end

    context "when the user is not able to access the related work package" do
      before do
        allow(WorkPackage).to receive(:visible).with(User.current).and_return(WorkPackage.none)
      end

      it do
        expect(cause).to render_html_variant(
          "<strong>#{I18n.t('journals.caused_changes.work_package_children_changed_values')}</strong> " \
          "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        )
      end

      it do
        expect(cause).to render_raw_variant(
          "#{I18n.t('journals.caused_changes.work_package_children_changed_values')} " \
          "#{I18n.t('journals.cause_descriptions.unaccessable_work_package_changed')}"
        )
      end
    end
  end

  context "when the change was caused by the deletion of the parent" do
    subject(:cause) do
      {
        "type" => "work_package_parent_deleted"
      }
    end

    it do
      expect(cause).to render_html_variant(
        "<strong>#{I18n.t('journals.caused_changes.work_package_parent_deleted')}</strong> " \
        "#{I18n.t('journals.cause_descriptions.work_package_parent_deleted')}"
      )
    end

    it do
      expect(cause).to render_raw_variant(
        "#{I18n.t('journals.caused_changes.work_package_parent_deleted')} " \
        "#{I18n.t('journals.cause_descriptions.work_package_parent_deleted')}"
      )
    end
  end

  context "when the change was caused by working day changes" do
    subject(:cause) do
      {
        "type" => "working_days_changed",
        "changed_days" => {
          "working_days" => {
            "2" => false,
            "6" => true

          },
          "non_working_days" => {
            "2023-01-01" => true,
            "2023-12-24" => false
          }
        }
      }
    end

    it do
      changes = [
        I18n.t("journals.cause_descriptions.working_days_changed.days.non_working", day: WeekDay.find_by!(day: 2).name),
        I18n.t("journals.cause_descriptions.working_days_changed.days.working", day: WeekDay.find_by!(day: 6).name),
        I18n.t("journals.cause_descriptions.working_days_changed.dates.working", date: format_date(Date.new(2023, 1, 1))),
        I18n.t("journals.cause_descriptions.working_days_changed.dates.non_working", date: format_date(Date.new(2023, 12, 24)))
      ].join(", ")
      expect(cause).to render_html_variant(
        "<strong>#{I18n.t('journals.caused_changes.dates_changed')}</strong> " \
        "#{I18n.t('journals.cause_descriptions.working_days_changed.changed', changes:)}"
      )
    end

    it do
      changes = [
        I18n.t("journals.cause_descriptions.working_days_changed.days.non_working", day: WeekDay.find_by!(day: 2).name),
        I18n.t("journals.cause_descriptions.working_days_changed.days.working", day: WeekDay.find_by!(day: 6).name),
        I18n.t("journals.cause_descriptions.working_days_changed.dates.working", date: format_date(Date.new(2023, 1, 1))),
        I18n.t("journals.cause_descriptions.working_days_changed.dates.non_working", date: format_date(Date.new(2023, 12, 24)))
      ].join(", ")
      expect(cause).to render_raw_variant(
        "#{I18n.t('journals.caused_changes.dates_changed')} " \
        "#{I18n.t('journals.cause_descriptions.working_days_changed.changed', changes:)}"
      )
    end

    context "with a date format preference" do
      current_user { build_stubbed(:user, preferences: { date_format: "%d.%m.%Y" }) }

      it "formats the dates according to the preference" do
        expect(render(cause, html: false))
          .to include("01.01.2023", "24.12.2023")
      end
    end
  end

  context "when a change of status % complete is the cause" do
    shared_let(:status) { create(:status, name: "In progress", default_done_ratio: 40) }
    subject(:cause) do
      {
        "type" => "status_changed",
        "status_name" => status.name,
        "status_id" => status.id,
        "status_changes" => { "default_done_ratio" => [20, 40] }
      }
    end

    it do
      expect(cause).to render_html_variant("<strong>Status &#39;In progress&#39;</strong> " \
                                           "% Complete changed from 20% to 40%")
    end

    it do
      expect(cause).to render_raw_variant("Status 'In progress' % Complete changed from 20% to 40%")
    end

    it_behaves_like "XSS-proof rendering of status name"
  end

  context "when a status being excluded from totals is the cause" do
    shared_let(:status) { create(:status, name: "Rejected") }
    subject(:cause) do
      {
        "type" => "status_changed",
        "status_name" => status.name,
        "status_id" => status.id,
        "status_changes" => { "excluded_from_totals" => [false, true] }
      }
    end

    it do
      expect(cause).to render_html_variant(
        "<strong>Status &#39;Rejected&#39;</strong> now excluded from hierarchy totals"
      )
    end

    it do
      expect(cause).to render_raw_variant(
        "Status 'Rejected' now excluded from hierarchy totals"
      )
    end

    it_behaves_like "XSS-proof rendering of status name"
  end

  context "when a status being no longer excluded from totals is the cause" do
    shared_let(:status) { create(:status, name: "Rejected") }
    subject(:cause) do
      {
        "type" => "status_changed",
        "status_name" => status.name,
        "status_id" => status.id,
        "status_changes" => { "excluded_from_totals" => [true, false] }
      }
    end

    it do
      expect(cause).to render_html_variant(
        "<strong>Status &#39;Rejected&#39;</strong> now included in hierarchy totals"
      )
    end

    it do
      expect(cause).to render_raw_variant(
        "Status 'Rejected' now included in hierarchy totals"
      )
    end

    it_behaves_like "XSS-proof rendering of status name"
  end

  context "when a change of progress calculation mode to status-based is the cause" do
    subject(:cause) do
      {
        "type" => "progress_mode_changed_to_status_based"
      }
    end

    it do
      expect(cause).to render_html_variant(
        "<strong>Progress calculation updated</strong> " \
        "Progress calculation mode set to status-based"
      )
    end

    it do
      expect(cause).to render_raw_variant(
        "Progress calculation updated " \
        "Progress calculation mode set to status-based"
      )
    end
  end

  context "when a change of total percent complete mode from " \
          "simple average to work-weighted average is the cause" do
    subject(:cause) do
      {
        "type" => "total_percent_complete_mode_changed_to_work_weighted_average"
      }
    end

    it do
      expect(cause).to render_html_variant(
        "<strong>Calculation of % Complete totals now weighted by Work.</strong> " \
        "Child work packages without Work are ignored."
      )
    end
  end

  context "when both a change of status % complete and excluded from totals is the cause" do
    shared_let(:status) { create(:status, name: "In progress", default_done_ratio: 40) }
    subject(:cause) do
      {
        "type" => "status_changed",
        "status_name" => status.name,
        "status_id" => status.id,
        "status_changes" => { "default_done_ratio" => [20, 40],
                              "excluded_from_totals" => [false, true] }
      }
    end

    it do
      expect(cause).to render_html_variant("<strong>Status &#39;In progress&#39;</strong> " \
                                           "% Complete changed from 20% to 40% and now excluded from hierarchy totals")
    end

    it do
      expect(cause).to render_raw_variant("Status 'In progress' " \
                                          "% Complete changed from 20% to 40% and now excluded from hierarchy totals")
    end

    it_behaves_like "XSS-proof rendering of status name"
  end

  context "when cause is a system update: change of progress calculation mode from disabled to work-based" do
    subject(:cause) do
      {
        "type" => "system_update",
        "feature" => "progress_calculation_adjusted_from_disabled_mode"
      }
    end

    it do
      href = OpenProject::Static::Links.url_for(:blog_article_progress_changes)
      expect(cause).to render_html_variant(
        "<strong>OpenProject system update:</strong> Progress calculation automatically " \
        "<a href=\"#{href}\" target=\"_blank\">set to work-based mode and adjusted with version update</a>."
      )
    end

    it do
      expect(cause).to render_raw_variant(
        "OpenProject system update: Progress calculation automatically " \
        "set to work-based mode and adjusted with version update."
      )
    end
  end

  context "when cause is a system update: progress calculation adjusted" do
    subject(:cause) do
      {
        "type" => "system_update",
        "feature" => "progress_calculation_adjusted"
      }
    end

    it do
      href = OpenProject::Static::Links.url_for(:blog_article_progress_changes)
      expect(cause).to render_html_variant(
        "<strong>OpenProject system update:</strong> Progress calculation automatically " \
        "<a href=\"#{href}\" target=\"_blank\">adjusted with version update</a>."
      )
    end

    it do
      expect(cause).to render_raw_variant(
        "OpenProject system update: Progress calculation automatically adjusted with version update."
      )
    end

    context "with previous feature key 'progress_calculation_changed'" do
      before do
        cause["feature"] = "progress_calculation_changed"
      end

      it "is rendered like 'progress_calculation_adjusted'" do
        expect(cause).to render_raw_variant(
          "OpenProject system update: Progress calculation automatically adjusted with version update."
        )
      end
    end
  end

  context "when cause is a system update: totals removed from childless work packages" do
    subject(:cause) do
      {
        "type" => "system_update",
        "feature" => "totals_removed_from_childless_work_packages"
      }
    end

    it do
      href = OpenProject::Static::Links.url_for(:release_notes_14_0_1)
      expect(cause).to render_html_variant(
        "<strong>OpenProject system update:</strong> Work and progress totals " \
        "automatically removed for non-parent work packages with " \
        "<a href=\"#{href}\" target=\"_blank\">version update</a>. " \
        "This is a maintenance task and can be safely ignored."
      )
    end

    it do
      expect(cause).to render_raw_variant(
        "OpenProject system update: Work and progress totals " \
        "automatically removed for non-parent work packages with version update. " \
        "This is a maintenance task and can be safely ignored."
      )
    end
  end

  context "when the change was caused by a system update" do
    subject(:cause) do
      {
        "type" => "system_update",
        "feature" => "file_links_journal"
      }
    end

    it do
      expect(cause).to render_html_variant(
        "<strong>#{I18n.t('journals.caused_changes.system_update')}</strong> " \
        "#{I18n.t('journals.cause_descriptions.system_update.file_links_journal')}"
      )
    end

    it do
      expect(cause).to render_raw_variant(
        "#{I18n.t('journals.caused_changes.system_update')} " \
        "#{I18n.t('journals.cause_descriptions.system_update.file_links_journal')}"
      )
    end
  end

  context "when the change was caused by a sprint migration" do
    subject(:cause) do
      {
        "type" => "system_update",
        "feature" => "sprint_migration",
        "version_name" => "Sprint 1"
      }
    end

    it do
      expect(cause).to render_html_variant(
        "<strong>#{I18n.t('journals.caused_changes.system_update')}</strong> " \
        "#{I18n.t('journals.cause_descriptions.system_update.sprint_migration', version_name: 'Sprint 1')}"
      )
    end

    it do
      expect(cause).to render_raw_variant(
        "#{I18n.t('journals.caused_changes.system_update')} " \
        "#{I18n.t('journals.cause_descriptions.system_update.sprint_migration', version_name: 'Sprint 1')}"
      )
    end

    context "when the version name contains HTML (XSS prevention)" do
      before do
        cause["version_name"] = "<script>alert('xss')</script>"
      end

      it "escapes the version name in HTML output" do
        expect(cause).to render_html_variant(
          a_string_including("&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
        )
      end

      it "escapes the version name in raw text output" do
        expect(cause).to render_raw_variant(
          a_string_including("&lt;script&gt;alert('xss')&lt;/script&gt;")
        )
      end
    end
  end

  context "when the change was caused by the deletion of a label" do
    subject(:cause) { Journal::CausedByLabelDeletion.new(label_ids: [42], label_names: ["Foo"]).to_hash }

    it do
      expect(cause).to render_html_variant(
        "<strong>Label removed:</strong> 'Foo' was deleted"
      )
    end

    it do
      expect(cause).to render_raw_variant("Label removed: 'Foo' was deleted")
    end

    context "when several labels were deleted" do
      subject(:cause) do
        Journal::CausedByLabelDeletion.new(
          label_ids: [1, 2, 3], label_names: %w[Frontend Backend Middleware]
        ).to_hash
      end

      it "lists every label name and pluralizes the verb" do
        expect(cause).to render_html_variant(
          "<strong>Label removed:</strong> 'Frontend', 'Backend', 'Middleware' were deleted"
        )
      end
    end

    context "when the label name contains HTML (XSS prevention)" do
      subject(:cause) do
        Journal::CausedByLabelDeletion.new(label_ids: [42], label_names: ["<script>alert('x')</script>"]).to_hash
      end

      it "escapes the label name in HTML output" do
        expect(cause).to render_html_variant(
          a_string_including("&lt;script&gt;alert(&#39;x&#39;)&lt;/script&gt;")
        )
      end

      it "does not escape the label name in raw text output" do
        expect(cause).to render_raw_variant(a_string_including("<script>alert('x')</script>"))
      end
    end
  end

  context "when the change was caused by an import" do
    subject(:cause) do
      {
        "type" => "import",
        "import_history" => [
          {
            "author_name" => "Alice Doe",
            "items" => [
              { "field" => "status", "fromString" => "Open", "toString" => "In Progress" },
              { "field" => "priority", "fromString" => "Low", "toString" => "High" }
            ]
          }
        ]
      }
    end

    it "renders the header with the author name in HTML" do
      expect(cause).to render_html_variant(
        a_string_including(I18n.t("journals.cause_descriptions.import.header", author: "Alice Doe"))
      )
    end

    it "renders the header with the author name in plain text" do
      expect(cause).to render_raw_variant(
        a_string_including(I18n.t("journals.cause_descriptions.import.header", author: "Alice Doe"))
      )
    end

    it "renders the 'Imported' label in HTML" do
      expect(cause).to render_html_variant(
        a_string_including("<strong>#{I18n.t('journals.caused_changes.import')}</strong>")
      )
    end

    it "renders field changes in HTML" do
      expect(cause).to render_html_variant(
        a_string_including(
          I18n.t("journals.cause_descriptions.import.field_changed",
                 field: "<strong>status</strong>", old_value: "Open", new_value: "In Progress")
        )
      )
    end

    it "renders field changes in plain text without HTML tags" do
      expect(cause).to render_raw_variant(
        a_string_including(
          I18n.t("journals.cause_descriptions.import.field_changed",
                 field: "status", old_value: "Open", new_value: "In Progress")
        )
      )
    end

    context "when a field was set (no previous value)" do
      subject(:cause) do
        {
          "type" => "import",
          "import_history" => [
            {
              "author_name" => "Bob",
              "items" => [{ "field" => "assignee", "fromString" => nil, "toString" => "Charlie" }]
            }
          ]
        }
      end

      it "renders field_set message in HTML" do
        expect(cause).to render_html_variant(
          a_string_including(
            I18n.t("journals.cause_descriptions.import.field_set",
                   field: "<strong>assignee</strong>", value: "Charlie")
          )
        )
      end

      it "renders field_set message in plain text" do
        expect(cause).to render_raw_variant(
          a_string_including(
            I18n.t("journals.cause_descriptions.import.field_set",
                   field: "assignee", value: "Charlie")
          )
        )
      end
    end

    context "when a field was removed (no new value)" do
      subject(:cause) do
        {
          "type" => "import",
          "import_history" => [
            {
              "author_name" => "Bob",
              "items" => [{ "field" => "assignee", "fromString" => "Charlie", "toString" => nil }]
            }
          ]
        }
      end

      it "renders field_removed message" do
        expect(cause).to render_html_variant(
          a_string_including(
            I18n.t("journals.cause_descriptions.import.field_removed",
                   field: "<strong>assignee</strong>")
          )
        )
      end
    end

    context "when a field was updated but has no from/to string" do
      subject(:cause) do
        {
          "type" => "import",
          "import_history" => [
            {
              "author_name" => "Bob",
              "items" => [{ "field" => "attachment", "fromString" => nil, "toString" => nil }]
            }
          ]
        }
      end

      it "renders field_updated message" do
        expect(cause).to render_html_variant(
          a_string_including(
            I18n.t("journals.cause_descriptions.import.field_updated",
                   field: "<strong>attachment</strong>")
          )
        )
      end
    end

    context "when a description field is set via import" do
      # build_stubbed gives the journal a fake ID so url_for can generate the diff link path
      let(:journal) { build_stubbed(:work_package_journal) }
      let(:instance) { described_class.new(journal) }

      subject(:cause) do
        {
          "type" => "import",
          "import_history" => [
            {
              "author_name" => "Bob",
              "items" => [{ "field" => "description", "fromString" => nil, "toString" => "new text" }]
            }
          ]
        }
      end

      it "renders a diff link for set_with_diff" do
        result = render(cause, html: true)
        expect(result).to include("diff")
        expect(result).to include(I18n.t("journals.cause_descriptions.import.header", author: "Bob"))
        expect(result).to match(/set.*diff|diff.*set/i)
      end
    end

    context "when a description field is changed via import" do
      let(:journal) { build_stubbed(:work_package_journal) }
      let(:instance) { described_class.new(journal) }

      subject(:cause) do
        {
          "type" => "import",
          "import_history" => [
            {
              "author_name" => "Bob",
              "items" => [{ "field" => "description", "fromString" => "old", "toString" => "new" }]
            }
          ]
        }
      end

      it "renders a diff link for changed_with_diff" do
        result = render(cause, html: true)
        expect(result).to include("diff")
        expect(result).to include("<strong>description</strong>")
      end

      it "links to the journal diff action" do
        result = render(cause, html: true)
        expect(result).to include("/journals/#{journal.id}/diff")
      end
    end

    context "when a description field is deleted via import" do
      let(:journal) { build_stubbed(:work_package_journal) }
      let(:instance) { described_class.new(journal) }

      subject(:cause) do
        {
          "type" => "import",
          "import_history" => [
            {
              "author_name" => "Bob",
              "items" => [{ "field" => "description", "fromString" => "old text", "toString" => nil }]
            }
          ]
        }
      end

      it "renders a diff link for deleted_with_diff" do
        result = render(cause, html: true)
        expect(result).to include("diff")
        expect(result).to include("<strong>description</strong>")
      end
    end

    context "when the work package was migrated" do
      subject(:cause) do
        { "type" => "import", "migrated" => true }
      end

      it "renders the migration message in HTML" do
        expect(cause).to render_html_variant(
          "<strong>#{I18n.t('journals.caused_changes.import')}</strong> " \
          "#{I18n.t('journals.cause_descriptions.import.migrated')}"
        )
      end

      it "renders the migration message in plain text" do
        expect(cause).to render_raw_variant(
          "#{I18n.t('journals.caused_changes.import')} #{I18n.t('journals.cause_descriptions.import.migrated')}"
        )
      end
    end

    context "when the work package came from a CSV import" do
      subject(:cause) do
        { "type" => "import", "csv" => true }
      end

      it "renders the CSV import message in HTML" do
        expect(cause).to render_html_variant(
          "<strong>#{I18n.t('journals.caused_changes.import')}</strong> " \
          "#{I18n.t('journals.cause_descriptions.import.csv')}"
        )
      end

      it "renders the CSV import message in plain text" do
        expect(cause).to render_raw_variant(
          "#{I18n.t('journals.caused_changes.import')} #{I18n.t('journals.cause_descriptions.import.csv')}"
        )
      end
    end

    context "when import_history is empty" do
      subject(:cause) do
        {
          "type" => "import",
          "import_history" => []
        }
      end

      it "renders without raising" do
        expect { render(cause, html: true) }.not_to raise_error
      end

      it "renders an empty description part" do
        expect(cause).to render_html_variant(
          a_string_ending_with(" ")
        )
      end
    end

    context "with multiple import history entries (grouped author blocks)" do
      subject(:cause) do
        {
          "type" => "import",
          "import_history" => [
            {
              "author_name" => "Alice",
              "items" => [{ "field" => "status", "fromString" => "Open", "toString" => "Closed" }]
            },
            {
              "author_name" => "Bob",
              "items" => [{ "field" => "priority", "fromString" => "Low", "toString" => "High" }]
            }
          ]
        }
      end

      it "renders all author blocks in HTML" do
        result = render(cause, html: true)
        expect(result).to include(I18n.t("journals.cause_descriptions.import.header", author: "Alice"))
        expect(result).to include(I18n.t("journals.cause_descriptions.import.header", author: "Bob"))
      end

      it "separates author blocks with <br/><br/> in HTML" do
        expect(cause).to render_html_variant(a_string_including("<br/><br/>"))
      end

      it "separates author blocks with double newline in plain text" do
        expect(cause).to render_raw_variant(a_string_including("\n\n"))
      end
    end

    context "when Jira-supplied values contain HTML characters (XSS prevention)" do
      context "with a malicious author name" do
        subject(:cause) do
          {
            "type" => "import",
            "import_history" => [
              {
                "author_name" => "<script>alert('xss')</script>",
                "items" => []
              }
            ]
          }
        end

        it "escapes the author name in output" do
          expect(cause).to render_html_variant(
            a_string_including("&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
          )
          expect(cause).to render_raw_variant(
            a_string_including("&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
          )
        end
      end

      context "with malicious fromString / toString field values" do
        subject(:cause) do
          {
            "type" => "import",
            "import_history" => [
              {
                "author_name" => "Alice",
                "items" => [
                  {
                    "field" => "status",
                    "fromString" => "<img src=x onerror=alert(1)>",
                    "toString" => "<b>Closed</b>"
                  }
                ]
              }
            ]
          }
        end

        it "escapes fromString in HTML output" do
          expect(cause).to render_html_variant(
            a_string_including("&lt;img src=x onerror=alert(1)&gt;")
          )
        end

        it "escapes toString in output" do
          expect(cause).to render_html_variant(
            a_string_including("&lt;b&gt;Closed&lt;/b&gt;")
          )
          expect(cause).to render_raw_variant(
            a_string_including("&lt;b&gt;Closed&lt;/b&gt;")
          )
        end
      end

      context "with malicious toString when field was set (no fromString)" do
        subject(:cause) do
          {
            "type" => "import",
            "import_history" => [
              {
                "author_name" => "Alice",
                "items" => [
                  { "field" => "assignee", "fromString" => nil, "toString" => "<script>evil()</script>" }
                ]
              }
            ]
          }
        end

        it "escapes toString in HTML output" do
          expect(cause).to render_html_variant(
            a_string_including("&lt;script&gt;evil()&lt;/script&gt;")
          )
        end
      end
    end
  end

  context "when the work package was created from a forum message" do
    shared_let(:forum) { create(:forum) }
    shared_let(:topic) { create(:message, forum:, subject: "Release planning") }
    shared_let(:reply) { create(:message, forum:, parent: topic) }

    subject(:cause) { { "type" => "forum_message", "message_id" => reply.id } }

    let(:reply_path) do
      "/projects/#{forum.project.identifier}/forums/#{forum.id}/topics/#{topic.id}?r=#{reply.id}#message-#{reply.id}"
    end

    context "when the user can see the message" do
      current_user { create(:user, member_with_permissions: { forum.project => %i[view_messages] }) }

      it do
        expect(cause).to render_html_variant(
          "<strong>Created from forum message</strong> #{link_to('Release planning', reply_path)}"
        )
      end

      it { expect(cause).to render_raw_variant("Created from forum message Release planning") }

      it "escapes a malicious topic subject when rendering HTML", :aggregate_failures do
        topic.update_column(:subject, "<script>alert('xss')</script>")

        expect(cause).to render_html_variant(a_string_including("&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"))
        expect(cause).not_to render_html_variant(a_string_including("<script>"))
      end
    end

    context "when the user cannot see the message" do
      current_user { create(:user) }

      it "says where the work package came from without naming the topic", :aggregate_failures do
        expect(cause).to render_html_variant("<strong>Created from forum message</strong> ")
        expect(cause).to render_raw_variant("Created from forum message")
      end
    end

    context "when the message has been deleted" do
      subject(:cause) { { "type" => "forum_message", "message_id" => 0 } }

      it "marks it deleted", :aggregate_failures do
        expect(cause).to render_html_variant("<strong>Created from forum message</strong> (deleted)")
        expect(cause).to render_raw_variant("Created from forum message (deleted)")
      end
    end
  end

  context "when the change came in by email" do
    subject(:cause) { { "type" => "email", "sender_address" => "jane@customer.example" } }

    it { expect(cause).to render_html_variant("<strong>Via email</strong> from jane@customer.example") }
    it { expect(cause).to render_raw_variant("Via email from jane@customer.example") }

    context "with an apostrophe in the sender address" do
      subject(:cause) { { "type" => "email", "sender_address" => "o'brien@customer.example" } }

      it { expect(cause).to render_html_variant("<strong>Via email</strong> from o&#39;brien@customer.example") }
      it { expect(cause).to render_raw_variant("Via email from o'brien@customer.example") }
    end

    context "with markup in the sender address" do
      subject(:cause) { { "type" => "email", "sender_address" => "<script>alert('xss')</script>@customer.example" } }

      it "escapes it when rendering HTML", :aggregate_failures do
        expect(cause).to render_html_variant(a_string_including("&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"))
        expect(cause).not_to render_html_variant(a_string_including("<script>"))
      end
    end
  end
end
