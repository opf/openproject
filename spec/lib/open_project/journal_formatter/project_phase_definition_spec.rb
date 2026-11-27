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

RSpec.describe OpenProject::JournalFormatter::ProjectPhaseDefinition do
  describe "#render" do
    let(:project_phase) { build_stubbed(:project_phase) }
    let(:other_project_phase) { build_stubbed(:project_phase) }
    let(:project_phases) { [project_phase, other_project_phase].compact }
    let(:project) { build_stubbed(:project, phases: project_phases) }
    let(:work_package) { build_stubbed(:work_package, project:) }
    let(:journal) { build_stubbed(:work_package_journal, journable: work_package) }
    let(:instance) { described_class.new(journal) }

    before do
      allow(Project::PhaseDefinition)
        .to receive(:find_by)
              .and_return(nil)

      project_phases.each do |phase|
        allow(Project::PhaseDefinition)
          .to receive(:find_by)
          .with(id: phase.definition_id)
          .and_return(phase.definition)
      end
    end

    shared_examples_for "renders project phase definition change" do
      it { expect(instance.render(:project_phase_definition, [old_value, new_value])).to eq(expected) }
    end

    context "when setting an active phase" do
      let(:old_value) { nil }
      let(:new_value) { project_phase.definition_id.to_s }
      let(:expected) do
        I18n.t(:text_journal_set_to,
               label: "<strong>Project phase</strong>",
               value: "<i>#{project_phase.name}</i>")
      end

      it_behaves_like "renders project phase definition change"
    end

    context "when changing between two active phases" do
      let(:old_value) { other_project_phase.definition_id.to_s }
      let(:new_value) { project_phase.definition_id.to_s }
      let(:expected) do
        I18n.t(:text_journal_changed_plain,
               label: "<strong>Project phase</strong>",
               linebreak: nil,
               old: "<i>#{other_project_phase.name}</i>",
               new: "<i>#{project_phase.name}</i>")
      end

      it_behaves_like "renders project phase definition change"
    end

    context "when deleting an active phase" do
      let(:old_value) { project_phase.definition_id.to_s }
      let(:new_value) { nil }
      let(:expected) do
        I18n.t(:text_journal_deleted,
               label: "<strong>Project phase</strong>",
               old: "<strike><i>#{project_phase.name}</i></strike>")
      end

      it_behaves_like "renders project phase definition change"
    end

    context "when setting an inactive phase" do
      let(:project_phase) { build_stubbed(:project_phase, active: false) }
      let(:old_value) { nil }
      let(:new_value) { project_phase.definition_id.to_s }
      let(:expected) do
        I18n.t(:text_journal_set_to,
               label: "<strong>Project phase</strong>",
               value: "<i>#{project_phase.name} (Inactive)</i>")
      end

      it_behaves_like "renders project phase definition change"
    end

    context "when changing between two inactive phases" do
      let(:project_phase) { build_stubbed(:project_phase, active: false) }
      let(:other_project_phase) { build_stubbed(:project_phase, active: false) }
      let(:old_value) { other_project_phase.definition_id.to_s }
      let(:new_value) { project_phase.definition_id.to_s }
      let(:expected) do
        I18n.t(:text_journal_changed_plain,
               label: "<strong>Project phase</strong>",
               linebreak: nil,
               old: "<i>#{other_project_phase.name} (Inactive)</i>",
               new: "<i>#{project_phase.name} (Inactive)</i>")
      end

      it_behaves_like "renders project phase definition change"
    end

    context "when deleting an inactive phase" do
      let(:project_phase) { build_stubbed(:project_phase, active: false) }
      let(:old_value) { project_phase.definition_id.to_s }
      let(:new_value) { nil }
      let(:expected) do
        I18n.t(:text_journal_deleted,
               label: "<strong>Project phase</strong>",
               old: "<strike><i>#{project_phase.name} (Inactive)</i></strike>")
      end

      it_behaves_like "renders project phase definition change"
    end

    context "when setting a phase not configured for the project" do
      let(:project) { build_stubbed(:project, phases: []) }
      let(:old_value) { nil }
      let(:new_value) { project_phase.definition_id.to_s }
      let(:expected) do
        I18n.t(:text_journal_set_to,
               label: "<strong>Project phase</strong>",
               value: "<i>#{project_phase.name} (Inactive)</i>")
      end

      it_behaves_like "renders project phase definition change"
    end

    context "when changing between two phases not configured for the project" do
      let(:project) { build_stubbed(:project, phases: []) }
      let(:old_value) { other_project_phase.definition_id.to_s }
      let(:new_value) { project_phase.definition_id.to_s }
      let(:expected) do
        I18n.t(:text_journal_changed_plain,
               label: "<strong>Project phase</strong>",
               linebreak: nil,
               old: "<i>#{other_project_phase.name} (Inactive)</i>",
               new: "<i>#{project_phase.name} (Inactive)</i>")
      end

      it_behaves_like "renders project phase definition change"
    end

    context "when deleting a phase not configured for the project" do
      let(:project) { build_stubbed(:project, phases: []) }
      let(:old_value) { project_phase.definition_id.to_s }
      let(:new_value) { nil }
      let(:expected) do
        I18n.t(:text_journal_deleted,
               label: "<strong>Project phase</strong>",
               old: "<strike><i>#{project_phase.name} (Inactive)</i></strike>")
      end

      it_behaves_like "renders project phase definition change"
    end

    context "when setting a phase whose definition is deleted" do
      let(:old_value) { nil }
      let(:new_value) { "-1" }
      let(:expected) do
        I18n.t(:text_journal_set_to,
               label: "<strong>Project phase</strong>",
               value: "<i>#{I18n.t(:"activity.project_phase.deleted_project_phase")}</i>")
      end

      it_behaves_like "renders project phase definition change"
    end

    context "when changing between two phases whose definition is deleted" do
      let(:old_value) { "-1" }
      let(:new_value) { "-2" }
      let(:expected) do
        I18n.t(:text_journal_changed_plain,
               label: "<strong>Project phase</strong>",
               linebreak: nil,
               old: "<i>#{I18n.t(:"activity.project_phase.deleted_project_phase")}</i>",
               new: "<i>#{I18n.t(:"activity.project_phase.deleted_project_phase")}</i>")
      end

      it_behaves_like "renders project phase definition change"
    end

    context "when deleting a phase whose definition is deleted" do
      let(:old_value) { "-1" }
      let(:new_value) { nil }
      let(:expected) do
        I18n.t(:text_journal_deleted,
               label: "<strong>Project phase</strong>",
               old: "<strike><i>#{I18n.t(:"activity.project_phase.deleted_project_phase")}</i></strike>")
      end

      it_behaves_like "renders project phase definition change"
    end

    context "when changing between an active and an inactive phase" do
      let(:project_phase) { build_stubbed(:project_phase, active: true) }
      let(:other_project_phase) { build_stubbed(:project_phase, active: false) }
      let(:old_value) { other_project_phase.definition_id.to_s }
      let(:new_value) { project_phase.definition_id.to_s }
      let(:expected) do
        I18n.t(:text_journal_changed_plain,
               label: "<strong>Project phase</strong>",
               linebreak: nil,
               old: "<i>#{other_project_phase.name} (Inactive)</i>",
               new: "<i>#{project_phase.name}</i>")
      end

      it_behaves_like "renders project phase definition change"
    end

    context "when changing between an active and a phase not configured in the project" do
      let(:project) { build_stubbed(:project, phases: [other_project_phase]) }
      let(:old_value) { other_project_phase.definition_id.to_s }
      let(:new_value) { project_phase.definition_id.to_s }
      let(:expected) do
        I18n.t(:text_journal_changed_plain,
               label: "<strong>Project phase</strong>",
               linebreak: nil,
               old: "<i>#{other_project_phase.name}</i>",
               new: "<i>#{project_phase.name} (Inactive)</i>")
      end

      it_behaves_like "renders project phase definition change"
    end

    context "when changing between an active and a deleted phase" do
      let(:old_value) { other_project_phase.definition_id.to_s }
      let(:new_value) { "-1" }
      let(:expected) do
        I18n.t(:text_journal_changed_plain,
               label: "<strong>Project phase</strong>",
               linebreak: nil,
               old: "<i>#{other_project_phase.name}</i>",
               new: "<i>#{I18n.t(:"activity.project_phase.deleted_project_phase")}</i>")
      end

      it_behaves_like "renders project phase definition change"
    end
  end
end
