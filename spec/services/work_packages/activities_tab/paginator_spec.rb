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

RSpec.describe WorkPackages::ActivitiesTab::Paginator, with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, :created_in_past, project:, author: user, created_at: 4.days.ago) }

  let(:params) { {} }
  let(:paginator) { described_class.new(work_package, params) }

  before do
    allow(User).to receive(:current).and_return(user)
  end

  describe "#call" do
    context "with no additional journals" do
      let(:work_package) { create(:work_package, project:, author: user) }

      it "returns paginated results with the initial journal" do
        pagy, records = paginator.call

        expect(pagy).to be_a(Pagy)
        expect(pagy.page).to eq(1)
        expect(pagy.count).to eq(1)
        expect(records).to have_attributes(size: 1)
        expect(records.first).to be_a(API::V3::Activities::ActivityEagerLoadingWrapper)
      end
    end

    context "with multiple journals" do
      3.times do |i|
        let!(:"journal_#{i + 1}") do
          create(:work_package_journal, user:, notes: "Comment #{i + 1}", journable: work_package, version: i + 2)
        end
      end

      context "when user preference is set to asc sorting" do
        before do
          user.pref.update!(comments_sorting: :asc)
        end

        it "returns journals reversed (oldest first)" do
          _pagy, records = paginator.call

          expect(records.map(&:notes)).to eq(["", journal_1.notes, journal_2.notes, journal_3.notes])
        end
      end

      context "when user preference is set to desc sorting" do
        before do
          user.pref.update!(comments_sorting: :desc)
        end

        it "returns journals in DESC order (newest first)" do
          _pagy, records = paginator.call

          expect(records.map(&:notes)).to eq([journal_3.notes, journal_2.notes, journal_1.notes, ""])
        end
      end
    end

    context "with changesets" do
      let(:repository) { create(:repository_subversion, project:) }

      2.times do |i|
        let!(:"changeset_#{i + 1}") do
          create(:changeset,
                 repository:,
                 committed_on: (2 - i).days.ago, # yesterday and today
                 revision: "rev#{i + 1}")
        end
      end

      before do
        work_package.changesets << [changeset_1, changeset_2]
      end

      it "includes changesets in the sorted results" do
        _pagy, records = paginator.call

        expect(records.size).to eq(3) # 1 initial journal + 2 changesets
        expect(records).to include(changeset_1, changeset_2)
      end

      it "sorts changesets along with journals by timestamp" do
        user.pref.update!(comments_sorting: :desc)
        journal = create(:work_package_journal,
                         user:,
                         notes: "Comment between changesets",
                         journable: work_package,
                         version: work_package.journals.last.version + 1,
                         created_at: 1.5.days.ago)

        _pagy, records = paginator.call
        expect(records).to eq([changeset_2, journal, changeset_1, work_package.journals.first])
      end

      it "preloads changeset projects so rendering them issues no per-row query" do
        _pagy, records = paginator.call
        changesets = records.grep(Changeset)

        expect(changesets.size).to eq(2)
        # format_text(changeset, :comments) reads changeset.project (a has_one
        # through :repository) for each row at render time.
        expect { changesets.each(&:project) }.to have_a_query_limit(0)
      end
    end

    context "with pagination" do
      # Create enough journals to span multiple pages (using limit of 5 for testing)
      let(:test_limit) { 5 }

      10.times do |i|
        let!(:"journal_#{i + 1}") do
          create(:work_package_journal, user:, notes: "Comment #{i + 1}", journable: work_package, version: i + 2)
        end
      end

      before do
        params[:limit] = test_limit
      end

      it "returns the first page with specified limit" do
        pagy, records = paginator.call

        expect(pagy.page).to eq(1)
        expect(pagy.count).to eq(11) # 10 journals + 1 initial
        expect(pagy.pages).to eq(3)
        expect(records.size).to eq(test_limit)
      end

      it "returns the second page when requested" do
        params[:page] = 2
        pagy, records = paginator.call

        expect(pagy.page).to eq(2)
        expect(records.size).to eq(test_limit)
      end

      context "with anchor to target journal" do
        context "with comment anchor" do
          it "returns the page containing the target journal" do
            params[:anchor] = "comment-#{journal_1.id}"
            pagy, records = paginator.call

            # journal_1 is old, so it should be on page 2
            expect(pagy.page).to eq(2)
            expect(records.map(&:id)).to include(journal_1.id)
          end

          it "handles invalid anchor format gracefully" do
            params[:anchor] = "invalid-anchor"
            pagy, _records = paginator.call

            expect(pagy.page).to eq(1)
          end

          it "falls back to page 1 if journal not found" do
            params[:anchor] = "comment-999999"
            pagy, _records = paginator.call

            expect(pagy.page).to eq(1)
          end

          it "falls back to page 1 even when params[:page] is set alongside an unresolvable anchor" do
            params[:anchor] = "comment-999999"
            params[:page] = 3
            pagy, _records = paginator.call

            expect(pagy.page).to eq(1)
          end

          it "resolves the anchor page when the limit arrives as a query string" do
            params[:anchor] = "comment-#{journal_1.id}"
            params[:limit] = test_limit.to_s
            pagy, records = paginator.call

            expect(pagy.page).to eq(2)
            expect(records.map(&:id)).to include(journal_1.id)
          end

          it "leaves resolved_anchor nil for comment anchors" do
            params[:anchor] = "comment-#{journal_1.id}"
            paginator.call

            expect(paginator.resolved_anchor).to be_nil
          end
        end

        context "with activity anchor" do
          it "returns the page containing the target activity and resolves it to the comment id" do
            params[:anchor] = "activity-2"
            pagy, records = paginator.call

            # activity-2 is the journal with sequence_version 2, i.e. journal_1
            expect(pagy.page).to eq(2)
            expect(records.map(&:id)).to include(journal_1.id)
            expect(paginator.resolved_anchor).to eq(journal_1.id)
          end

          it "handles an activity anchor for the initial journal" do
            params[:anchor] = "activity-1"
            _pagy, records = paginator.call

            # activity-1 is the oldest journal, on the last page
            initial_journal = work_package.journals.order(:version).first
            expect(records.map(&:id)).to include(initial_journal.id)
            expect(paginator.resolved_anchor).to eq(initial_journal.id)
          end
        end
      end
    end

    context "with a large activity history" do
      let(:test_limit) { 2 }

      before do
        8.times do |i|
          create(:work_package_journal, user:, notes: "Comment #{i + 1}", journable: work_package, version: i + 2)
        end
        params[:limit] = test_limit
      end

      it "resolves an anchor to the oldest journal on the last page" do
        oldest_journal = work_package.journals.order(:version).first
        params[:anchor] = "comment-#{oldest_journal.id}"
        pagy, records = paginator.call

        expect(records.map(&:id)).to include(oldest_journal.id)
        expect(pagy.page).to eq(5)
      end

      it "issues a bounded number of queries regardless of history size" do
        described_class.new(work_package, params).call # warm autoloads + caches

        50.times { |i| create(:work_package_journal, user:, journable: work_package, version: 10 + i) }

        recorder = ActiveRecord::QueryRecorder.new do
          described_class.new(work_package, params).call
        end

        # The wrapper runs against the page slice, so query count does not scale
        # with history size. Ceiling leaves headroom for an extra eager-load
        # without becoming brittle; actual count today is ~10.
        expect(recorder.count).to be < 20,
                                  "expected query count bounded regardless of history; got #{recorder.count}:\n" \
                                  "#{recorder.log.join("\n")}"
      end

      it "skips the sequence-version window function on the default render path" do
        recorder = ActiveRecord::QueryRecorder.new do
          described_class.new(work_package, params).call
        end

        expect(recorder.log.join("\n")).not_to match(/ROW_NUMBER|JOIN LATERAL/i),
                                               "expected no window function without an activity anchor:\n" \
                                               "#{recorder.log.join("\n")}"
      end

      it "computes the sequence version only when resolving an activity anchor" do
        recorder = ActiveRecord::QueryRecorder.new do
          described_class.new(work_package, params.merge(anchor: "activity-2")).call
        end

        expect(recorder.log.join("\n")).to match(/ROW_NUMBER|JOIN LATERAL/i)
      end
    end

    context "when the page holds comment journals carrying inline attachments" do
      let!(:comment_journals) do
        Array.new(3) do |i|
          journal = create(:work_package_journal,
                           user:, notes: "Comment #{i}", journable: work_package, version: i + 2)
          create(:attachment, container: journal, author: user, filename: "inline_#{i}.png")
          journal
        end
      end

      # Rendering a comment body reads `journal.attachments` (the inline-image
      # rewrite), so the page slice must preload them or each comment costs a query.
      it "preloads journal attachments so rendering bodies does not query per comment" do
        _pagy, records = paginator.call
        journals = records.grep_v(Changeset)

        recorder = ActiveRecord::QueryRecorder.new do
          journals.each { it.attachments.to_a }
        end

        attachment_queries = recorder.log.count { it.match?(/FROM\s+"attachments"/) && it.include?("container_type") }
        expect(attachment_queries).to eq(0),
                                      "expected journal attachments preloaded; got #{attachment_queries}:\n" \
                                      "#{recorder.log.join("\n")}"
      end
    end

    # The journal factory chains each predecessor's `validity_period` upper
    # bound to the next journal's `created_at`; two journals at the same
    # `created_at` produce an empty range and trip the
    # `validity_period_not_empty` constraint. A journal + changeset pair
    # sidesteps that while still exercising the secondary id sort.
    context "with a journal and a changeset at the same timestamp" do
      let(:repository) { create(:repository_subversion, project:) }
      let(:shared_time) { 1.day.ago }
      let(:work_package) do
        create(:work_package,
               project:,
               author: user,
               journals: { shared_time => { notes: "Tied with changeset" } })
      end
      let(:tied_journal) { work_package.journals.sole }
      let!(:tied_changeset) do
        create(:changeset, repository:, committed_on: shared_time, revision: "tied")
      end

      before do
        # Default sort can be :asc, which reverses the records. Pin to :desc so
        # the relation's `id DESC` secondary sort surfaces in the result.
        user.pref.update!(comments_sorting: :desc)
        work_package.changesets << tied_changeset
      end

      it "breaks ties by the journal id descending" do
        _pagy, records = paginator.call

        # A changeset surfaces through its own journal, so the feed orders both
        # rows by journal id; the record whose journal id is higher must lead.
        changeset_journal_id = Journal.where(journable: tied_changeset).pick(:id)
        leader, trailer =
          if changeset_journal_id > tied_journal.id
            [tied_changeset.id, tied_journal.id]
          else
            [tied_journal.id, tied_changeset.id]
          end

        expect(records.map(&:id)).to eq([leader, trailer])
      end
    end

    context "with internal comments filtering" do
      let!(:internal_journal) do
        create(:work_package_journal,
               user:,
               notes: "Internal comment",
               journable: work_package,
               internal: true,
               version: 2)
      end
      let!(:public_journal) do
        create(:work_package_journal,
               user:,
               notes: "Public comment",
               journable: work_package,
               internal: false,
               version: 3)
      end

      before do
        work_package.project.enabled_internal_comments = true
        work_package.project.save!
      end

      context "when user can see internal comments", with_ee: [:internal_comments] do
        it "includes internal journals" do
          _pagy, records = paginator.call

          journal_notes = records.map(&:notes)
          expect(journal_notes).to include("Internal comment", "Public comment")
        end
      end

      context "when user cannot see internal comments" do
        let(:member_role) { create(:project_role, permissions: %i[view_work_packages]) }
        let(:member_user) { create(:user, member_with_roles: { project => member_role }) }
        let(:internal_sequence_version) do
          Journal
            .where(journable: work_package)
            .with_sequence_version
            .where(id: internal_journal.id)
            .pick("ranked.sequence_version")
        end

        before do
          allow(User).to receive(:current).and_return(member_user)
        end

        it "excludes internal journals" do
          _pagy, records = described_class.new(work_package, params).call

          journal_notes = records.map(&:notes)
          expect(journal_notes).not_to include("Internal comment")
          expect(journal_notes).to include("Public comment")
        end

        it "falls back to page 1 when anchoring to an internal journal" do
          params[:anchor] = "comment-#{internal_journal.id}"
          pagy, _records = described_class.new(work_package, params).call

          expect(pagy.page).to eq(1)
        end

        it "falls back to page 1 and resolves no anchor for an internal journal by sequence_version" do
          paginator = described_class.new(work_package, params.merge(anchor: "activity-#{internal_sequence_version}"))
          pagy, _records = paginator.call

          expect(pagy.page).to eq(1)
          expect(paginator.resolved_anchor).to be_nil
        end
      end
    end

    context "with :only_comments filter" do
      let!(:journal_with_notes) do
        create(:work_package_journal,
               user:,
               notes: "This is a comment",
               journable: work_package,
               version: 2)
      end
      let!(:journal_without_notes) do
        create(:work_package_journal,
               user:,
               notes: "",
               journable: work_package,
               version: 3)
      end

      before do
        params[:filter] = :only_comments
      end

      it "includes journals with notes" do
        _pagy, records = paginator.call

        journal_notes = records.map(&:notes)
        expect(journal_notes).to include("This is a comment")
      end

      it "excludes journals without notes" do
        _pagy, records = paginator.call

        expect(records.map(&:id)).not_to include(journal_without_notes.id)
      end

      context "with changesets" do
        let(:repository) { create(:repository_subversion, project:) }
        let!(:changeset) do
          create(:changeset,
                 repository:,
                 committed_on: 1.day.ago,
                 revision: "rev1")
        end

        before do
          work_package.changesets << changeset
        end

        it "excludes changesets (code commits are not comments)" do
          _pagy, records = paginator.call

          expect(records).not_to include(changeset)
        end
      end

      context "with pagination" do
        let(:test_limit) { 2 }

        before do
          # Create journals with notes by updating work package
          work_package.subject = "Updated 1"
          work_package.save!
          work_package.journals.last.update_column(:notes, "Comment 1")

          work_package.subject = "Updated 2"
          work_package.save!
          work_package.journals.last.update_column(:notes, "Comment 2")

          params[:limit] = test_limit
        end

        it "paginates filtered results correctly" do
          pagy, records = paginator.call

          expect(pagy.count).to be >= 2
          expect(records.size).to eq(test_limit)
        end
      end
    end

    context "with :only_changes filter" do
      let(:initial_journal) { work_package.journals.find_by(version: 1) }

      before do
        params[:filter] = :only_changes
      end

      it "includes the initial journal (version = 1)" do
        _pagy, records = paginator.call

        expect(records.map(&:id)).to include(initial_journal.id)
      end

      context "with changesets" do
        let(:repository) { create(:repository_subversion, project:) }
        let!(:changeset) do
          create(:changeset,
                 repository:,
                 committed_on: 1.day.ago,
                 revision: "rev1")
        end

        before do
          work_package.changesets << changeset
        end

        it "includes changesets (commits are activity, not attribute-diffable journals)" do
          _pagy, records = paginator.call

          expect(records).to include(changeset)
        end
      end

      context "with attribute changes" do
        let!(:journal_with_attribute_change) do
          work_package.subject = "Updated subject"
          work_package.save!
          work_package.journals.order(:version).last
        end

        it "includes journals with attribute changes" do
          _pagy, records = paginator.call

          changes = journal_with_attribute_change.reload.get_changes
          expect(changes).to have_key("subject")
          expect(records.map(&:id)).to include(journal_with_attribute_change.id)
        end
      end

      context "with only notes added (no attribute/association changes)" do
        let!(:notes_only_journal) do
          work_package.add_journal(notes: "Comment only")
          work_package.save!
          work_package.journals.order(:version).last
        end

        it "excludes journals with only notes (no actual changes to track)" do
          _pagy, records = paginator.call

          changes = notes_only_journal.reload.get_changes
          expect(changes).to eq({}) # no changes
          expect(records.map(&:id)).not_to include(notes_only_journal.id)
        end
      end

      context "with cause change" do
        let!(:journal_with_cause) do
          work_package.subject = "Changed by system"
          work_package.save!
          journal = work_package.journals.last
          journal.update_column(:cause, { type: "system_update" })
          journal
        end

        it "includes journals with cause metadata" do
          _pagy, records = paginator.call

          changes = journal_with_cause.reload.get_changes
          expect(changes.keys).to contain_exactly("subject", "cause")
          expect(records.map(&:id)).to include(journal_with_cause.id)
        end
      end

      context "with attachment changes" do
        let!(:journal_with_attachment_added) do
          attachment = create(:attachment, container: nil, author: user)
          work_package.attachments << attachment
          work_package.save!
          work_package.journals.order(:version).last
        end

        let(:attachment) { journal_with_attachment_added.attachable_journals.first&.attachment }

        let!(:journal_with_attachment_snapshot) do
          work_package.add_journal(notes: "Unrelated to Attachments change")
          work_package.save!
          work_package.journals.order(:version).last
        end

        it "includes journal where attachment was added" do
          _pagy, records = paginator.call
          expect(records.map(&:id)).to include(journal_with_attachment_added.id)

          changes = journal_with_attachment_added.reload.get_changes
          expect(changes).to have_key("attachments_#{attachment.id}")
        end

        it "excludes journal with only attachment snapshot" do
          _pagy, records = paginator.call

          expect(journal_with_attachment_snapshot.reload.attachable_journals.count).to eq(1)
          changes = journal_with_attachment_snapshot.reload.get_changes
          expect(changes).to eq({}) # no changes

          expect(records.map(&:id)).not_to include(journal_with_attachment_snapshot.id)
        end
      end

      context "with custom field value changes" do
        let!(:custom_field) { create(:work_package_custom_field, field_format: "string") }

        let!(:journal_with_cf_set) do
          project.work_package_custom_fields << custom_field
          work_package.type.custom_fields << custom_field
          work_package.custom_field_values = { custom_field.id => "Value" }
          work_package.save!
          work_package.journals.order(:version).last
        end

        let!(:journal_with_cf_snapshot) do
          work_package.add_journal(notes: "Unrelated to CF change")
          work_package.save!
          work_package.journals.order(:version).last
        end

        it "includes journal where custom field was set" do
          _pagy, records = paginator.call
          expect(records.map(&:id)).to include(journal_with_cf_set.id)

          changes = journal_with_cf_set.reload.get_changes
          expect(changes).to have_key("custom_fields_#{custom_field.id}")
        end

        it "excludes journal with only custom field snapshot" do
          _pagy, records = paginator.call

          expect(journal_with_cf_snapshot.reload.customizable_journals.count).to eq(1)
          changes = journal_with_cf_snapshot.reload.get_changes
          expect(changes).to eq({}) # no changes

          expect(records.map(&:id)).not_to include(journal_with_cf_snapshot.id)
        end
      end

      context "with multi-value custom field" do
        let!(:multi_select_cf) do
          create(:work_package_custom_field,
                 field_format: "list",
                 multi_value: true,
                 possible_values: ["Option 1", "Option 2", "Option 3"])
        end
        let!(:option1) { multi_select_cf.custom_options.find_by(value: "Option 1") }
        let!(:option2) { multi_select_cf.custom_options.find_by(value: "Option 2") }
        let!(:option3) { multi_select_cf.custom_options.find_by(value: "Option 3") }

        let!(:other_cf) { create(:work_package_custom_field, field_format: "string") }

        let!(:journal_with_multi_cf_set) do
          project.work_package_custom_fields << multi_select_cf
          project.work_package_custom_fields << other_cf
          work_package.type.custom_fields << multi_select_cf
          work_package.type.custom_fields << other_cf
          work_package.custom_field_values = { multi_select_cf.id => [option1.id, option2.id] }
          work_package.save!
          work_package.journals.order(:version).last
        end

        let!(:journal_with_multi_cf_snapshot) do
          work_package.add_journal(notes: "Just a comment")
          work_package.save!
          work_package.journals.order(:version).last
        end

        it "includes journal where multi-value custom field was set" do
          _pagy, records = paginator.call
          expect(records.map(&:id)).to include(journal_with_multi_cf_set.id)

          changes = journal_with_multi_cf_set.reload.get_changes
          expect(changes).to have_key("custom_fields_#{multi_select_cf.id}")
        end

        it "excludes journal with only notes and multi-value CF snapshot" do
          _pagy, records = paginator.call

          expect(journal_with_multi_cf_snapshot.reload.customizable_journals.count).to eq(2)

          changes = journal_with_multi_cf_snapshot.reload.get_changes
          expect(changes).not_to have_key("custom_fields_#{multi_select_cf.id}")
          expect(changes).not_to have_key("custom_fields_#{other_cf.id}")

          expect(records.map(&:id)).not_to include(journal_with_multi_cf_snapshot.id)
        end

        context "when adding an option to existing selection" do
          let!(:journal_adding_option) do
            journal_with_multi_cf_snapshot

            work_package.reload.custom_field_values = { multi_select_cf.id => [option1.id, option2.id, option3.id] }
            work_package.save!
            work_package.journals.order(:version).last
          end

          it "detects the addition as a change" do
            _pagy, records = paginator.call

            expect(records.map(&:id)).to include(journal_adding_option.id)

            changes = journal_adding_option.reload.get_changes
            expect(changes).to have_key("custom_fields_#{multi_select_cf.id}")

            change = changes["custom_fields_#{multi_select_cf.id}"]
            new_value, old_value = change
            expect(new_value).not_to eq(old_value)
          end
        end

        context "when removing an option from existing selection" do
          let!(:journal_removing_option) do
            journal_with_multi_cf_snapshot

            work_package.reload.custom_field_values = { multi_select_cf.id => [option1.id] }
            work_package.save!
            work_package.journals.order(:version).last
          end

          it "detects the removal as a change" do
            _pagy, records = paginator.call

            expect(records.map(&:id)).to include(journal_removing_option.id)

            changes = journal_removing_option.reload.get_changes
            expect(changes).to have_key("custom_fields_#{multi_select_cf.id}")

            change = changes["custom_fields_#{multi_select_cf.id}"]
            new_value, old_value = change
            expect(new_value).not_to eq(old_value)
          end
        end

        context "when changing options (adding and removing simultaneously)" do
          let!(:journal_changing_options) do
            journal_with_multi_cf_snapshot

            work_package.reload.custom_field_values = { multi_select_cf.id => [option2.id, option3.id] }
            work_package.save!
            work_package.journals.order(:version).last
          end

          it "detects both additions and removals as changes" do
            _pagy, records = paginator.call

            expect(records.map(&:id)).to include(journal_changing_options.id)

            changes = journal_changing_options.reload.get_changes
            expect(changes).to have_key("custom_fields_#{multi_select_cf.id}")

            change = changes["custom_fields_#{multi_select_cf.id}"]
            new_value, old_value = change
            expect(new_value).not_to eq(old_value)
          end
        end
      end

      context "with file link changes" do
        let(:storage) { create(:nextcloud_storage) }

        let!(:journal_with_file_link_added) do
          create(:project_storage, project:, storage:)
          create(:file_link, container: work_package, storage:)
          work_package.add_journal(notes: "Here be file links")
          work_package.save!
          work_package.journals.order(:version).last
        end

        let!(:journal_with_file_link_snapshot) do
          work_package.add_journal(notes: "Unrelated change")
          work_package.save!
          work_package.journals.order(:version).last
        end

        it "includes journal where file link was added" do
          _pagy, records = paginator.call
          expect(records.map(&:id)).to include(journal_with_file_link_added.id)

          file_link = journal_with_file_link_added.reload.storable_journals.first&.file_link
          changes = journal_with_file_link_added.reload.get_changes
          expect(changes).to have_key("file_links_#{file_link.id}")
        end

        it "excludes journal with only file link snapshot" do
          _pagy, records = paginator.call

          expect(journal_with_file_link_snapshot.reload.storable_journals.count).to eq(1)
          changes = journal_with_file_link_snapshot.reload.get_changes
          expect(changes).to eq({}) # no changes

          expect(records.map(&:id)).not_to include(journal_with_file_link_snapshot.id)
        end
      end
    end

    context "with an unrecognised filter value" do
      let(:initial_journal) { work_package.journals.find_by(version: 1) }
      let!(:journal_with_notes) do
        create(:work_package_journal, user:, notes: "A comment", journable: work_package, version: 2)
      end

      before do
        params[:filter] = "bogus"
      end

      it "normalises the filter to :all" do
        expect(paginator.filter).to eq(:all)
      end

      it "returns the unfiltered feed" do
        _pagy, records = paginator.call

        expect(records.map(&:id)).to include(initial_journal.id, journal_with_notes.id)
      end
    end

    context "with filter and deep linking" do
      let!(:journal_with_notes) do
        create(:work_package_journal,
               user:,
               notes: "Comment 1",
               journable: work_package,
               version: 2)
      end
      let!(:journal_without_notes) do
        create(:work_package_journal,
               user:,
               notes: "",
               journable: work_package,
               version: 3)
      end

      before do
        params[:filter] = :only_comments
      end

      context "when anchoring to a journal that matches the filter" do
        it "returns the page containing the target journal" do
          params[:anchor] = "comment-#{journal_with_notes.id}"
          _pagy, records = paginator.call

          expect(records.map(&:id)).to include(journal_with_notes.id)
        end
      end

      context "when anchoring to a journal that doesn't match the filter" do
        it "ignores the filter without mutating the filter reader" do
          params[:anchor] = "comment-#{journal_without_notes.id}"
          _pagy, records = paginator.call

          expect(records.map(&:id)).to include(journal_without_notes.id, journal_with_notes.id)
          expect(paginator.filter).to eq(:only_comments)
        end
      end
    end

    context "with all journals filtered out" do
      let(:work_package) { create(:work_package, project:, author: user) }

      before do
        # Create only journals without notes
        3.times do |i|
          create(:work_package_journal,
                 user:,
                 notes: "",
                 journable: work_package,
                 version: i + 2)
        end
        params[:filter] = :only_comments
      end

      it "returns empty results" do
        pagy, records = paginator.call

        expect(pagy.count).to eq(0)
        expect(records).to be_empty
      end
    end
  end
end
