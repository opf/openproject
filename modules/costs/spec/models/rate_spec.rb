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

require File.dirname(__FILE__) + "/../spec_helper"

RSpec.describe Rate do
  let(:rate) { build(:rate) }

  describe "#valid?" do
    describe "WHEN no rate is supplied" do
      before do
        rate.rate = nil
      end

      it "is not valid" do
        expect(rate).not_to be_valid
        expect(rate.errors[:rate]).to eq([I18n.t("activerecord.errors.messages.not_a_number")])
      end
    end

    describe "WHEN no number is supplied" do
      before do
        rate.rate = "test"
      end

      it "is not valid" do
        expect(rate).not_to be_valid
        expect(rate.errors[:rate]).to eq([I18n.t("activerecord.errors.messages.not_a_number")])
      end
    end

    describe "WHEN a rate is supplied" do
      before do
        rate.rate = 5.0
      end

      it { expect(rate).to be_valid }
    end

    describe "WHEN a date is supplied" do
      before do
        rate.valid_from = Date.today
      end

      it { expect(rate).to be_valid }
    end

    describe "WHEN a transformable string is supplied for date" do
      before do
        rate.valid_from = "2012-03-04"
      end

      it { expect(rate).to be_valid }
    end

    describe "WHEN a nontransformable string is supplied for date" do
      before do
        rate.valid_from = "2012-02-30"
      end

      it "is not valid" do
        expect(rate).not_to be_valid
        expect(rate.errors[:valid_from]).to eq([I18n.t("activerecord.errors.messages.not_a_date")])
      end
    end

    describe "WHEN no value is supplied for date" do
      before do
        rate.valid_from = nil
      end

      it "is not valid" do
        expect(rate).not_to be_valid
        expect(rate.errors[:valid_from]).to eq([I18n.t("activerecord.errors.messages.not_a_date")])
      end
    end
  end
end
