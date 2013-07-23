#-- encoding: UTF-8
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

class Issue < WorkPackageData
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
