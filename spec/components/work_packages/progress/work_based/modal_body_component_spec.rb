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
require_relative "../shared_modal_examples"

RSpec.describe WorkPackages::Progress::WorkBased::ModalBodyComponent,
               type: :component do
  include OpenProject::StaticRouting::UrlHelpers

  include_examples "progress modal validations"
  include_examples "progress modal submit path"

  describe "#mode" do
    subject(:component) { described_class.new(WorkPackage.new) }

    it "returns :work_based" do
      expect(component.mode).to eq(:work_based)
    end
  end

  describe "#focused_field" do
    subject(:component) { described_class.new(work_package, focused_field:) }

    let(:work_package) { build(:work_package) }

    context "when given estimatedTime" do
      let(:focused_field) { "estimatedTime" }

      it "returns :estimated_hours" do
        expect(component.focused_field).to eq(:estimated_hours)
      end
    end

    context "when given remainingTime" do
      let(:focused_field) { "remainingTime" }

      it "returns :remaining_hours" do
        expect(component.focused_field).to eq(:remaining_hours)
      end
    end

    context "when given percentageDone" do
      let(:focused_field) { "percentageDone" }

      it "returns :done_ratio" do
        expect(component.focused_field).to eq(:done_ratio)
      end
    end
  end
end
