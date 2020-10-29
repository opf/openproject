# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ISO8601::Years do
  let(:common_year) { ISO8601::DateTime.new('2010-01-01') }
  let(:leap_year) { ISO8601::DateTime.new('2000-01-01') }

  describe 'Atomic' do
    let(:subject) { ISO8601::Years.new(1) }

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
    it "should return the Year factor" do
      expect { ISO8601::Years.new(1).factor }.to_not raise_error
      expect(ISO8601::Years.new(2).factor).to eq(31536000)
      expect(ISO8601::Years.new(1).factor).to eq(31536000)
    end

    it "should return the Year factor for a common year" do
      expect(ISO8601::Years.new(1).factor(common_year)).to eq(31536000)
      expect(ISO8601::Years.new(0).factor(common_year)).to eq(31536000)
    end

    it "should return the Year factor for a leap year" do
      expect(ISO8601::Years.new(1).factor(leap_year)).to eq(31622400)
    end
  end

  describe '#to_seconds' do
    it "should return the amount of seconds" do
      expect(ISO8601::Years.new(2).to_seconds).to eq(63072000)
      expect(ISO8601::Years.new(-2).to_seconds).to eq(-63072000)
    end

    it "should return the amount of seconds for a common year" do
      expect(ISO8601::Years.new(2).to_seconds(common_year)).to eq(63072000)
      expect(ISO8601::Years.new(12).to_seconds(common_year)).to eq(378691200)
    end

    it "should return the amount of seconds for a leap year" do
      expect(ISO8601::Years.new(2).to_seconds(leap_year)).to eq(63158400)
      expect(ISO8601::Years.new(15).to_seconds(leap_year)).to eq(473385600)
    end
  end

  describe '#symbol' do
    it "should return the ISO symbol" do
      expect(ISO8601::Years.new(1).symbol).to eq(:Y)
    end
  end

  describe '#hash' do
    it "should build hash identity by value" do
      expect(ISO8601::Years.new(3).hash).to eq(ISO8601::Years.new(3).hash)
    end
  end
end
