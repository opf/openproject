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
  factory :attachment do
    container :factory => :issue
    author :factory => :user
    sequence(:filename) { |n| "test#{n}.test" }
    sequence(:disk_filename) { |n| "test#{n}.test" }

    factory :wiki_attachment do
      container :factory => :wiki_page_with_content
    end
  end
end
