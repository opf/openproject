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

class AddCustomFieldsPosition < ActiveRecord::Migration
  def self.up
    add_column(:custom_fields, :position, :integer, :default => 1)
    CustomField.find(:all).group_by(&:type).each  do |t, fields|
      fields.each_with_index do |field, i|
        # do not call model callbacks
        CustomField.update_all "position = #{i+1}", {:id => field.id}
      end
    end
  end

  def self.down
    remove_column :custom_fields, :position
  end
end
