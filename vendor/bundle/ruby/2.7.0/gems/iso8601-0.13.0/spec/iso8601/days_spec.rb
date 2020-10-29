# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ISO8601::Days do
  describe 'Atomic' do
    let(:subject) { ISO8601::Days.new(1) }

    it "should respond to the Atomic interface" do
      expect(subject).to respond_to(:factor)
      expect(subject).to respond_to(:to_seconds)
      expect(subject).to respond_to(:symbol)
      expect(subject).to respond_to(:to_i)
      expect(subject).to respond_to(:to_f)
      expect(subject).to respond_to(:to_s)
      expect(subject).to respond_to(:value)
      expect(subject).to respond_to(:<=>)
      expect(subject).to respond_to(:eql?)
      expect(subject).to respond_to(:hash)
      expect(subject).to respond_to(:valid_atom?)
    end
  end

  describe '#factor' do
    it "should return the Day factor" do
      expect(ISO8601::Days.new(2).factor).to eq(86400)
    end

    it "should return the amount of seconds" do
      expect(ISO8601::Days.new(2).to_seconds).to eq(172800)
      expect(ISO8601::Days.new(-2).to_seconds).to eq(-172800)
    end
  end

  describe '#symbol' do
    it "should return the ISO symbol" do
      expect(ISO8601::Days.new(1).symbol).to eq(:D)
    end
  end

  describe '#hash' do
    it "should build hash identity by value" do
      expect(ISO8601::Days.new(3).hash).to eq(ISO8601::Days.new(3).hash)
    end
  end
end
