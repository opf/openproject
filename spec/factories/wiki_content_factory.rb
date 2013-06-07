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
  factory :wiki_content do
    page :factory => :wiki_page
    author :factory => :user

    text { |a| "h1. #{a.page.title}\n\nPage Content Version #{a.version}." }
  end
end

