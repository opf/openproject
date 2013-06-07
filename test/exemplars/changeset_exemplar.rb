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
