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
  factory :document do
    project
    category :factory => :document_category
    sequence(:description) { |n| "I am a document's description  No. #{n}" }
    sequence(:title) { |n| "I am the document No. #{n}" }
  end
end
