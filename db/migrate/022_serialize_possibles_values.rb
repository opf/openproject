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
