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

class Change < ActiveRecord::Base
  generator_for :action => 'A'
  generator_for :path, :method => :next_path
  generator_for :changeset, :method => :generate_changeset

  def self.next_path
    @last_path ||= 'test/dir/aaa0001'
    @last_path.succ!
    @last_path
  end

  def self.generate_changeset
    Changeset.generate!
  end
end
