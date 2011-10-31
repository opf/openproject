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

class Repository < ActiveRecord::Base
  generator_for :type => 'Subversion'
  generator_for :url, :method => :next_url

  def self.next_url
    @last_url ||= 'file:///test/svn'
    @last_url.succ!
    @last_url
  end

end
