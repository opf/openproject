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

class Document < ActiveRecord::Base
  generator_for :title, :method => :next_title

  def self.next_title
    @last_title ||= 'Document001'
    @last_title.succ!
    @last_title
  end
end
