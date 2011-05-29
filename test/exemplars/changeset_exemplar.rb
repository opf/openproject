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

class Changeset < ActiveRecord::Base
  generator_for :revision, :method => :next_revision
  generator_for :committed_on => Date.today
  generator_for :repository, :method => :generate_repository

  def self.next_revision
    @last_revision ||= '1'
    @last_revision.succ!
    @last_revision
  end

  def self.generate_repository
    Repository::Subversion.generate!
  end
end
