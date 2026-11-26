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

  shared_let(:work_package) { create(:work_package) }

  context "when the change was caused by adding the work package to a meeting" do
    shared_let(:meeting) { create(:meeting, title: "Weekly sync") }
    subject(:cause) do
      {
        "type" => "meeting_agenda_item_added",
        "meeting_id" => meeting.id
      }
    end

    context "when the user can access the meeting" do
      before do
        allow(Meeting).to receive(:find_by).with(id: meeting.id).and_return(meeting)
        allow(meeting).to receive(:visible?).with(User.current).and_return(true)
      end

      it do
        link = link_to("#{meeting.title} – #{format_time(meeting.start_time)}", meeting_path(meeting))
        expect(cause).to render_html_variant(
          I18n.t("journals.caused_changes.meeting_agenda_item_added_html", meeting_title_information: link)
        )
      end

      it do
        label = "#{meeting.title} – #{format_time(meeting.start_time)}"
        expect(cause).to render_raw_variant(
          ActionController::Base.helpers.strip_tags(
            I18n.t("journals.caused_changes.meeting_agenda_item_added_html", meeting_title_information: label)
          )
        )
      end

      it "escapes a malicious meeting title when rendering HTML" do
        allow(meeting).to receive(:title).and_return("<script>alert('xss')</script>")
        expect(cause).to render_html_variant(a_string_including("&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"))
        expect(cause).not_to render_html_variant(a_string_including("<script>alert('xss')</script>"))
      end
    end

    context "when the user cannot access the meeting" do
      before do
        allow(Meeting).to receive(:find_by).with(id: meeting.id).and_return(meeting)
        allow(meeting).to receive(:visible?).with(User.current).and_return(false)
      end

      it "renders nothing at all, leaking neither the meeting nor the action" do
        expect(cause).to render_html_variant("")
        expect(cause).to render_raw_variant("")
      end
    end

    context "when the meeting has been deleted" do
      before do
        allow(Meeting).to receive(:find_by).with(id: meeting.id).and_return(nil)
      end

      it "keeps the entry with a generic label" do
        expect(cause).to render_html_variant(
          I18n.t("journals.caused_changes.meeting_agenda_item_added_html",
                 meeting_title_information: I18n.t("journals.cause_descriptions.meeting_deleted"))
        )
      end
    end

    context "when the meeting has been cancelled" do
      before do
        allow(Meeting).to receive(:find_by).with(id: meeting.id).and_return(meeting)
        allow(meeting).to receive(:visible?).with(User.current).and_return(true)
        allow(meeting).to receive(:cancelled?).and_return(true)
      end

      it "renders the meeting label as plain text with '(cancelled)'" do
        label = "#{meeting.title} – #{format_time(meeting.start_time)}"
        cancelled = I18n.t("journals.cause_descriptions.meeting_cancelled")
        expect(cause).to render_html_variant(
          I18n.t("journals.caused_changes.meeting_agenda_item_added_html",
                 meeting_title_information: "#{label} #{cancelled}")
        )
      end

      it "renders the meeting label with '(cancelled)' when rendering raw text" do
        label = "#{meeting.title} – #{format_time(meeting.start_time)}"
        cancelled = I18n.t("journals.cause_descriptions.meeting_cancelled")
        expect(cause).to render_raw_variant(
          ActionController::Base.helpers.strip_tags(
            I18n.t("journals.caused_changes.meeting_agenda_item_added_html",
                   meeting_title_information: "#{label} #{cancelled}")
          )
        )
      end

      it "escapes a malicious meeting title when rendering HTML" do
        allow(meeting).to receive(:title).and_return("<script>alert('xss')</script>")
        expect(cause).to render_html_variant(a_string_including("&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"))
        expect(cause).not_to render_html_variant(a_string_including("<script>alert('xss')</script>"))
      end
    end
  end

  context "when the change was caused by removing the work package from a meeting" do
    shared_let(:meeting) { create(:meeting, title: "Weekly sync") }
    subject(:cause) do
      {
        "type" => "meeting_agenda_item_removed",
        "meeting_id" => meeting.id
      }
    end

    before do
      allow(Meeting).to receive(:find_by).with(id: meeting.id).and_return(meeting)
      allow(meeting).to receive(:visible?).with(User.current).and_return(true)
    end

    it do
      link = link_to("#{meeting.title} – #{format_time(meeting.start_time)}", meeting_path(meeting))
      expect(cause).to render_html_variant(
        I18n.t("journals.caused_changes.meeting_agenda_item_removed_html", meeting_title_information: link)
      )
    end
  end

  context "when the change was caused by moving the work package to another meeting" do
    shared_let(:meeting) { create(:meeting, title: "Weekly sync") }
    subject(:cause) do
      {
        "type" => "meeting_agenda_item_moved",
        "meeting_id" => meeting.id
      }
    end

    before do
      allow(Meeting).to receive(:find_by).with(id: meeting.id).and_return(meeting)
      allow(meeting).to receive(:visible?).with(User.current).and_return(true)
    end

    it do
      link = link_to("#{meeting.title} – #{format_time(meeting.start_time)}", meeting_path(meeting))
      expect(cause).to render_html_variant(
        I18n.t("journals.caused_changes.meeting_agenda_item_moved_html", meeting_title_information: link)
      )
    end
  end

  context "when the change was caused by discussing the work package in a meeting" do
    shared_let(:meeting) { create(:meeting, title: "Weekly sync") }
    let(:outcome) { create(:meeting_outcome) }

    subject(:cause) do
      {
        "type" => "meeting_agenda_item_discussed",
        "meeting_id" => meeting.id,
        "outcome_id" => outcome.id
      }
    end

    before do
      allow(Meeting).to receive(:find_by).with(id: meeting.id).and_return(meeting)
      allow(meeting).to receive(:visible?).with(User.current).and_return(true)
    end

    it do
      link = link_to("#{meeting.title} – #{format_time(meeting.start_time)}", meeting_path(meeting))
      expect(cause).to render_html_variant(
        I18n.t("journals.caused_changes.meeting_agenda_item_discussed_html", meeting_title_information: link)
      )
    end

    context "when the outcome has since been deleted" do
      before { outcome.destroy }

      it "renders nothing, hiding the stale discussion entry" do
        expect(cause).to render_html_variant("")
        expect(cause).to render_raw_variant("")
      end
    end

    context "when the cause predates outcome tracking (legacy data with no outcome_id)" do
      subject(:cause) { { "type" => "meeting_agenda_item_discussed", "meeting_id" => meeting.id } }

      it "still renders, since the referenced outcome is unknown" do
        link = link_to("#{meeting.title} – #{format_time(meeting.start_time)}", meeting_path(meeting))
        expect(cause).to render_html_variant(
          I18n.t("journals.caused_changes.meeting_agenda_item_discussed_html", meeting_title_information: link)
        )
      end
    end

    context "when the outcome was deleted and a later one added (add → delete → add)" do
      it "hides only the entry of the deleted outcome, keeping the later one" do
        deleted_outcome = create(:meeting_outcome)
        later_outcome = create(:meeting_outcome)
        deleted_outcome.destroy

        stale_cause = { "type" => "meeting_agenda_item_discussed", "meeting_id" => meeting.id,
                        "outcome_id" => deleted_outcome.id }
        later_cause = { "type" => "meeting_agenda_item_discussed", "meeting_id" => meeting.id,
                        "outcome_id" => later_outcome.id }

        expect(stale_cause).to render_html_variant("")

        link = link_to("#{meeting.title} – #{format_time(meeting.start_time)}", meeting_path(meeting))
        expect(later_cause).to render_html_variant(
          I18n.t("journals.caused_changes.meeting_agenda_item_discussed_html", meeting_title_information: link)
        )
      end
    end

    context "when the whole meeting was deleted, cascading the outcome" do
      before do
        outcome.destroy
        allow(Meeting).to receive(:find_by).with(id: meeting.id).and_return(nil)
      end

      it "keeps the entry with a generic label instead of hiding it" do
        expect(cause).to render_html_variant(
          I18n.t("journals.caused_changes.meeting_agenda_item_discussed_html",
                 meeting_title_information: I18n.t("journals.cause_descriptions.meeting_deleted"))
        )
      end
    end
  end

  context "when the change was caused by adding a work package outcome in a meeting" do
    shared_let(:meeting) { create(:meeting, title: "Weekly sync") }
    let(:outcome) { create(:meeting_outcome) }

    subject(:cause) do
      {
        "type" => "meeting_outcome_recorded",
        "meeting_id" => meeting.id,
        "outcome_id" => outcome.id
      }
    end

    before do
      allow(Meeting).to receive(:find_by).with(id: meeting.id).and_return(meeting)
      allow(meeting).to receive(:visible?).with(User.current).and_return(true)
    end

    it do
      link = link_to("#{meeting.title} – #{format_time(meeting.start_time)}", meeting_path(meeting))
      expect(cause).to render_html_variant(
        I18n.t("journals.caused_changes.meeting_outcome_recorded_html", meeting_title_information: link)
      )
    end

    context "when the outcome has since been deleted" do
      before { outcome.destroy }

      it "renders nothing, hiding the stale outcome entry" do
        expect(cause).to render_html_variant("")
        expect(cause).to render_raw_variant("")
      end
    end

    context "when the cause predates outcome tracking (legacy data with no outcome_id)" do
      subject(:cause) { { "type" => "meeting_outcome_recorded", "meeting_id" => meeting.id } }

      it "still renders, since the referenced outcome is unknown" do
        link = link_to("#{meeting.title} – #{format_time(meeting.start_time)}", meeting_path(meeting))
        expect(cause).to render_html_variant(
          I18n.t("journals.caused_changes.meeting_outcome_recorded_html", meeting_title_information: link)
        )
      end
    end
  end

  context "when the change references a recurring meeting series template" do
    shared_let(:recurring_meeting) { create(:recurring_meeting, title: "Weekly series") }
    let(:template) { recurring_meeting.reload.template }
    let(:series_link) { link_to(template.title, meeting_path(template)) }

    before do
      allow(Meeting).to receive(:find_by).and_call_original
      allow(Meeting).to receive(:find_by).with(id: template.id).and_return(template)
      allow(template).to receive(:visible?).with(User.current).and_return(true)
    end

    context "when added to the template" do
      subject(:cause) { { "type" => "meeting_agenda_item_added", "meeting_id" => template.id } }

      it do
        expect(cause).to render_html_variant(
          I18n.t("journals.caused_changes.meeting_agenda_item_added_template_html",
                 meeting_title_information: I18n.t("journals.cause_descriptions.meeting_series_template_html", link: series_link))
        )
      end
    end

    context "when removed from the template" do
      subject(:cause) { { "type" => "meeting_agenda_item_removed", "meeting_id" => template.id } }

      it do
        expect(cause).to render_html_variant(
          I18n.t("journals.caused_changes.meeting_agenda_item_removed_template_html",
                 meeting_title_information: I18n.t("journals.cause_descriptions.meeting_series_template_html", link: series_link))
        )
      end
    end

    context "when moved to the series backlog" do
      shared_let(:occurrence) { create(:recurring_meeting_occurrence, recurring_meeting:) }
      let!(:backlog_item) do
        create(:wp_meeting_agenda_item, meeting: template, meeting_section: template.backlog, work_package:)
      end
      let(:instance) { described_class.new(build(:work_package_journal, journable: work_package)) }

      subject(:cause) do
        { "type" => "meeting_agenda_item_moved", "meeting_id" => template.id, "source_meeting_id" => occurrence.id }
      end

      it "links to the source occurrence's page, not the template" do
        link = link_to(template.title, meeting_path(occurrence, anchor: "meeting-agenda-item-#{backlog_item.id}"))
        expect(cause).to render_html_variant(
          I18n.t("journals.caused_changes.meeting_agenda_item_moved_template_html",
                 meeting_title_information: I18n.t("journals.cause_descriptions.meeting_series_backlog_html", link:))
        )
      end
    end
  end

  context "when the change references a onetime meeting template" do
    shared_let(:template) { create(:onetime_template, title: "Sprint review template") }
    subject(:cause) { { "type" => "meeting_agenda_item_added", "meeting_id" => template.id } }

    before do
      allow(Meeting).to receive(:find_by).with(id: template.id).and_return(template)
      allow(template).to receive(:visible?).with(User.current).and_return(true)
    end

    it do
      link = link_to(template.title, meeting_path(template))
      expect(cause).to render_html_variant(
        I18n.t("journals.caused_changes.meeting_agenda_item_added_template_html",
               meeting_title_information: I18n.t("journals.cause_descriptions.meeting_template_html", link:))
      )
    end
  end

  describe "deep-linking the meeting label to an agenda item" do
    shared_let(:meeting) { create(:meeting, title: "Weekly sync") }
    let(:instance) { described_class.new(build(:work_package_journal, journable: work_package)) }
    let(:label) { "#{meeting.title} – #{format_time(meeting.start_time)}" }

    before do
      allow(Meeting).to receive(:find_by).with(id: meeting.id).and_return(meeting)
      allow(meeting).to receive(:visible?).with(User.current).and_return(true)
    end

    context "for add/move/discuss" do
      shared_let(:agenda_item) { create(:wp_meeting_agenda_item, meeting:, work_package:) }

      it "anchors to the work package's own agenda item" do
        cause = { "type" => "meeting_agenda_item_added", "meeting_id" => meeting.id }
        link = link_to(label, meeting_path(meeting, anchor: "meeting-agenda-item-#{agenda_item.id}"))
        expect(cause).to render_html_variant(
          I18n.t("journals.caused_changes.meeting_agenda_item_added_html", meeting_title_information: link)
        )
      end
    end

    context "for a removal" do
      it "links to the meeting only, without an anchor" do
        cause = { "type" => "meeting_agenda_item_removed", "meeting_id" => meeting.id }
        link = link_to(label, meeting_path(meeting))
        expect(cause).to render_html_variant(
          I18n.t("journals.caused_changes.meeting_agenda_item_removed_html", meeting_title_information: link)
        )
      end
    end

    context "for an outcome work package" do
      shared_let(:parent_item) { create(:wp_meeting_agenda_item, meeting:) }
      shared_let(:outcome) do
        create(:meeting_outcome, meeting_agenda_item: parent_item, work_package:, kind: :work_package)
      end

      it "anchors to the outcome's parent agenda item" do
        cause = { "type" => "meeting_outcome_recorded", "meeting_id" => meeting.id }
        link = link_to(label, meeting_path(meeting, anchor: "meeting-agenda-item-#{parent_item.id}"))
        expect(cause).to render_html_variant(
          I18n.t("journals.caused_changes.meeting_outcome_recorded_html", meeting_title_information: link)
        )
      end
    end
  end
end
