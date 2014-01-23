#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe Rate do
  let(:rate) { FactoryGirl.build(:rate) }

  describe :valid? do
    describe "WHEN no rate is supplied" do
      before do
        rate.rate = nil
      end

      it "should not be valid" do
        rate.should_not be_valid
        rate.errors[:rate].should == [I18n.t('activerecord.errors.messages.not_a_number')]
      end
    end

    describe "WHEN no number is supplied" do
      before do
        rate.rate = "test"
      end

      it "should not be valid" do
        rate.should_not be_valid
        rate.errors[:rate].should == [I18n.t('activerecord.errors.messages.not_a_number')]
      end
    end

    describe "WHEN a rate is supplied" do
      before do
        rate.rate = 5.0
      end

      it { rate.should be_valid }
    end

    describe "WHEN a date is supplied" do
      before do
        rate.valid_from = Date.today
      end

      it { rate.should be_valid }
    end

    describe "WHEN a transformable string is supplied for date" do
      before do
        rate.valid_from = "2012-03-04"
      end

      it { rate.should be_valid }
    end

    describe "WHEN a nontransformable string is supplied for date" do
      before do
        rate.valid_from = "2012-02-30"
      end

      it "should not be valid" do
        rate.should_not be_valid
        rate.errors[:valid_from].should ==  [I18n.t('activerecord.errors.messages.not_a_date')]
      end
    end

    describe "WHEN no value is supplied for date" do
      before do
        rate.valid_from = nil
      end

      it "should not be valid" do
        rate.should_not be_valid
        rate.errors[:valid_from].should ==  [I18n.t('activerecord.errors.messages.not_a_date')]
      end
    end
  end
end
