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

RSpec.describe ProjectIdentifiers::RevertProjectToClassicService do
  describe "#call" do
    context "when the project has a classic identifier in FriendlyId history" do
      let!(:project) do
        create(:project).tap do |p|
          p.update_columns(identifier: "MYAPP", wp_sequence_counter: 0)
          FriendlyId::Slug.create!(sluggable: p, slug: "my-app")
        end
      end

      before { described_class.new(project).call }

      it "restores the classic identifier" do
        expect(project.reload.identifier).to eq("my-app")
      end

      it "does not enqueue Notifications::WorkflowJob for the identifier change" do
        project2 = create(:project).tap do |p|
          p.update_columns(identifier: "OTHER", wp_sequence_counter: 0)
          FriendlyId::Slug.create!(sluggable: p, slug: "other-name")
        end
        expect { described_class.new(project2).call }
          .not_to have_enqueued_job(Notifications::WorkflowJob)
      end
    end

    context "when the project has multiple slugs in FriendlyId history" do
      let!(:project) do
        create(:project).tap do |p|
          p.update_columns(identifier: "MYAPP", wp_sequence_counter: 0)
          FriendlyId::Slug.create!(sluggable: p, slug: "old-name", created_at: 2.hours.ago)
          FriendlyId::Slug.create!(sluggable: p, slug: "newer-name", created_at: 1.hour.ago)
        end
      end

      before { described_class.new(project).call }

      it "restores the most recent classic slug" do
        expect(project.reload.identifier).to eq("newer-name")
      end
    end

    context "when the project has only semantic identifiers in FriendlyId history" do
      let!(:project) do
        create(:project).tap do |p|
          p.update_columns(identifier: "MYAPP", wp_sequence_counter: 3)
          FriendlyId::Slug.where(sluggable: p).delete_all
          FriendlyId::Slug.create!(sluggable: p, slug: "MYAPP")
        end
      end

      before do
        allow(Setting::WorkPackageIdentifier).to receive_messages(classic?: true, semantic?: false)
        described_class.new(project).call
      end

      it "generates a classic identifier from the project name" do
        expect(project.reload.identifier).to eq(project.name.to_url.first(Projects::Identifier::CLASSIC_IDENTIFIER_MAX_LENGTH))
      end
    end

    context "when the project name produces no URL-safe slug" do
      let!(:project) do
        create(:project).tap do |p|
          p.update_columns(name: "!!!", identifier: "MYAPP", wp_sequence_counter: 0)
          FriendlyId::Slug.where(sluggable: p).delete_all
          FriendlyId::Slug.create!(sluggable: p, slug: "MYAPP")
        end
      end

      before do
        allow(Setting::WorkPackageIdentifier).to receive_messages(classic?: true, semantic?: false)
        described_class.new(project).call
      end

      it "assigns a project-NNNNN fallback identifier" do
        expect(project.reload.identifier).to match(/\Aproject-[a-z0-9]{5}\z/)
      end
    end

    context "when saving the restored identifier raises a DB-level uniqueness error" do
      let!(:project) do
        create(:project).tap do |p|
          p.update_columns(identifier: "MYAPP", wp_sequence_counter: 0)
          FriendlyId::Slug.where(sluggable: p).delete_all
          FriendlyId::Slug.create!(sluggable: p, slug: "my-app")
        end
      end

      before do
        raised = false
        allow(project).to receive(:update!).and_wrap_original do |original, *args, **kwargs|
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

      it "assigns a project-NNNNN fallback identifier" do
        described_class.new(project).call
        expect(project.reload.identifier).to match(/\Aproject-[a-z0-9]{5}\z/)
      end

      it "logs a warning containing the project id and the conflicting identifier" do
        allow(Rails.logger).to receive(:warn)
        described_class.new(project).call
        expect(Rails.logger).to have_received(:warn)
          .with(a_string_including(project.id.to_s, "my-app"))
      end
    end

    context "when the classic slug from FriendlyId history is already taken by another project" do
      let!(:blocking_project) { create(:project, identifier: "my-app") }

      let!(:project) do
        create(:project).tap do |p|
          p.update_columns(identifier: "MYAPP", wp_sequence_counter: 0)
          # Remove p's own initial slug so "my-app" is the only entry in its slug history.
          # Without this, the factory slug (newer created_at) would be returned first by
          # restore_identifier, the update would succeed, and the conflict path would never fire.
          FriendlyId::Slug.where(sluggable_id: p.id, sluggable_type: "Project").delete_all
          # blocking_project already owns the "my-app" FriendlyId slug; reassign it so that
          # restore_identifier returns "my-app" and project.update! conflicts with blocking_project.
          FriendlyId::Slug.where(slug: "my-app", sluggable_type: "Project").update_all(sluggable_id: p.id)
        end
      end

      it "does not raise" do
        expect { described_class.new(project).call }.not_to raise_error
      end

      it "assigns a project-NNNNN fallback identifier" do
        described_class.new(project).call
        expect(project.reload.identifier).to match(/\Aproject-[a-z0-9]{5}\z/)
      end

      it "logs a warning containing the project id and the conflicting identifier" do
        allow(Rails.logger).to receive(:warn)
        described_class.new(project).call
        expect(Rails.logger).to have_received(:warn)
          .with(a_string_including(project.id.to_s, "my-app"))
      end
    end
  end
end
