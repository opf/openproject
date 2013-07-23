#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

FactoryGirl.define do
  factory :user_password do
    association :user
    plain_password 'adminADMIN!'

    factory :old_user_password do
      created_at 1.year.ago
      updated_at 1.year.ago
    end
  end
end
