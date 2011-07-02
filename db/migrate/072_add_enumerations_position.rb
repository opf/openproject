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

class AddEnumerationsPosition < ActiveRecord::Migration
  def self.up
    add_column(:enumerations, :position, :integer, :default => 1) unless Enumeration.column_names.include?('position')
    Enumeration.find(:all).group_by(&:opt).each do |opt, enums|
      enums.each_with_index do |enum, i|
        # do not call model callbacks
        Enumeration.update_all "position = #{i+1}", {:id => enum.id}
      end
    end
  end

  def self.down
    remove_column :enumerations, :position
  end
end
