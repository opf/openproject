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

describe UserPreference do
  let(:user) { FactoryGirl.build_stubbed(:user) }
  subject { FactoryGirl.build(:user_preference, user: user) }

  describe 'default settings' do
    it 'hides the email address' do
      expect(subject.hide_mail).to eql(true)
    end

    it 'disables accessibility mode' do
      expect(subject.impaired).to eql(false)
    end

    it 'activates no self notification' do
      expect(subject.others[:no_self_notified]).to be_truthy
    end
  end

  shared_examples 'accepts real and false booleans' do |setter, getter|
    it 'accepts true boolean' do
      subject.send(setter, true)
      expect(subject.send(getter)).to be true

      subject.send(setter, false)
      expect(subject.send(getter)).to be false
    end

    it 'accepts false booleans' do
      %w(true 1).each do |str|
        subject.send(setter, str)
        expect(subject.send(getter)).to be true
      end

      %w(false 0).each do |str|
        subject.send(setter, str)
        expect(subject.send(getter)).to be false
      end
    end
  end

  describe 'sort order' do
    it_behaves_like 'accepts real and false booleans',
                    :comments_in_reverse_order=,
                    :comments_in_reverse_order?

    it 'can be changed by string' do
      subject.comments_sorting = 'desc'
      expect(subject.comments_in_reverse_order?).to be true

      subject.comments_sorting = 'asc'
      expect(subject.comments_in_reverse_order?).to be false
    end
  end

  describe 'warn on unsaved changes' do
    it_behaves_like 'accepts real and false booleans',
                    :warn_on_leaving_unsaved=,
                    :warn_on_leaving_unsaved?
  end

  describe 'time_zone' do
    it 'allows to save short time zones' do
      subject.time_zone = 'Berlin'
      expect(subject).to be_valid
      expect(subject.time_zone).to eq('Berlin')
      expect(subject.canonical_time_zone).to eq('Europe/Berlin')
    end

    it 'allows to set full time zones' do
      subject.time_zone = 'Europe/Paris'
      expect(subject).to be_valid
      expect(subject.time_zone).to eq('Europe/Paris')
      expect(subject.canonical_time_zone).to eq('Europe/Paris')
    end

    it 'disallows invalid time zones' do
      subject.time_zone = 'Berlin123'
      expect(subject).not_to be_valid
    end

    it 'allows empty values' do
      subject.time_zone = nil
      expect(subject).to be_valid

      subject.time_zone = ''
      expect(subject).to be_valid
    end
  end

  describe 'theme' do
    it 'allows to save valid themes' do
      subject.theme = 'default'
      expect(subject).to be_valid
      expect(subject.theme).to eq(:default)

      subject.theme = :default
      expect(subject).to be_valid
      expect(subject.theme).to eq(:default)
    end

    it 'allows empty values' do
      subject.theme = nil
      expect(subject).to be_valid

      subject.theme = ''
      expect(subject).to be_valid
    end

    it 'rejects invalid themes' do
      subject.theme = :mycoolthemethatisnotavailableyet
      expect(subject).not_to be_valid

      subject.theme = 'mycoolthemethatisnotavailableyet'
      expect(subject).not_to be_valid
    end
  end

  describe 'self_notified getter/setter' do
    it 'has a getter and a setter for self_notified' do
      subject.self_notified = false
      expect(subject.self_notified?).to be_falsey
      expect(subject[:no_self_notified]).to be_truthy
    end
  end
end
