# frozen_string_literal: true

require 'spec_helper'

describe ISO8601::Date do
  it "should raise an error for any unknown pattern" do
    expect { ISO8601::Date.new('') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::Date.new('2') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::Date.new('20') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::Date.new('201') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::Date.new('2010-') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::Date.new('2010-') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::Date.new('20-05') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::Date.new('2010-0') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::Date.new('2010-0-09') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::Date.new('2010-1-09') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::Date.new('201001-09') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::Date.new('201-0109') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::Date.new('2014-W15-02') }.to raise_error(ISO8601::Errors::UnknownPattern)
  end

  it "should raise an error for a correct pattern but an invalid date" do
    expect { ISO8601::Date.new('2010-01-32') }.to raise_error(ISO8601::Errors::RangeError)
    expect { ISO8601::Date.new('2010-02-30') }.to raise_error(ISO8601::Errors::RangeError)
    expect { ISO8601::Date.new('2010-13-30') }.to raise_error(ISO8601::Errors::RangeError)
  end

  it "should parse any allowed pattern" do
    expect { ISO8601::Date.new('2010') }.to_not raise_error
    expect { ISO8601::Date.new('2010-05') }.to_not raise_error
    expect { ISO8601::Date.new('2010-05-09') }.to_not raise_error
    expect { ISO8601::Date.new('2014-001') }.to_not raise_error
    expect { ISO8601::Date.new('2014121') }.to_not raise_error
    expect { ISO8601::Date.new('2014-W15') }.to_not raise_error
    expect { ISO8601::Date.new('2014-W15-2') }.to_not raise_error
    expect { ISO8601::Date.new('2014W15') }.to_not raise_error
    expect { ISO8601::Date.new('2014W152') }.to_not raise_error
  end

  context 'reduced patterns' do
    it "should parse correctly reduced dates" do
      reduced_date = ISO8601::Date.new('20100509')
      expect(reduced_date.year).to eq(2010)
      expect(reduced_date.month).to eq(5)
      expect(reduced_date.day).to eq(9)
    end
  end

  it "should return the right sign for the given year" do
    expect(ISO8601::Date.new('-2014-05-31').year).to eq(-2014)
    expect(ISO8601::Date.new('+2014-05-31').year).to eq(2014)
  end

  it "should respond to delegated casting methods" do
    expect(ISO8601::Date.new('2014-12-11')).to respond_to(:to_s, :to_time, :to_date, :to_datetime)
  end

  describe '#+' do
    it "should return the result of the addition of a number" do
      expect((ISO8601::Date.new('2012-07-07') + 7).to_s).to eq('2012-07-14')
    end
  end

  describe '#-' do
    it "should return the result of the subtraction" do
      expect((ISO8601::Date.new('2012-07-07') - 7).to_s).to eq('2012-06-30')
    end
  end

  describe '#to_a' do
    it "should return an array of atoms" do
      expect(ISO8601::Date.new('2014-05-31').to_a).to eq([2014, 5, 31])
    end
  end

  describe '#atoms' do
    it "should return an array of original atoms" do
      expect(ISO8601::Date.new('2014-05-02').atoms).to eq([2014, 5, 2])
      expect(ISO8601::Date.new('2014-05').atoms).to eq([2014, 5])
      expect(ISO8601::Date.new('2014').atoms).to eq([2014])
    end
  end

  describe '#hash' do
    it "should return the date hash" do
      subject = ISO8601::Date.new('2014-08-16')
      contrast = ISO8601::Date.new('2014-08-16')

      expect(subject).to respond_to(:hash)
      expect(subject.hash).to eq(contrast.hash)
    end
  end
end
