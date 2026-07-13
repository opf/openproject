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

RSpec.describe ProjectIdentifiers::RevertInstanceToClassicIdsJob do
  describe "#perform" do
    context "when the setting is not classic" do
      before { allow(Setting::WorkPackageIdentifier).to receive(:classic?).and_return(false) }

      it "raises an error" do
        expect { described_class.new.perform }
          .to raise_error(RuntimeError, /expected Setting.work_packages_identifier to be classic/)
      end
    end

    context "when the setting is classic" do
      before { allow(Setting::WorkPackageIdentifier).to receive(:classic?).and_return(true) }

      context "when projects have non-classic identifiers" do
        let!(:projects) do
          create_list(:project, 2).each.with_index(1) do |p, i|
            p.update_columns(identifier: "PROJ#{i}")
          end
        end

        it "calls RevertProjectToClassicService for each project" do
          services = projects.map do |project|
            instance_double(ProjectIdentifiers::RevertProjectToClassicService, call: nil).tap do |service|
              allow(ProjectIdentifiers::RevertProjectToClassicService).to receive(:new).with(project).and_return(service)
            end
          end

          described_class.new.perform

          expect(services).to all(have_received(:call))
        end
      end

      context "when a project already has a classic identifier" do
        let!(:project) { create(:project) }

        it "skips it and does not call RevertProjectToClassicService" do
          allow(ProjectIdentifiers::RevertProjectToClassicService).to receive(:new)
          described_class.new.perform
          expect(ProjectIdentifiers::RevertProjectToClassicService).not_to have_received(:new)
        end
      end

      context "when there are no projects" do
        it "does not call RevertProjectToClassicService" do
          allow(ProjectIdentifiers::RevertProjectToClassicService).to receive(:new)
          described_class.new.perform
          expect(ProjectIdentifiers::RevertProjectToClassicService).not_to have_received(:new)
        end
      end

      context "when run end-to-end against real projects" do
        let!(:project_with_classic_history) do
          create(:project).tap do |p|
            p.update_columns(identifier: "PROJ1")
            FriendlyId::Slug.create!(sluggable: p, slug: "my-project")
          end
        end

        let!(:project_without_classic_history) do
          create(:project).tap do |p|
            p.update_columns(identifier: "APP2")
            FriendlyId::Slug.where(sluggable: p).delete_all
            FriendlyId::Slug.create!(sluggable: p, slug: "APP2")
          end
        end

        before do
          allow(Setting::WorkPackageIdentifier).to receive_messages(classic?: true, semantic?: false)
          described_class.new.perform
        end

        it "restores the most recent classic slug from history" do
          expect(project_with_classic_history.reload.identifier).to eq("my-project")
        end

        it "generates a valid classic identifier when no classic history exists" do
          expect(project_without_classic_history.reload.identifier)
            .to match(Projects::Identifier::CLASSIC_FORMAT)
        end
      end

      context "when one project has a conflicting restored identifier" do
        # project_before and project_after bracket the conflict project to confirm
        # the find_each loop is not aborted — both must be processed.
        let!(:project_before) do
          create(:project).tap do |p|
            p.update_columns(identifier: "BEFORE1")
            FriendlyId::Slug.create!(sluggable: p, slug: "project-before")
          end
        end

        # Holds "conflict-slug" as its current identifier, blocking project_conflict
        # from reclaiming it.
        let!(:blocking_project) { create(:project, identifier: "conflict-slug") }

        let!(:project_conflict) do
          create(:project).tap do |p|
            p.update_columns(identifier: "CONFLICT1")
            FriendlyId::Slug.where(sluggable_id: p.id, sluggable_type: "Project").delete_all
            FriendlyId::Slug.where(slug: "conflict-slug", sluggable_type: "Project").update_all(sluggable_id: p.id)
          end
        end

        let!(:project_after) do
          create(:project).tap do |p|
            p.update_columns(identifier: "AFTER1")
            FriendlyId::Slug.create!(sluggable: p, slug: "project-after")
          end
        end

        before do
          allow(Setting::WorkPackageIdentifier).to receive_messages(classic?: true, semantic?: false)
          described_class.new.perform
        end

        it "still reverts project_before (loop not aborted before the conflict)" do
          expect(project_before.reload.identifier).to eq("project-before")
        end

        it "still reverts project_after (loop not aborted after the conflict)" do
          expect(project_after.reload.identifier).to eq("project-after")
        end

        it "assigns project_conflict a project-NNNNN fallback identifier" do
          expect(project_conflict.reload.identifier).to match(/\Aproject-[a-z0-9]{5}\z/)
        end
      end
    end
  end
end
