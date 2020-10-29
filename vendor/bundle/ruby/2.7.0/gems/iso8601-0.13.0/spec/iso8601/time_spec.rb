# frozen_string_literal: true

require 'spec_helper'

describe ISO8601::Time do
  it "should raise an error for any unknown pattern" do
    expect { ISO8601::Time.new('') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::Time.new('T') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::Time.new('T10:3012+0400') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::Time.new('T10:30:12+0400') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::Time.new('T10:30:12+040') }.to raise_error(ISO8601::Errors::UnknownPattern)
  end

  it "should raise an error for a correct pattern but an invalid date" do
    expect { ISO8601::Time.new('T25:00:00') }.to raise_error(ISO8601::Errors::RangeError)
    expect { ISO8601::Time.new('T00:61:00') }.to raise_error(ISO8601::Errors::RangeError)
    expect { ISO8601::Time.new('T00:00:61') }.to raise_error(ISO8601::Errors::RangeError)
  end

  it "should parse any allowed pattern" do
    expect { ISO8601::Time.new('T10') }.to_not raise_error
    expect { ISO8601::Time.new('T10-00:00') }.to_not raise_error
    expect { ISO8601::Time.new('T10Z') }.to_not raise_error
    expect { ISO8601::Time.new('T10:30') }.to_not raise_error
    expect { ISO8601::Time.new('T10:30Z') }.to_not raise_error
    expect { ISO8601::Time.new('T10:30:12') }.to_not raise_error
    expect { ISO8601::Time.new('T10:30:12Z') }.to_not raise_error
    expect { ISO8601::Time.new('T10:30:12+04') }.to_not raise_error
    expect { ISO8601::Time.new('T10:30:12+04:00') }.to_not raise_error
    expect { ISO8601::Time.new('T10:30:12-04:00') }.to_not raise_error
    expect { ISO8601::Time.new('T103012+0400') }.to_not raise_error
    expect { ISO8601::Time.new('T103012+04') }.to_not raise_error
    expect { ISO8601::Time.new('T10:30:12-00:00') }.to_not raise_error
    expect { ISO8601::Time.new('T16:26:10,5Z') }.to_not raise_error
    expect { ISO8601::Time.new('T10+00:00') }.to_not raise_error
  end

  context 'reduced patterns' do
    it "should parse correctly reduced times" do
      reduced_time = ISO8601::Time.new('T101112Z')
      expect(reduced_time.hour).to eq(10)
      expect(reduced_time.minute).to eq(11)
      expect(reduced_time.second).to eq(12)
    end
  end

  it "should return each atomic value" do
    t = ISO8601::Time.new('T12:02:01+04:00', ::Date.parse('2010-05-09'))
    expect(t.hour).to eq(12)
    expect(t.minute).to eq(2)
    expect(t.second).to eq(1)
    expect(t.zone).to eq('+04:00')
  end

  it "should keep the correct fraction when using commma separators" do
    expect(ISO8601::Time.new('T16:26:10,5Z').second).to eq(10.5)
  end

  it "should respond to delegated casting methods" do
    expect(ISO8601::Time.new('T10:09:08Z')).to respond_to(:to_s, :to_time, :to_date, :to_datetime)
  end

  describe '#+' do
    it "should return the result of the addition of a number" do
      expect((ISO8601::Time.new('T20:20:20Z') + 10).to_s).to eq('T20:20:30+00:00')
      expect((ISO8601::Time.new('T20:20:20.5Z') + 10).to_s).to eq('T20:20:30.5+00:00')
      expect((ISO8601::Time.new('T20:20:20+02:00') + 10.09).to_s).to eq('T20:20:30.1+02:00')
      expect((ISO8601::Time.new('T20:20:20+02:00') + 10.1).to_s).to eq('T20:20:30.1+02:00')
      expect((ISO8601::Time.new('T20:20:20+02:00') + 10).second).to eq(30)
      expect((ISO8601::Time.new('T20:20:20.5Z') + 10).second).to eq(30.5)
      expect((ISO8601::Time.new('T20:20:20+02:00') + 10.09).second).to eq(30.1)
    end
  end

  describe '#-' do
    it "should return the result of the subtraction of a number" do
      expect((ISO8601::Time.new('T20:20:20+01:00') - 10).to_s).to eq('T20:20:10+01:00')
      expect((ISO8601::Time.new('T20:20:20.11+02:00') - 10).to_s).to eq('T20:20:10.1+02:00')
    end
  end

  describe '#to_a' do
    it "should return an array of atoms" do
      expect(ISO8601::Time.new('T19:29:39Z').to_a).to eq([19, 29, 39, '+00:00'])
    end
  end

  describe '#atoms' do
    it "should return an array of atoms" do
      expect(ISO8601::Time.new('T19:29:39+04:00').atoms).to eq([19, 29, 39, '+04:00'])
      expect(ISO8601::Time.new('T19:29:39Z').atoms).to eq([19, 29, 39, 'Z'])
      expect(ISO8601::Time.new('T19:29:39').atoms).to eq([19, 29, 39])
      expect(ISO8601::Time.new('T19:29').atoms).to eq([19, 29, 0.0])
      expect(ISO8601::Time.new('T19:29Z').atoms).to eq([19, 29, 0.0, 'Z'])
      expect(ISO8601::Time.new('T19Z').atoms).to eq([19, 0, 0.0, 'Z'])
    end
  end

  describe '#hash' do
    it "should return the time hash" do
      subject = ISO8601::Time.new('T20:11:10Z')

      expect(subject).to respond_to(:hash)
    end
    it "should return the same hash" do
      subject = ISO8601::Time.new('T20:11:10Z')
      contrast = ISO8601::Time.new('T20:11:10Z')

      expect(subject.hash).to eq(contrast.hash)
    end
  end
end
