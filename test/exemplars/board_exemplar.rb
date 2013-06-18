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

class Board < ActiveRecord::Base
  generator_for :name, :method => :next_name
  generator_for :description, :method => :next_description
  generator_for :project, :method => :generate_project

  def self.next_name
    @last_name ||= 'A Forum'
    @last_name.succ!
    @last_name
  end

  def self.next_description
    @last_description ||= 'Some description here'
    @last_description.succ!
    @last_description
  end

  def self.generate_project
    Project.generate!
  end
end
