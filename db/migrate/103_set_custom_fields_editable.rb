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

class SetCustomFieldsEditable < ActiveRecord::Migration
  def self.up
    UserCustomField.update_all("editable = #{CustomField.connection.quoted_false}")
  end

  def self.down
    UserCustomField.update_all("editable = #{CustomField.connection.quoted_true}")
  end
end
