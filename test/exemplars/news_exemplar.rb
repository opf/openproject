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

class News < ActiveRecord::Base
  generator_for :title, :method => :next_title
  generator_for :description, :method => :next_description

  def self.next_title
    @last_title ||= 'A New Item'
    @last_title.succ!
    @last_title
  end

  def self.next_description
    @last_description ||= 'Some content here'
    @last_description.succ!
    @last_description
  end
end
