# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ISO8601::Months do
  let(:common_year) { ISO8601::DateTime.new('2010-01-01') }
  let(:leap_year) { ISO8601::DateTime.new('2000-01-01') }

  let(:common_february) { ISO8601::DateTime.new('2010-02-01') }
  let(:leap_february) { ISO8601::DateTime.new('2000-02-01') }

  let(:common_november) { ISO8601::DateTime.new('2017-11-01') }

  let(:common_december) { ISO8601::DateTime.new('2017-12-01') }
  let(:leap_december) { ISO8601::DateTime.new('2000-12-01') }

  describe 'Atomic' do
    let(:subject) { ISO8601::Months.new(1) }

    it "should respond to the Atomic interface" do
      %i[factor
         to_seconds
         symbol
         to_i
         to_f
         to_s
         value
         <=>
         eql?
         hash
         valid_atom?].each { |m| expect(subject).to respond_to(m) }
    end
  end

  describe '#factor' do
    it "should return the Month factor" do
      expect { ISO8601::Months.new(1).factor }.to_not raise_error
      expect(ISO8601::Months.new(2).factor).to eq(2628000)
      expect(ISO8601::Months.new(0).factor).to eq(2628000)
    end

    it "should return the Month factor for a common year" do
      expect(ISO8601::Months.new(1).factor(common_year)).to eq(2678400)
    end

    it "should return the Month factor for a leap year" do
      expect(ISO8601::Months.new(1).factor(leap_year)).to eq(2678400)
    end

    it "should return the Month factor based on february for a common year" do
      expect(ISO8601::Months.new(1).factor(common_february)).to eq(2419200)
    end

    it "should return the Month factor based on february for a leap year" do
      expect(ISO8601::Months.new(1).factor(leap_february)).to eq(2505600)
    end
  end

  describe '#to_seconds' do
    it "should return the amount of seconds" do
      expect(ISO8601::Months.new(2).to_seconds).to eq(5256000)
    end

    it "should return the amount of seconds for a common year" do
      expect(ISO8601::Months.new(2).to_seconds(common_year)).to eq(5097600)
      expect(ISO8601::Months.new(1).to_seconds(common_year)).to eq(2678400)
      expect(ISO8601::Months.new(0).to_seconds(common_year)).to eq(0)
      expect(ISO8601::Months.new(0).to_seconds(common_december)).to eq(0)
      expect(ISO8601::Months.new(2).to_seconds(common_november)).to eq(5270400)
      expect(ISO8601::Months.new(1).to_seconds(common_november)).to eq(2592000)
      expect(ISO8601::Months.new(0).to_seconds(common_november)).to eq(0)
    end

    it "should return the amount of seconds for a leap year" do
      expect(ISO8601::Months.new(2).to_seconds(leap_year)).to eq(5184000)
    end

    it "should return the amount of seconds based on februrary for a common year" do
      expect(ISO8601::Months.new(2).to_seconds(common_february)).to eq(5097600)
    end

    it "should return the amount of seconds based on february for a leap year" do
      expect(ISO8601::Months.new(2).to_seconds(leap_february)).to eq(5184000)
      expect(ISO8601::Months.new(12).to_seconds(leap_february)).to eq(31622400)
      expect(ISO8601::Months.new(12).to_seconds(leap_february)).to eq(ISO8601::Years.new(1).to_seconds(leap_year))
    end
  end

  describe '#symbol' do
    it "should return the ISO symbol" do
      expect(ISO8601::Months.new(1).symbol).to eq(:M)
    end
  end

  describe '#hash' do
    it "should build hash identity by value" do
      expect(ISO8601::Months.new(3).hash).to eq(ISO8601::Months.new(3).hash)
    end
  end
end
