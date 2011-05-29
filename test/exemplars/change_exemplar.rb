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
