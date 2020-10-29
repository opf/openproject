# frozen_string_literal: true

require 'spec_helper'

describe ISO8601::DateTime do
  it "should raise a ISO8601::Errors::UnknownPattern for any unknown pattern" do
    expect { ISO8601::DateTime.new('') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::DateTime.new('2') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::DateTime.new('20') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::DateTime.new('201') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::DateTime.new('2010-') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::DateTime.new('2010-') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::DateTime.new('20-05') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::DateTime.new('2010-0') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::DateTime.new('2010-0-09') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::DateTime.new('2010-1-09') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::DateTime.new('201001-09') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::DateTime.new('201-0109') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::DateTime.new('2010-05-09T103012+0400') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::DateTime.new('20100509T10:30:12+04:00') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::DateTime.new('2010-05T10:30:12Z') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::DateTime.new('2010T10:30:12Z') }.to raise_error(ISO8601::Errors::UnknownPattern)
    expect { ISO8601::DateTime.new('2014-W15-02T10:11:12Z') }.to raise_error(ISO8601::Errors::UnknownPattern)
  end

  it "should raise a RangeError for a correct pattern but an invalid date" do
    expect { ISO8601::DateTime.new('2010-01-32') }.to raise_error(ISO8601::Errors::RangeError)
    expect { ISO8601::DateTime.new('2010-02-30') }.to raise_error(ISO8601::Errors::RangeError)
    expect { ISO8601::DateTime.new('2010-13-30') }.to raise_error(ISO8601::Errors::RangeError)
    expect { ISO8601::DateTime.new('2010-12-30T25:00:00') }.to raise_error(ISO8601::Errors::RangeError)
  end

  it "should parse any allowed pattern" do
    expect { ISO8601::DateTime.new('2010') }.to_not raise_error
    expect { ISO8601::DateTime.new('2010-05') }.to_not raise_error
    expect { ISO8601::DateTime.new('2010-05-09') }.to_not raise_error
    expect { ISO8601::DateTime.new('2010-05-09T10') }.to_not raise_error
    expect { ISO8601::DateTime.new('2010-05-09T10:30') }.to_not raise_error
    expect { ISO8601::DateTime.new('2010-05-09T10:30:12') }.to_not raise_error
    expect { ISO8601::DateTime.new('2010-05-09T10:30:12Z') }.to_not raise_error
    expect { ISO8601::DateTime.new('2010-05-09T10:30:12+04') }.to_not raise_error
    expect { ISO8601::DateTime.new('2010-05-09T10:30:12+04:00') }.to_not raise_error
    expect { ISO8601::DateTime.new('2010-05-09T10:30:12-04:00') }.to_not raise_error
    expect { ISO8601::DateTime.new('2010-05-09T10:30:12-00:00') }.to_not raise_error
    expect { ISO8601::DateTime.new('-2014-05-31T16:26:00Z') }.to_not raise_error
    expect { ISO8601::DateTime.new('2014-05-31T16:26:10.5Z') }.to_not raise_error
    expect { ISO8601::DateTime.new('2014-05-31T16:26:10,5Z') }.to_not raise_error
    expect { ISO8601::DateTime.new('T10:30:12Z') }.to_not raise_error
    expect { ISO8601::DateTime.new('2014-001') }.to_not raise_error
    expect { ISO8601::DateTime.new('2014121') }.to_not raise_error
    expect { ISO8601::DateTime.new('2014-121T10:11:12Z') }.to_not raise_error
    expect { ISO8601::DateTime.new('20100509T103012+0400') }.to_not raise_error
    expect { ISO8601::DateTime.new('20100509') }.to_not raise_error
    expect { ISO8601::DateTime.new('T103012+0400') }.to_not raise_error
    expect { ISO8601::DateTime.new('T103012+04') }.to_not raise_error
    expect { ISO8601::DateTime.new('T103012+04') }.to_not raise_error
  end

  context 'reduced patterns' do
    it "should parse correctly reduced dates" do
      reduced_date = ISO8601::DateTime.new('20100509')
      expect(reduced_date.year).to eq(2010)
      expect(reduced_date.month).to eq(5)
      expect(reduced_date.day).to eq(9)
    end
    it "should parse correctly reduced times" do
      reduced_time = ISO8601::DateTime.new('T101112Z')
      expect(reduced_time.hour).to eq(10)
      expect(reduced_time.minute).to eq(11)
      expect(reduced_time.second).to eq(12)
    end
    it "should parse correctly reduced date times" do
      reduced_datetime = ISO8601::DateTime.new('20140531T101112Z')
      expect(reduced_datetime.year).to eq(2014)
      expect(reduced_datetime.month).to eq(5)
      expect(reduced_datetime.day).to eq(31)
      expect(reduced_datetime.hour).to eq(10)
      expect(reduced_datetime.minute).to eq(11)
      expect(reduced_datetime.second).to eq(12)
    end
  end

  it "should return each atomic value" do
    dt = ISO8601::DateTime.new('2010-05-09T12:02:01+04:00')
    expect(dt.year).to eq(2010)
    expect(dt.month).to eq(5)
    expect(dt.day).to eq(9)
    expect(dt.hour).to eq(12)
    expect(dt.minute).to eq(2)
    expect(dt.second).to eq(1)
    expect(dt.zone).to eq('+04:00')
  end

  it "should return the right sign for the given year" do
    expect(ISO8601::DateTime.new('-2014-05-31T16:26:00Z').year).to eq(-2014)
    expect(ISO8601::DateTime.new('+2014-05-31T16:26:00Z').year).to eq(2014)
  end

  it "should respond to delegated casting methods" do
    dt = ISO8601::DateTime.new('2014-12-11T10:09:08Z')
    expect(dt).to respond_to(:to_s, :to_time, :to_date, :to_datetime)
  end

  describe '#+' do
    it "should return the result of the addition of a number" do
      expect((ISO8601::DateTime.new('2012-07-07T20:20:20Z') + 10).to_s).to eq('2012-07-07T20:20:30+00:00')
      expect((ISO8601::DateTime.new('2012-07-07T20:20:20.5Z') + 10).to_s).to eq('2012-07-07T20:20:30.5+00:00')
      expect((ISO8601::DateTime.new('2012-07-07T20:20:20+02:00') + 10.09).to_s).to eq('2012-07-07T20:20:30.1+02:00')
      expect((ISO8601::DateTime.new('2012-07-07T20:20:20+02:00') + 10.1).to_s).to eq('2012-07-07T20:20:30.1+02:00')
      expect((ISO8601::DateTime.new('2012-07-07T20:20:20+02:00') + 10).second).to eq(30)
      expect((ISO8601::DateTime.new('2012-07-07T20:20:20.5Z') + 10).second).to eq(30.5)
      expect((ISO8601::DateTime.new('2012-07-07T20:20:20+02:00') + 10.09).second).to eq(30.1)
    end
  end

  describe '#-' do
    it "should return the result of the subtraction of a number" do
      expect((ISO8601::DateTime.new('2012-07-07T20:20:20Z') - 10).to_s).to eq('2012-07-07T20:20:10+00:00')
    end
  end

  describe '#to_a' do
    it "should return an array of atoms" do
      dt = ISO8601::DateTime.new('2014-05-31T19:29:39Z').to_a
      expect(dt).to be_kind_of(Array)
      expect(dt).to eq([2014, 5, 31, 19, 29, 39, '+00:00'])
    end
  end

  describe '#hash' do
    it "should return the datetime hash" do
      subject = ISO8601::DateTime.new('2014-08-16T20:11:10Z')
      contrast = ISO8601::DateTime.new('2014-08-16T20:11:10Z')

      expect(subject.hash == contrast.hash).to be_truthy
      expect(subject.hash).to eq(contrast.hash)
    end
  end

  describe '#==' do
    it "should identify loose precision datetimes" do
      expect(ISO8601::DateTime.new('2014') == ISO8601::DateTime.new('2014')).to be_truthy
      expect(ISO8601::DateTime.new('2014') == ISO8601::DateTime.new('2015')).to be_falsy
      expect(ISO8601::DateTime.new('2014-10') == ISO8601::DateTime.new('2014-11')).to be_falsy
      expect(ISO8601::DateTime.new('2014-10') == ISO8601::DateTime.new('2014-11')).to be_falsy
      expect(ISO8601::DateTime.new('2014-10-11T12') == ISO8601::DateTime.new('2014-10-11T13')).to be_falsy
      expect(ISO8601::DateTime.new('2014-10-11T12:13') == ISO8601::DateTime.new('2014-10-11T12:14')).to be_falsy
      expect(ISO8601::DateTime.new('2014-10-11T12:13:10') == ISO8601::DateTime.new('2014-10-11T12:13:10.0')).to be_truthy
      expect(ISO8601::DateTime.new('2014-10-11T12:13:10.1') == ISO8601::DateTime.new('2014-10-11T12:13:10.2')).to be_falsy
    end

    it "should identify as the same when two dates with different timezones are the same timestamp" do
      expect(ISO8601::DateTime.new('2014-10-11T12:13:14Z') == ISO8601::DateTime.new('2014-10-11T13:13:14+01:00')).to be_truthy
    end
  end
end
