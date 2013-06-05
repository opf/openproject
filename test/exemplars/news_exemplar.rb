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
