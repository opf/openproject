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
  factory :wiki_menu_item do
    wiki

    sequence(:name) {|n| "Item No. #{n}" }
    sequence(:title) {|n| "Wiki Title #{n}" }
  end
end
