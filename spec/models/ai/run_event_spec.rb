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

RSpec.describe AI::RunEvent do
  subject(:event) { build(:ai_run_event) }

  it { is_expected.to validate_inclusion_of(:kind).in_array(described_class::KINDS) }
  it { is_expected.to validate_presence_of(:seq) }

  describe "seq" do
    let(:run) { create(:ai_run) }

    it "must be unique per run" do
      create(:ai_run_event, run:, seq: 1)
      duplicate = build(:ai_run_event, run:, seq: 1)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:seq]).to be_present
    end

    it "may repeat across runs" do
      create(:ai_run_event, run:, seq: 1)

      expect(build(:ai_run_event, seq: 1)).to be_valid
    end
  end

  describe "append-only behaviour" do
    subject(:event) { create(:ai_run_event) }

    it "refuses updates once persisted" do
      expect { event.update!(kind: "completed") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "refuses destruction once persisted" do
      expect { event.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end
end
