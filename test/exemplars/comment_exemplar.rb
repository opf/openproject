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
