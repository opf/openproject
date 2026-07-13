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

require "rails_helper"

RSpec.describe ProjectIdentifiers::ConvertProjectToSemanticService,
               with_settings: { work_packages_identifier: "classic" } do
  describe "#call" do
    context "when the project has a prior valid semantic identifier in FriendlyId history" do
      let!(:project) do
        create(:project).tap do |p|
          p.update_columns(identifier: "my-app", wp_sequence_counter: 0)
          FriendlyId::Slug.create!(sluggable: p, slug: "MYAPP")
        end
      end

      before { described_class.new(project).call }

      it "restores the prior semantic identifier instead of generating a new one" do
        expect(project.reload.identifier).to eq("MYAPP")
      end
    end

    context "when the prior semantic identifier is already taken by another project" do
      let!(:other)   { create(:project).tap { |p| p.update_columns(identifier: "MYAPP") } }
      let!(:project) do
        create(:project).tap do |p|
          p.update_columns(identifier: "my-app", wp_sequence_counter: 0)
          FriendlyId::Slug.create!(sluggable: p, slug: "MYAPP")
        end
      end

      before { described_class.new(project).call }

      it "falls back to a freshly generated semantic identifier" do
        identifier = project.reload.identifier
        expect(identifier).not_to eq("my-app")
        expect(identifier).not_to eq("MYAPP")
        expect(identifier).to match(/\A[A-Z][A-Z0-9_]{1,9}\z/)
      end
    end

    context "when saving the generated identifier fails due to a race condition" do
      let!(:project) do
        create(:project).tap { |p| p.update_columns(identifier: "my-app", wp_sequence_counter: 0) }
      end

      before do
        allow(project).to receive(:previous_semantic_identifier).and_return("MYAPP")
        raised = false
        allow(project).to receive(:save!).and_wrap_original do |original, *args, **kwargs|
          unless raised
            raised = true
            raise ActiveRecord::RecordNotUnique, "stubbed"
          end
          original.call(*args, **kwargs)
        end
      end

      it "does not raise" do
        expect { described_class.new(project).call }.not_to raise_error
      end

      it "assigns a random P-NNNNN fallback identifier" do
        described_class.new(project).call
        expect(project.reload.identifier).to match(/\AP[A-Z0-9]{5}\z/)
      end

      it "logs a warning containing the project id and the conflicting identifier" do
        allow(Rails.logger).to receive(:warn)
        described_class.new(project).call
        expect(Rails.logger).to have_received(:warn)
          .with(a_string_including(project.id.to_s, "MYAPP"))
      end
    end

    context "when the suggested identifier case-insensitively matches a historical classic identifier" do
      let!(:project_one) do
        create(:project, name: "Project 1", identifier: "project_one").tap do |p|
          FriendlyId::Slug.create!(sluggable: p, slug: "toi")
        end
      end
      let!(:project_two) { create(:project, name: "Test Old Identifier", identifier: "whatever") }

      it "avoids the clashing suggestion and assigns an alternative semantic identifier" do
        described_class.new(project_two).call
        # "TOI" (initials of "Test Old Identifier") is the first candidate but is
        # blocked by the FriendlyId slug history; the generator expands to "TEOI" next.
        expect(project_two.reload.identifier).to eq("TEOI")
      end
    end

    context "when the generated identifier is blank" do
      let!(:project) do
        create(:project).tap { |p| p.update_columns(identifier: "my-app") }
      end

      before do
        allow(ProjectIdentifiers::IdentifierAutofix::ProjectIdentifierSuggestionGenerator)
          .to receive(:suggest_identifier)
          .and_return(nil)
      end

      it "raises a RuntimeError" do
        expect { described_class.new(project).call }
          .to raise_error(RuntimeError, /Generated identifier is blank/)
      end
    end

    context "when the project has a problematic identifier" do
      let!(:project) { create(:project, name: "My Project") }
      let!(:wp)      { create(:work_package, project:) }

      before { described_class.new(project).call }

      it "renames the project to a valid semantic identifier" do
        expect(project.reload.identifier).to match(/\A[A-Z][A-Z0-9_]{1,9}\z/)
      end

      it "backfills WPs using the new identifier" do
        expect(wp.reload.identifier).to eq("#{project.reload.identifier}-1")
      end

      it "does not enqueue Notifications::WorkflowJob for the identifier change" do
        project2 = create(:project, name: "Another Project")
        expect { described_class.new(project2).call }
          .not_to have_enqueued_job(Notifications::WorkflowJob)
      end
    end

    context "when the only natural suggestion is a system-reserved keyword" do
      let!(:project) do
        # "New" produces "NEW" as the sole initial candidate, but "NEW" is in
        # RESERVED_IDENTIFIERS; the generator falls back to the numeric suffix "NEW2".
        create(:project, name: "New Project").tap { |p| p.update_columns(name: "New", identifier: "new") }
      end

      before { described_class.new(project).call }

      it "steers to a non-reserved alternative" do
        expect(project.reload.identifier).to eq("NEW2")
      end
    end

    context "when the project already has a valid identifier" do
      let!(:project) do
        create(:project).tap { |p| p.update_columns(identifier: "MYAPP", wp_sequence_counter: 0) }
      end
      let!(:wp) { create(:work_package, project:) }

      before { described_class.new(project).call }

      it "leaves the identifier unchanged" do
        expect(project.reload.identifier).to eq("MYAPP")
      end
    end

    context "when a project has work packages without sequence numbers" do
      let!(:project) do
        create(:project).tap { |p| p.update_columns(identifier: "MYAPP", wp_sequence_counter: 0) }
      end
      let!(:wp1) { create(:work_package, project:) }
      let!(:wp2) { create(:work_package, project:) }

      before { described_class.new(project).call }

      it "assigns sequence numbers in id (oldest-first) order" do
        expect(wp1.reload.sequence_number).to eq(1)
        expect(wp2.reload.sequence_number).to eq(2)
      end

      it "sets identifier on each WP using the project identifier" do
        expect(wp1.reload.identifier).to eq("MYAPP-1")
        expect(wp2.reload.identifier).to eq("MYAPP-2")
      end
    end

    context "when a WP was moved in from another project (identifier and seq are stale)" do
      let!(:project) do
        create(:project).tap { |p| p.update_columns(identifier: "DEST", wp_sequence_counter: 1) }
      end
      let!(:wp) { create(:work_package, project:).tap { |w| w.update_columns(sequence_number: 4, identifier: "SOURCE-1") } }

      before { described_class.new(project).call }

      it "rewrites the identifier to match the current project prefix" do
        expect(wp.reload.identifier).to eq("DEST-2")
      end
    end

    context "when a moved-in WP has a sequence_number higher than the project counter (counter underflow)" do
      let!(:project) do
        create(:project).tap { |p| p.update_columns(identifier: "DEST", wp_sequence_counter: 0) }
      end
      let!(:moved_wp) { create(:work_package, project:).tap { |w| w.update_columns(sequence_number: 5, identifier: "SOURCE-5") } }
      let!(:new_wp)   { create(:work_package, project:).tap { |w| w.update_columns(sequence_number: nil, identifier: nil) } }

      before { described_class.new(project).call }

      it "correctly assigns the new sequence numbers" do
        expect(moved_wp.reload.sequence_number).to eq(1)
        expect(new_wp.reload.sequence_number).to eq(2)
      end
    end

    context "when seeding the alias table" do
      let!(:project) do
        create(:project).tap { |p| p.update_columns(identifier: "CURR", wp_sequence_counter: 0) }
      end
      let!(:wp) { create(:work_package, project:) }

      before do
        FriendlyId::Slug.where(sluggable: project).delete_all
        FriendlyId::Slug.create!(sluggable: project, slug: "OLD")
        FriendlyId::Slug.create!(sluggable: project, slug: "CURR")
        described_class.new(project).call
      end

      it "inserts alias rows for all historical prefixes" do
        seq = wp.reload.sequence_number
        expect(WorkPackageSemanticAlias.where(work_package_id: wp.id).pluck(:identifier))
          .to contain_exactly("OLD-#{seq}", "CURR-#{seq}")
      end
    end
  end
end
