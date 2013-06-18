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

class Group < Principal
  generator_for :lastname, :method => :next_lastname

  def self.next_lastname
    @last_lastname ||= 'Group'
    @last_lastname.succ!
    @last_lastname
  end

end
