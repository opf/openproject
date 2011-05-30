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

class WikiRedirect < ActiveRecord::Base
  generator_for :title, :method => :next_title
  generator_for :redirects_to, :method => :next_redirects_to
  generator_for :wiki, :method => :generate_wiki

  def self.next_title
    @last_title ||= 'AWikiPage'
    @last_title.succ!
    @last_title
  end

  def self.next_redirects_to
    @last_redirect ||= '/a/path/000001'
    @last_redirect.succ!
    @last_redirect
  end

  def self.generate_wiki
    Wiki.generate!
  end
end
