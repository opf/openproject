#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2011-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'meeting_agenda'

FactoryGirl.define do
  factory :meeting_agenda_journal do |m|
    m.association :journaled, :factory => :meeting_agenda
  end
end
