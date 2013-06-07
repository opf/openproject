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

class SerializePossiblesValues < ActiveRecord::Migration
  def self.up
    CustomField.find(:all).each do |field|
      if field.possible_values and field.possible_values.is_a? String
        field.possible_values = field.possible_values.split('|')
        field.save
      end
    end
  end

  def self.down
  end
end
