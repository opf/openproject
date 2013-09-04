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

    factory :work_package_journal, class: Journal do
      journable_type "WorkPackage"
      activity_type "work_packages"
      data FactoryGirl.build(:journal_work_package_journal)
    end

    factory :wiki_content_journal, class: Journal do
      journable_type "WikiContent"
      activity_type "wiki_edits"
      data FactoryGirl.build(:journal_wiki_content_journal)
    end
  end
end
