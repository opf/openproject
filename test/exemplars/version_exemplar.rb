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

class Version < ActiveRecord::Base
  generator_for :name, :method => :next_name
  generator_for :status => 'open'

  def self.next_name
    @last_name ||= 'Version 1.0.0'
    @last_name.succ!
    @last_name
  end

end
