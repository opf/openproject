#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class Comment < ActiveRecord::Base
  generator_for :commented, :method => :generate_news
  generator_for :author, :method => :generate_author
  generator_for :comments => 'What great news this is.'

  def self.generate_news
    News.generate!
  end

  def self.generate_author
    User.generate_with_protected!
  end
end
