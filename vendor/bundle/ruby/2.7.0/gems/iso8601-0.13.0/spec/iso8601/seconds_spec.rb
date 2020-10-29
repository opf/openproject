# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ISO8601::Seconds do
  describe 'Atomic' do
    let(:subject) { ISO8601::Seconds.new(1) }

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
    it "should return the Second factor" do
      expect(ISO8601::Seconds.new(2).factor).to eq(1)
    end

    it "should return the amount of seconds" do
      expect(ISO8601::Seconds.new(2).to_seconds).to eq(2)
      expect(ISO8601::Seconds.new(-2).to_seconds).to eq(-2)
    end
  end

  describe '#symbol' do
    it "should return the ISO symbol" do
      expect(ISO8601::Seconds.new(1).symbol).to eq(:S)
    end
  end

  describe '#hash' do
    it "should build hash identity by value" do
      expect(ISO8601::Seconds.new(3).hash).to eq(ISO8601::Seconds.new(3).hash)
    end
  end
end
