# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Projects::Exports::Formatters::ProjectPhase do
  let(:project) { create(:project) }
  let(:definition) { create(:project_phase_definition) }
  let(:user) { create(:user) }

  before do
    login_as(user)
    mock_permissions_for(user) do |mock|
      mock.allow_in_project :view_project_phases, project:
    end
  end

  describe ".apply?" do
    it "returns true for a project_phase_<id> attribute regardless of export format" do
      attribute = :"project_phase_#{definition.id}"
      expect(described_class.apply?(attribute, :csv)).to be true
      expect(described_class.apply?(attribute, :xls)).to be true
      expect(described_class.apply?(attribute, :pdf)).to be true
    end

    it "returns false for other attributes" do
      expect(described_class.apply?(:other_attribute, :csv)).to be false
    end
  end

  describe "#format" do
    subject(:formatter_instance) { described_class.new(:"project_phase_#{definition.id}") }

    context "when the user lacks the view_project_phases permission" do
      before do
        mock_permissions_for(user, &:forbid_everything)
      end

      it "returns an empty string" do
        expect(formatter_instance.format(project)).to eq("")
      end
    end

    context "when the phase definition does not exist" do
      subject(:formatter_instance) { described_class.new(:"project_phase_#{unknown_definition_id}") }

      let(:unknown_definition_id) { 0 }

      before do
        create(:project_phase, project:, definition:)
      end

      it "returns an empty string" do
        expect(formatter_instance.format(project)).to eq("")
      end
    end

    context "when the project has no active phase for that definition" do
      it "returns an empty string" do
        expect(formatter_instance.format(project)).to eq("")
      end
    end

    context "when the project has an inactive phase for that definition" do
      before do
        create(:project_phase, project:, definition:, active: false)
      end

      it "returns an empty string" do
        expect(formatter_instance.format(project)).to eq("")
      end
    end

    context "when the project has an active phase with start and finish dates" do
      let!(:phase) do
        create(:project_phase, project:, definition:, start_date: Date.new(2026, 1, 5), finish_date: Date.new(2026, 1, 20))
      end

      it "returns the formatted date range" do
        expect(formatter_instance.format(project))
          .to eq("#{formatter_instance.format_date(phase.start_date)} - #{formatter_instance.format_date(phase.finish_date)}")
      end
    end

    context "when the project has an active phase without start or finish dates" do
      let!(:phase) do
        create(:project_phase, :skip_validate, project:, definition:, start_date: nil, finish_date: nil, duration: nil)
      end

      it "returns the placeholder labels" do
        expect(formatter_instance.format(project))
          .to eq("#{I18n.t('js.label_no_start_date')} - #{I18n.t('js.label_no_due_date')}")
      end
    end
  end
end
