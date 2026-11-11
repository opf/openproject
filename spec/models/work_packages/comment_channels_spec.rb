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

RSpec.describe WorkPackages::CommentChannels do
  let(:work_package) { build_stubbed(:work_package) }
  let(:user) { build_stubbed(:user) }
  let(:journal) { build_stubbed(:work_package_journal) }
  let(:channel) do
    instance_double(WorkPackages::CommentChannel,
                    key: "letter",
                    available?: true,
                    delivered?: true,
                    journal_preloads: [:letter])
  end
  let(:other_channel) do
    instance_double(WorkPackages::CommentChannel,
                    key: "fax",
                    available?: false,
                    delivered?: false,
                    journal_preloads: [])
  end

  before do
    allow(described_class).to receive(:registry).and_return({})

    described_class.register(channel)
    described_class.register(other_channel)
  end

  describe ".find" do
    it "finds a channel by its key" do
      expect(described_class.find("letter")).to eq(channel)
      expect(described_class.find(:fax)).to eq(other_channel)
    end

    it "finds nothing for an unknown or missing key" do
      expect(described_class.find("pigeon")).to be_nil
      expect(described_class.find(nil)).to be_nil
    end
  end

  describe ".available_for" do
    it "returns the channels available for the work package and the user" do
      expect(described_class.available_for(work_package:, user:)).to eq([channel])
      expect(other_channel).to have_received(:available?).with(work_package:, user:)
    end
  end

  describe ".delivering" do
    it "returns the channel that delivered the journal" do
      expect(described_class.delivering(journal)).to eq(channel)
    end

    context "when no channel delivered the journal" do
      before { allow(channel).to receive(:delivered?).and_return(false) }

      it "returns nothing" do
        expect(described_class.delivering(journal)).to be_nil
      end
    end
  end

  describe ".journal_preloads" do
    it "collects the preloads of all channels" do
      expect(described_class.journal_preloads).to eq([:letter])
    end
  end
end
