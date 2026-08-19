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

RSpec.describe Queries::WorkPackages::Filter::TypeaheadFilter do
  let(:instance) do
    described_class.create!(name: :typeahead, context:)
  end

  let(:context)  { nil }
  let(:values)   { ["test"] }
  let(:operator) { "**" }

  before do
    instance.values = values
    instance.operator = operator
  end

  describe "#where clause" do
    subject { WorkPackage.joins(instance.joins + [:project]).where(instance.where) }

    shared_let(:open_status) { create(:status, name: "In Progress", is_closed: false) }
    shared_let(:closed_status) { create(:status, name: "Done", is_closed: true) }
    shared_let(:project)   { create(:project, name: "Phoenix") }
    shared_let(:epic_type) { create(:type, name: "Epic") }
    shared_let(:bug_type)  { create(:type, name: "Bug") }
    shared_let(:task_type) { create(:type, name: "Task") }
    shared_let(:epic_work_package) do
      create(:work_package,
             project:,
             type: epic_type,
             status: open_status,
             subject: "Gorilla work package ething")
    end
    shared_let(:bug_work_package) do
      create(:work_package,
             project:,
             type: bug_type,
             status: open_status,
             subject: "Gorilla work package bthing")
    end
    shared_let(:task_work_package) do
      create(:work_package,
             project:,
             type: task_type,
             status: open_status,
             subject: "Work package tthing")
    end

    context "when searching by work package type name" do
      let(:values) { ["epic"] }

      it "returns work packages with matching type name" do
        expect(subject).to include(epic_work_package)
        expect(subject).not_to include(bug_work_package, task_work_package)
      end
    end

    context "when searching by partial type name" do
      let(:values) { ["ep"] }

      it "returns work packages with type name containing the search term" do
        expect(subject).to include(epic_work_package)
        expect(subject).not_to include(bug_work_package, task_work_package)
      end
    end

    context "when searching by work package subject" do
      let(:values) { ["ething"] }

      it "returns work packages with matching subject" do
        expect(subject).to include(epic_work_package)
        expect(subject).not_to include(bug_work_package, task_work_package)
      end
    end

    context "when searching by project name" do
      let(:values) { ["phoenix"] }

      it "returns work packages from projects with matching name" do
        expect(subject).to include(epic_work_package, bug_work_package, task_work_package)
      end
    end

    context "when searching by work package ID" do
      let(:values) { [epic_work_package.id.to_s] }

      it "returns work packages with matching ID" do
        expect(subject).to include(epic_work_package)
        expect(subject).not_to include(bug_work_package, task_work_package)
      end
    end

    context "when searching for 'epic gorilla'" do
      let(:values) { ["epic gorilla"] }

      it "returns work packages matching both type name and subject" do
        expect(subject).to include(epic_work_package)
        expect(subject).not_to include(task_work_package, bug_work_package)
      end
    end

    context "when searching for 'gorilla epic' the order of the terms does not matter" do
      let(:values) { ["gorilla epic"] }

      it "returns work packages matching both subject and type name" do
        expect(subject).to include(epic_work_package)
        expect(subject).not_to include(bug_work_package, task_work_package)
      end
    end

    context "when searching for 'gorilla' only" do
      let(:values) { ["gorilla"] }

      it "returns all work packages with 'gorilla' in subject" do
        expect(subject).to include(epic_work_package, bug_work_package)
        expect(subject).not_to include(task_work_package)
      end
    end

    context "when searching for uppercase type name" do
      let(:values) { ["EPIC"] }

      it "returns work packages with matching type name regardless of case" do
        expect(subject).to include(epic_work_package)
        expect(subject).not_to include(bug_work_package, task_work_package)
      end
    end

    context "when searching for mixed case type name" do
      let(:values) { ["EpIc"] }

      it "returns work packages with matching type name regardless of case" do
        expect(subject).to include(epic_work_package)
        expect(subject).not_to include(bug_work_package, task_work_package)
      end
    end

    context "when searching for non-existent terms" do
      let(:values) { ["nonexistent"] }

      it "returns no work packages" do
        expect(subject).to be_empty
      end
    end

    describe "when the setting for work package identifiers is set to semantic",
             with_settings: { work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC } do
      before do
        previous_identifier = project.identifier
        project.update!(identifier: "PHX")
        project.handle_semantic_rename(previous_identifier)
      end

      let!(:identifier_work_package1) do
        create(:work_package,
               project:,
               subject: "First semantic work package")
      end

      let!(:identifier_work_package2) do
        create(:work_package,
               project:,
               subject: "Second semantic work package")
      end

      context "when searching by work package identifier" do
        let(:values) { [identifier_work_package1.identifier] }

        it "returns work packages with matching identifier" do
          expect(subject).to include(identifier_work_package1)
          expect(subject).not_to include(identifier_work_package2)
        end
      end

      context "when searching by lower case work package identifier" do
        let(:values) { [identifier_work_package1.identifier.downcase] }

        it "returns work packages with matching identifier" do
          expect(subject).to include(identifier_work_package1)
          expect(subject).not_to include(identifier_work_package2)
        end
      end

      context "when searching for partial identifier" do
        let(:values) { [project.identifier] }

        it "returns work packages with matching identifier" do
          expect(subject).to include(identifier_work_package1, identifier_work_package2)
        end
      end

      context "and the project identifier changed" do
        before do
          project.update!(identifier: "PHO")
          project.reload.handle_semantic_rename("PHX")
        end

        context "when searching for the previous identifier of the work package" do
          let(:values) { ["PHX-#{identifier_work_package1.sequence_number}"] }

          it "still finds the work package" do
            expect(identifier_work_package1.reload.identifier).to start_with("PHO")
            expect(subject).to include(identifier_work_package1)
            expect(subject).not_to include(identifier_work_package2)
          end
        end
      end
    end

    describe "when the setting for work package identifiers is set to classic but was semantic before",
             with_settings: { work_packages_identifier: Setting::WorkPackageIdentifier::CLASSIC } do
      let!(:identifier_work_package1) do
        create(:work_package,
               project:,
               subject: "First semantic work package")
      end

      let!(:identifier_work_package1_semantic_alias) do
        create(:work_package_semantic_alias,
               work_package: identifier_work_package1,
               identifier: "PHO-1")
      end

      let!(:identifier_work_package2) do
        create(:work_package,
               project:,
               subject: "Second semantic work package")
      end

      let!(:identifier_work_package2_semantic_alias) do
        create(:work_package_semantic_alias,
               work_package: identifier_work_package2,
               identifier: "PHO-2")
      end

      context "and there are still entries in the semantic alias registry" do
        let(:values) { [identifier_work_package1_semantic_alias.identifier] }

        it "still finds by existing identifiers" do
          expect(subject).to include(identifier_work_package1)
          expect(subject).not_to include(identifier_work_package2)
        end
      end
    end

    context "when searching by status" do
      shared_let(:open_work_package)   { create(:work_package, project:, status: open_status,   subject: "wide work package") }
      shared_let(:closed_work_package) { create(:work_package, project:, status: closed_status, subject: "narrow work package") }

      context "when searching for status name 'In Progress'" do
        let(:values) { ["In Progress"] }

        it "returns work packages with 'In Progress' status" do
          expect(subject).to include(open_work_package)
          expect(subject).not_to include(closed_work_package)
        end
      end

      context "when searching for status name 'In Progress' and part of subject 'wide'" do
        let(:values) { ["In Progress wide"] }

        it "returns work packages with 'In Progress' status containing the search term 'wide'" do
          expect(subject).to include(open_work_package)
          expect(subject).not_to include(closed_work_package)
        end
      end

      context "when searching for meta status 'open'" do
        let(:values) { ["open"] }

        it "returns work packages with open status" do
          expect(subject).to include(open_work_package)
          expect(subject).not_to include(closed_work_package)
        end
      end

      context "when searching for meta status 'closed'" do
        let(:values) { ["closed"] }

        it "returns work packages with closed status" do
          expect(subject).to include(closed_work_package)
          expect(subject).not_to include(open_work_package)
        end
      end

      context "when searching for meta status 'OPEN' (case insensitive)" do
        let(:values) { ["OPEN"] }

        it "returns work packages with open status regardless of case" do
          expect(subject).to include(open_work_package)
          expect(subject).not_to include(closed_work_package)
        end
      end

      context "when searching for meta status 'CLOSED' (case insensitive)" do
        let(:values) { ["CLOSED"] }

        it "returns work packages with closed status regardless of case" do
          expect(subject).to include(closed_work_package)
          expect(subject).not_to include(open_work_package)
        end
      end

      context "with different locale" do
        around do |example|
          I18n.with_locale(:de) do
            example.run
          end
        end

        context "when searching for German 'offen' (open)" do
          let(:values) { ["offen"] }

          it "returns work packages with open status using German translation" do
            # Assuming German translation exists
            allow(I18n).to receive(:t).with("label_open").and_return("offen")
            allow(I18n).to receive(:t).with("label_closed").and_return("geschlossen")

            expect(subject).to include(open_work_package)
            expect(subject).not_to include(closed_work_package)
          end
        end
      end
    end

    context "with empty search term" do
      let(:values) { [""] }

      it "returns some work packages" do
        expect(subject).to include(epic_work_package, bug_work_package, task_work_package)
      end
    end
  end
end
