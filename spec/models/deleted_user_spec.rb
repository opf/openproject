#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe DeletedUser, type: :model do
  before do
    User.delete_all
  end

  let(:user) { DeletedUser.new }

  describe '#admin' do
    it { expect(user.admin).to be_falsey }
  end

  describe '#logged?' do
    it { expect(user).not_to be_logged }
  end

  describe '#name' do
    it { expect(user.name).to eq(I18n.t('user.deleted')) }
  end

  describe '#mail' do
    it { expect(user.mail).to be_nil }
  end

  describe '#time_zone' do
    it { expect(user.time_zone).to be_nil }
  end

  describe '#rss_key' do
    it { expect(user.rss_key).to be_nil }
  end

  describe '#destroy' do
    it { expect(user.destroy).to be_falsey }
  end

  describe '#available_custom_fields' do
    before do
      FactoryGirl.create(:user_custom_field)
    end

    it { expect(user.available_custom_fields).to eq([]) }
  end

  describe '#create' do
    describe 'WHEN creating a second deleted user' do
      let(:u1) { FactoryGirl.build(:deleted_user) }
      let(:u2) { FactoryGirl.build(:deleted_user) }

      before do
        u1.save!
        u2.save
      end

      it { expect(u1).not_to be_new_record }
      it { expect(u2).to be_new_record }
      it { expect(u2.errors[:base]).to include 'A DeletedUser already exists.' }
    end
  end

  describe '#valid' do
    describe 'WHEN no login, first-, lastname and mail is provided' do
      let(:user) { DeletedUser.new }

      it { expect(user).to be_valid }
    end
  end

  describe '#first' do
    describe 'WHEN a deleted user already exists' do
      let(:user) { FactoryGirl.build(:deleted_user) }

      before do
        user.save!
      end

      it { expect(DeletedUser.first).to eq(user) }
    end

    describe 'WHEN no deleted user exists' do
      it { expect(DeletedUser.first.is_a?(DeletedUser)).to be_truthy }
      it { expect(DeletedUser.first).not_to be_new_record }
    end
  end
end
