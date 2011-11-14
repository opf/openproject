#-- encoding: UTF-8
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

class AddUniqueIndexOnMembers < ActiveRecord::Migration
  def self.up
    # Clean and reassign MemberRole rows if needed
    MemberRole.delete_all("member_id NOT IN (SELECT id FROM #{Member.table_name})")
    MemberRole.update_all("member_id =" +
      " (SELECT min(m2.id) FROM #{Member.table_name} m1, #{Member.table_name} m2" +
      " WHERE m1.user_id = m2.user_id AND m1.project_id = m2.project_id" +
      " AND m1.id = #{MemberRole.table_name}.member_id)")
    # Remove duplicates
    Member.connection.select_values("SELECT m.id FROM #{Member.table_name} m" +
      " WHERE m.id > (SELECT min(m1.id) FROM #{Member.table_name} m1 WHERE m1.user_id = m.user_id AND m1.project_id = m.project_id)").each do |i|
        Member.delete_all(["id = ?", i])
      end

    # Then add a unique index
    add_index :members, [:user_id, :project_id], :unique => true
  end

  def self.down
    remove_index :members, [:user_id, :project_id]
  end
end
