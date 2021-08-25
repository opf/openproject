#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe UserPreference do
  subject { FactoryBot.build(:user_preference, user: user) }

  let(:user) { FactoryBot.build_stubbed(:user) }

  describe 'default settings' do
    it 'hides the email address' do
      expect(subject.hide_mail).to eql(true)
    end

    context 'with default setting auto_hide_popups to false', with_settings: { default_auto_hide_popups: false } do
      it 'disables auto hide popups' do
        expect(subject.auto_hide_popups).to be_falsey
      end
    end

    context 'with default setting auto_hide_popups to true', with_settings: { default_auto_hide_popups: true } do
      it 'disables auto hide popups' do
        expect(subject.auto_hide_popups).to be_truthy
      end
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

  describe 'auto hide popups' do
    it_behaves_like 'accepts real and false booleans',
                    :auto_hide_popups=,
                    :auto_hide_popups?
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

  describe '[]=' do
    let(:user) { FactoryBot.create(:user) }

    context 'with attributes stored in "others"' do
      it 'will save the values on sending "save"' do
        subject.save

        value_warn_on_leaving_unsaved = !subject[:warn_on_leaving_unsaved]
        value_auto_hide_popups = !subject[:auto_hide_popups]

        subject[:warn_on_leaving_unsaved] = value_warn_on_leaving_unsaved
        subject[:auto_hide_popups] = value_auto_hide_popups

        subject.save
        subject.reload

        expect(subject[:warn_on_leaving_unsaved]).to eql(value_warn_on_leaving_unsaved)
        expect(subject[:auto_hide_popups]).to eql(value_auto_hide_popups)
      end
    end
  end
end
