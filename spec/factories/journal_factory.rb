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
  factory :journal do
    created_at Time.now
    sequence(:version) {|n| n}

    factory :work_package_journal do
      journaled_type "WorkPackageJournal"
      data FactoryGirl.build(:journal_work_package_journal)
    end
  end
end
