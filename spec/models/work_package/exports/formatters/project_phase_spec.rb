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

RSpec.describe WorkPackage::Exports::Formatters::ProjectPhase do
  let(:formatter_instance) { described_class.new(:project_phase) }

  describe ".apply?" do
    it "returns true for :project_phase and pdf format" do
      expect(described_class.apply?(:project_phase, :pdf)).to be true
    end

    it "returns false for other attributes" do
      expect(described_class.apply?(:other_attribute, :pdf)).to be false
    end

    it "returns true for :project_phase and csv format" do
      expect(described_class.apply?(:project_phase, :csv)).to be true
    end

    it "returns true for :project_phase and xls format" do
      expect(described_class.apply?(:project_phase, :xls)).to be true
    end
  end

  describe "#format" do
    let(:work_package) do
      build_stubbed(:work_package) do |wp|
        allow(wp)
          .to receive(:project_phase)
                .and_return(project_phase)
      end
    end

    context "when the phase is active" do
      let(:project_phase) { build_stubbed(:project_phase, active: true) }

      it "returns the name of the phase" do
        expect(formatter_instance.format(work_package)).to eq(project_phase.name)
      end
    end

    context "when the phase is inactive" do
      let(:project_phase) { build_stubbed(:project_phase, active: false) }

      it "returns nil" do
        expect(formatter_instance.format(work_package)).to be_nil
      end
    end

    context "when no phase is set" do
      let(:project_phase) { nil }

      it "returns nil" do
        expect(formatter_instance.format(work_package)).to be_nil
      end
    end
  end

  describe "#format_value" do
    it "is not implemented" do
      expect { formatter_instance.format_value("abc", {}) }
        .to raise_error(NotImplementedError)
    end
  end
end
