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
  factory :issue_relation do
    issue_from :factory => :issue
    issue_to { FactoryGirl.build(:work_package, :project => issue_from.project) }
    relation_type 'relates' # "relates", "duplicates", "duplicated", "blocks", "blocked", "precedes", "follows"
    delay nil
  end
end
