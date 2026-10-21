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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe Llm::WorkPackages::RefreshEmbedding, with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:status) { create(:status) }
  shared_let(:assignee) { create(:user) }

  let(:work_package) { create(:work_package, subject: "Fix login bug", description: "Users cannot log in.") }
  let(:available) { true }

  before do
    allow(Llm::WorkPackages::SemanticSearch).to receive(:available?).and_return(available)
  end

  def journal_after(**changes)
    work_package.update!(changes)
    work_package.journals.reload.last
  end

  describe ".call" do
    it "enqueues an embedding for a newly created work package" do
      described_class.call(work_package.journals.last)

      expect(Llm::EmbedWorkPackagesJob).to have_been_enqueued.once.with([work_package.id])
    end

    it "enqueues an embedding when the subject changed" do
      described_class.call(journal_after(subject: "Fix logout bug"))

      expect(Llm::EmbedWorkPackagesJob).to have_been_enqueued.once.with([work_package.id])
    end

    it "enqueues an embedding when the description changed" do
      described_class.call(journal_after(description: "Users cannot log out."))

      expect(Llm::EmbedWorkPackagesJob).to have_been_enqueued.once.with([work_package.id])
    end

    it "enqueues a single embedding when the subject changed together with other attributes" do
      described_class.call(journal_after(subject: "Fix logout bug", description: "Users cannot log out.", status:))

      expect(Llm::EmbedWorkPackagesJob).to have_been_enqueued.once.with([work_package.id])
    end

    it "does not enqueue an embedding when only other attributes changed" do
      described_class.call(journal_after(status:, assigned_to: assignee, due_date: Date.tomorrow))

      expect(Llm::EmbedWorkPackagesJob).not_to have_been_enqueued
    end

    context "when semantic search is not available" do
      let(:available) { false }

      it "does not enqueue an embedding" do
        described_class.call(journal_after(subject: "Fix logout bug"))

        expect(Llm::EmbedWorkPackagesJob).not_to have_been_enqueued
      end
    end
  end

  describe "subscription to the aggregated journal event" do
    it "enqueues an embedding for the journal's work package" do
      OpenProject::Notifications.send(OpenProject::Events::AGGREGATED_WORK_PACKAGE_JOURNAL_READY,
                                      journal: journal_after(subject: "Fix logout bug"),
                                      send_mail: false)

      expect(Llm::EmbedWorkPackagesJob).to have_been_enqueued.once.with([work_package.id])
    end
  end
end
