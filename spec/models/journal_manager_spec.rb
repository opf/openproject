#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe JournalManager, :type => :model do
  describe '#self.changed?' do
    let(:journable) do
      FactoryGirl.create(:work_package, description: old).tap do |journable|
        # replace newline character and apply another change
        journable.assign_attributes description: changed
      end
    end

    context 'when only the newline character representation has changed' do
      let(:old) { "Description\nContains newline character" }
      let(:changed) { old.gsub("\n", "\r\n") }

      subject { JournalManager.changed? journable }

      it { is_expected.to be_falsey }
    end

    context 'when old value is nil and changed value is an empty string' do
      let(:old) { nil }
      let(:changed) { '' }

      subject { JournalManager.changed? journable }

      it { is_expected.to be_falsey }
    end

    context 'when changed value is nil and old value is an empty string' do
      let(:old) { '' }
      let(:changed) { nil }

      subject { JournalManager.changed? journable }

      it { is_expected.to be_falsey }
    end

    context 'when changed value has a value and old value is an empty string' do
      let(:old) { '' }
      let(:changed) { 'Changed text' }

      subject { JournalManager.changed? journable }

      it { is_expected.to be_truthy }
    end

    context 'when changed value has a value and old value is nil' do
      let(:old) { nil }
      let(:changed) { 'Changed text' }

      subject { JournalManager.changed? journable }

      it { is_expected.to be_truthy }
    end

    context 'when changed value is nil and old value was some text' do
      let(:old) { 'Old text' }
      let(:changed) { nil }

      subject { JournalManager.changed? journable }

      it { is_expected.to be_truthy }
    end

    context 'when changed value is an empty string and old value was some text' do
      let(:old) { 'Old text' }
      let(:changed) { '' }

      subject { JournalManager.changed? journable }

      it { is_expected.to be_truthy }
    end
  end
end
