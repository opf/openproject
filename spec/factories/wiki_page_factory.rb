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
  factory :wiki_page do
    wiki
    sequence(:title) { |n| "Wiki Page No. #{n}" }

    factory :wiki_page_with_content do
      after :build do |wiki_page|
        wiki_page.content = FactoryGirl.build :wiki_content, :page => wiki_page
      end
    end
  end
end
