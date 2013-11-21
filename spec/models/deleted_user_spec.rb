#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

describe DeletedUser do
  before do
    User.delete_all
  end

  let(:user) { DeletedUser.new }

  describe :admin do
    it { user.admin.should be_false }
  end

  describe :logged? do
    it { user.should_not be_logged }
  end

  describe :name do
    it { user.name.should == I18n.t('user.deleted') }
  end

  describe :mail do
    it { user.mail.should be_nil }
  end

  describe :time_zone do
    it { user.time_zone.should be_nil }
  end

  describe :rss_key do
    it { user.rss_key.should be_nil }
  end

  describe :destroy do
    it { user.destroy.should be_false }
  end

  describe :available_custom_fields do
    before do
      FactoryGirl.create(:user_custom_field)
    end

    it { user.available_custom_fields.should == [] }
  end

  describe :create do
    describe "WHEN creating a second deleted user" do
      let(:u1) { FactoryGirl.build(:deleted_user) }
      let(:u2) { FactoryGirl.build(:deleted_user) }

      before do
        u1.save!
        u2.save
      end

      it { u1.should_not be_new_record }
      it { u2.should be_new_record }
      it { u2.errors[:base].should include 'A DeletedUser already exists.' }
    end
  end

  describe :valid do
    describe "WHEN no login, first-, lastname and mail is provided" do
      let(:user) { DeletedUser.new }

      it { user.should be_valid }
    end
  end

  describe :first do
    describe "WHEN a deleted user already exists" do
      let(:user) { FactoryGirl.build(:deleted_user) }

      before do
        user.save!
      end

      it { DeletedUser.first.should == user }
    end

    describe "WHEN no deleted user exists" do
      it { DeletedUser.first.is_a?(DeletedUser).should be_true }
      it { DeletedUser.first.should_not be_new_record }
    end
  end
end
