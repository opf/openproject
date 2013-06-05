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

class Attachment < ActiveRecord::Base
  generator_for :container, :method => :generate_project
  generator_for :file, :method => :generate_file
  generator_for :author, :method => :generate_author

  def self.generate_project
    Project.generate!
  end

  def self.generate_author
    User.generate_with_protected!
  end

  def self.generate_file
    @file = ActiveSupport::TestCase.mock_file
  end
end
