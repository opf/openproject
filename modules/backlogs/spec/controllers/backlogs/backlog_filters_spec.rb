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

RSpec.describe Backlogs::BacklogFilters, type: :model do
  subject(:filters) { described_class.from_params(params) }

  describe ".from_params / #bucket_ids" do
    context "when bucket_ids are absent" do
      let(:params) { {} }

      it { expect(filters.bucket_ids).to be_nil }
    end

    context "when bucket_ids are string integers" do
      let(:params) { { bucket_ids: %w[1 2 3] } }

      it "coerces them to integers" do
        expect(filters.bucket_ids).to eq([1, 2, 3])
      end
    end

    context "when bucket_ids contain blank strings" do
      let(:params) { { bucket_ids: ["1", "", "2"] } }

      it "filters out blanks" do
        expect(filters.bucket_ids).to eq([1, 2])
      end
    end
  end

  describe "#sprint_ids" do
    context "when sprint_ids are absent" do
      let(:params) { {} }

      it { expect(filters.sprint_ids).to be_nil }
    end

    context "when sprint_ids are string integers" do
      let(:params) { { sprint_ids: %w[5 6] } }

      it "coerces them to integers" do
        expect(filters.sprint_ids).to eq([5, 6])
      end
    end
  end

  describe "#show_all?" do
    context "when the all param is absent" do
      let(:params) { {} }

      it { expect(filters.show_all?).to be false }
    end

    context "when the all param is '1'" do
      let(:params) { { all: "1" } }

      it { expect(filters.show_all?).to be true }
    end

    context "when the all param is '0'" do
      let(:params) { { all: "0" } }

      it { expect(filters.show_all?).to be false }
    end

    context "when the all param is 'false'" do
      let(:params) { { all: "false" } }

      it { expect(filters.show_all?).to be false }
    end
  end

  describe "#to_h" do
    context "with no params" do
      let(:params) { {} }

      it "returns an empty hash" do
        expect(filters.to_h).to eq({})
      end
    end

    context "with show_all" do
      let(:params) { { all: "1" } }

      it "includes all: 1" do
        expect(filters.to_h).to eq({ all: true })
      end
    end

    context "with bucket_ids and sprint_ids" do
      let(:params) { { bucket_ids: %w[1 2], sprint_ids: %w[3] } }

      it "includes both" do
        expect(filters.to_h).to eq({ bucket_ids: [1, 2], sprint_ids: [3] })
      end
    end

    context "with all params combined" do
      let(:params) { { all: "1", bucket_ids: %w[1], sprint_ids: %w[2] } }

      it "includes everything" do
        expect(filters.to_h).to eq({ all: true, bucket_ids: [1], sprint_ids: [2] })
      end
    end
  end

  describe "#to_hash" do
    let(:params) { { bucket_ids: %w[1 2] } }

    it "is an alias for to_h, enabling ** spreading" do
      expect(filters.to_hash).to eq(filters.to_h)
    end
  end
end
