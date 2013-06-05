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

class FixMessagesStickyNull < ActiveRecord::Migration
  def self.up
    Message.update_all('sticky = 0', 'sticky IS NULL')
  end

  def self.down
    # nothing to do
  end
end
