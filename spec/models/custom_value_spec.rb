#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe CustomValue do
  let(:format) { 'bool' }
  let(:custom_field) { FactoryGirl.create(:custom_field, field_format: format) }
  subject { FactoryGirl.create(:custom_value, custom_field: custom_field, value: value) }

  describe '#typed_value' do
    before do
      # we are testing roundtrips through the database here
      # the databases might choose to store values in weird and unexpected formats (e.g. booleans)
      subject.reload
    end

    describe 'boolean custom value' do
      let(:format) { 'bool' }
      let(:value) { true }

      context 'is true' do
        it { expect(subject.typed_value).to eql(value) }
      end

      context 'is false' do
        let(:value) { false }

        it { expect(subject.typed_value).to eql(value) }
      end

      context 'is nil' do
        let(:value) { nil }

        it { expect(subject.typed_value).to eql(value) }
      end
    end

    describe 'integer custom value' do
      let(:format) { 'string' }
      let(:value) { 'This is a string!' }

      it { expect(subject.typed_value).to eql(value) }
    end

    describe 'integer custom value' do
      let(:format) { 'int' }
      let(:value) { 123 }

      it { expect(subject.typed_value).to eql(value) }
    end

    describe 'float custom value' do
      let(:format) { 'float' }
      let(:value) { 3.147 }

      it { expect(subject.typed_value).to eql(value) }
    end

    describe 'date custom value' do
      let(:format) { 'date' }
      let(:value) { Date.today }

      it { expect(subject.typed_value).to eql(value) }
    end
  end
end
