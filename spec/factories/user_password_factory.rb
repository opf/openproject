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

FactoryGirl.define do
  factory :user_password, class: UserPassword.active_type do
    association :user
    plain_password 'adminADMIN!'

    factory :old_user_password do
      created_at 1.year.ago
      updated_at 1.year.ago
    end
  end

  factory :legacy_sha1_password, class: UserPassword::SHA1 do
    association :user
    type 'UserPassword::SHA1'
    plain_password 'mylegacypassword!'

    # Avoid going through the after_save hook
    # As it's no longer possible for Sha1 passwords
    after(:build) do |obj|
      obj.salt = SecureRandom.hex(16)
      obj.hashed_password = obj.send(:derive_password!, obj.plain_password)
      obj.plain_password = nil
    end
  end
end
