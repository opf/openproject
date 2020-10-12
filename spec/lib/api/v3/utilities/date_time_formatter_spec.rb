#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe :DateTimeFormatter do
  subject { ::API::V3::Utilities::DateTimeFormatter }
  let(:date) { Date.today }
  let(:datetime) { DateTime.now }

  shared_examples_for 'can format nil' do
    it 'accepts nil if asked to' do
      expect(subject.send(method, nil, allow_nil: true)).to eql(nil)
    end

    it 'returns usual result for non-nils' do
      expected = subject.send(method, input)
      expect(subject.send(method, input, allow_nil: true)).to eql(expected)
    end
  end

  shared_examples_for 'can parse nil' do
    it 'accepts nil if asked to' do
      expect(subject.send(method, nil, 'prop', allow_nil: true)).to eql(nil)
    end

    it 'returns usual result for non-nils' do
      expected = subject.send(method, input, 'prop')
      expect(subject.send(method, input, 'prop', allow_nil: true)).to eql(expected)
    end
  end

  describe 'format_date' do
    it 'formats dates' do
      expect(subject.format_date(date)).to eql(date.iso8601)
    end

    it 'formats datetimes' do
      expect(subject.format_date(datetime)).to eql(datetime.to_date.iso8601)
    end

    it_behaves_like 'can format nil' do
      let(:method) { :format_date }
      let(:input) { date }
    end
  end

  describe 'parse_date' do
    it 'parses ISO 8601 dates' do
      expect(subject.parse_date(date.iso8601, 'prop')).to eql(date)
    end

    it 'rejects parsing non ISO date formats' do
      bad_format = date.strftime('%d.%m.%Y')
      expect {
        subject.parse_date(bad_format, 'prop')
      }.to raise_error(API::Errors::PropertyFormatError)
    end

    it 'rejects parsing ISO 8601 date + time formats' do
      bad_format = datetime.iso8601
      expect {
        subject.parse_date(bad_format, 'prop')
      }.to raise_error(API::Errors::PropertyFormatError)
    end

    it_behaves_like 'can parse nil' do
      let(:method) { :parse_date }
      let(:input) { date.iso8601 }
    end
  end

  describe 'format_datetime' do
    it 'formats dates' do
      expect(subject.format_datetime(date)).to eql(date.to_datetime.utc.iso8601)
    end

    it 'formats datetimes' do
      expect(subject.format_datetime(datetime)).to eql(datetime.utc.iso8601)
    end

    it_behaves_like 'can format nil' do
      let(:method) { :format_datetime }
      let(:input) { datetime }
    end
  end

  describe 'format_duration_from_hours' do
    it 'formats floats' do
      expect(subject.format_duration_from_hours(5.0)).to eql('PT5H')
    end

    it 'formats fractional floats' do
      expect(subject.format_duration_from_hours(5.5)).to eql('PT5H30M')
    end

    it 'includes seconds' do
      expect(subject.format_duration_from_hours(5.501)).to eql('PT5H30M3S')
    end

    it 'formats ints' do
      expect(subject.format_duration_from_hours(5)).to eql('PT5H')
    end

    it_behaves_like 'can format nil' do
      let(:method) { :format_duration_from_hours }
      let(:input) { 5 }
    end
  end

  describe 'parse_duration_to_hours' do
    it 'parses ISO 8601 durations of full hours' do
      expect(subject.parse_duration_to_hours('PT5H', 'prop')).to eql(5.0)
    end

    it 'parses ISO 8601 durations of fractional hours' do
      expect(subject.parse_duration_to_hours('PT5H30M', 'prop')).to eql(5.5)
    end

    it 'parses ISO 8601 durations of days' do
      expect(subject.parse_duration_to_hours('P1D', 'prop')).to eql(24.0)
    end

    it 'rejects parsing non sense' do
      expect {
        subject.parse_duration_to_hours('foo', 'prop')
      }.to raise_error(API::Errors::PropertyFormatError)
    end

    it 'rejects parsing pure number strings' do
      expect {
        subject.parse_duration_to_hours('5', 'prop')
      }.to raise_error(API::Errors::PropertyFormatError)
    end

    it 'rejects parsing pure numbers' do
      expect {
        subject.parse_duration_to_hours(5, 'prop')
      }.to raise_error(API::Errors::PropertyFormatError)
    end

    it_behaves_like 'can parse nil' do
      let(:method) { :parse_duration_to_hours }
      let(:input) { 'PT5H' }
    end
  end
end
