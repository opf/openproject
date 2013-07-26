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

class RenameEndDateOnAlternateDates < ActiveRecord::Migration
  def change
    rename_column :alternate_dates, :end_date, :due_date
  end
end
