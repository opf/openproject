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

RSpec.describe WorkPackages::ActivitiesTab::UpdateStreams do
  # Records every emission instead of rendering it, so we can assert the
  # decisions (which journal becomes which mutation) without a controller.
  let(:sink) do
    Class.new do
      attr_reader :updated, :inserted, :removed, :replaced

      def initialize
        @updated = []
        @inserted = []
        @removed = []
        @replaced = []
      end

      def update_via_turbo_stream(component:) = @updated << component
      def remove_via_turbo_stream(component:) = @removed << component
      def replace_via_turbo_stream(component:) = @replaced << component

      def insert_via_turbo_stream(component:, target_component:, action:)
        @inserted << { component:, target_component:, action: }
      end
    end.new
  end

  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:since) { 1.hour.ago }
  let(:filter) { WorkPackages::ActivitiesTab::Filters::ALL }
  let(:editing_journal_ids) { [] }
  let(:sorting) { ActiveSupport::StringInquirer.new("desc") }

  def add_comment(notes:, created_at:, updated_at:)
    create(:work_package_journal,
           journable: work_package, user:, notes:,
           version: work_package.journals.last.version + 1)
      .tap { |journal| journal.update_columns(created_at:, updated_at:) }
  end

  # Age out the work package's initial creation journal so only the comments
  # crafted per-example drive the assertions.
  before do
    allow(User).to receive(:current).and_return(user)
    work_package.journals.update_all(created_at: 3.hours.ago, updated_at: 3.hours.ago)
  end

  subject(:emit) do
    described_class.new(work_package:, filter:, since:, editing_journal_ids:, sorting:).emit_into(sink)
  end

  def updated_item_journal_ids
    sink.updated
        .select { it.instance_of?(WorkPackages::ActivitiesTab::Journals::ItemComponent) }
        .map { it.instance_variable_get(:@journal).id }
  end

  context "with a comment edited after the client's last poll" do
    let!(:changed) { add_comment(notes: "edited", created_at: 2.hours.ago, updated_at: 10.minutes.ago) }

    it "re-renders it as a show component" do
      emit
      expect(updated_item_journal_ids).to include(changed.id)
    end

    context "when that comment is being edited by the client" do
      let(:editing_journal_ids) { [changed.id] }

      it "does not re-render it, to avoid clobbering the open editor" do
        emit
        expect(updated_item_journal_ids).not_to include(changed.id)
      end
    end
  end

  context "with a comment created after the client's last poll" do
    let!(:fresh) { add_comment(notes: "brand new", created_at: 5.minutes.ago, updated_at: 5.minutes.ago) }

    it "inserts it into the list" do
      emit
      expect(sink.inserted.map { it[:component].instance_variable_get(:@journal).id }).to include(fresh.id)
    end

    context "when sorting ascending" do
      let(:sorting) { ActiveSupport::StringInquirer.new("asc") }

      it "appends" do
        emit
        expect(sink.inserted.pluck(:action)).to all(eq(:append))
      end
    end

    context "when sorting descending" do
      let(:sorting) { ActiveSupport::StringInquirer.new("desc") }

      it "prepends" do
        emit
        expect(sink.inserted.pluck(:action)).to all(eq(:prepend))
      end
    end
  end

  context "with comments present" do
    let!(:comment) { add_comment(notes: "any", created_at: 5.minutes.ago, updated_at: 5.minutes.ago) }

    it "removes a potential empty state and refreshes the activity counter once each" do
      emit
      expect(sink.removed.size).to eq(1)
      expect(sink.replaced.size).to eq(1)
    end

    it "streams reactions only for journals whose reactions changed since the last poll" do
      comment.update_columns(reactions_changed_at: 1.minute.ago)

      emit

      reacted_journal_ids = sink.updated
        .select { it.instance_of?(WorkPackages::ActivitiesTab::Journals::ItemComponent::Reactions) }
        .map { it.instance_variable_get(:@journal).id }
      expect(reacted_journal_ids).to contain_exactly(comment.id)
    end
  end

  context "with the only_comments filter" do
    let(:filter) { WorkPackages::ActivitiesTab::Filters::ONLY_COMMENTS }

    it "ignores non-comment changes that the filtered list would not show" do
      # a change journal carries no notes; under ONLY_COMMENTS it is out of scope
      work_package.add_journal(user:)
      work_package.subject = "changed subject"
      work_package.save!
      work_package.journals.last.update_columns(created_at: 10.minutes.ago, updated_at: 10.minutes.ago)

      emit

      expect(updated_item_journal_ids).not_to include(work_package.journals.last.id)
    end
  end
end
