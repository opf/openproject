#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class Issue < ActiveRecord::Base
  generator_for :subject, :method => :next_subject
  generator_for :author, :method => :next_author
  generator_for :priority, :method => :fetch_priority

  def self.next_subject
    @last_subject ||= 'Subject 0'
    @last_subject.succ!
    @last_subject
  end

  def self.next_author
    User.generate_with_protected!
  end

  def self.fetch_priority
    IssuePriority.first || IssuePriority.generate!
  end

end
