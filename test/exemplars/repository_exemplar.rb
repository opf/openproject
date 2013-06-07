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

class Repository < ActiveRecord::Base
  generator_for :type => 'Repository::Subversion'
  generator_for :url, :method => :next_url

  def self.next_url
    @last_url ||= 'file:///test/svn'
    @last_url.succ!
    @last_url
  end

end
