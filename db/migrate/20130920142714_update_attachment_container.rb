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

require_relative 'migration_utils/utils'

class UpdateAttachmentContainer < ActiveRecord::Migration
  include Migration::Utils

  def up
    say_with_time_silently "Changing container type from 'Issue' to 'WorkPackage'" do
      update <<-SQL
      UPDATE #{attachments_table}
      SET container_type = #{work_package_type}
      WHERE container_type = #{issue_type}
      SQL
    end
  end

  def down
    say_with_time_silently "Changing container type from 'WorkPackage' to 'Issue'" do
      update <<-SQL
      UPDATE #{attachments_table}
      SET container_type = #{issue_type}
      WHERE container_type = #{work_package_type}
      SQL
    end
  end

  private

  def attachments_table
    ActiveRecord::Base.connection.quote_table_name('attachments')
  end

  def issue_type
    ActiveRecord::Base.connection.quote('Issue')
  end

  def work_package_type
    ActiveRecord::Base.connection.quote('WorkPackage')
  end
end
