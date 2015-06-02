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

describe UserPassword, type: :model do
  let(:old_password) { FactoryGirl.create(:old_user_password) }
  let(:password) { FactoryGirl.create(:user_password) }

  describe '#expired?' do
    it 'should be true for an old password when password expiry is activated' do
      with_settings password_days_valid: 30 do
        expect(old_password.expired?).to be_truthy
      end
    end

    it 'should be false when password expiry is enabled and the password was changed recently' do
      with_settings password_days_valid: 30 do
        expect(password.expired?).to be_falsey
      end
    end

    it 'should be false for an old password when password expiry is disabled' do
      with_settings password_days_valid: 0 do
        expect(old_password.expired?).to be_falsey
      end
    end
  end

end
