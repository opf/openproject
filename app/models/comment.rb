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
  belongs_to :commented, :polymorphic => true, :counter_cache => true
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'

  validates_presence_of :commented, :author, :comments
end
