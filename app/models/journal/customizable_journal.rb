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

class Journal::CustomizableJournal < ActiveRecord::Base
  self.table_name = "customizable_journals"

  belongs_to :journal
  belongs_to :custom_field, foreign_key: :custom_field_id
end
