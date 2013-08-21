#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2010-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class PrincipalRole < ActiveRecord::Base
  belongs_to :principal
  belongs_to :role
  validate :validate_assignable

  attr_accessible :principal,
                  :role

  def validate_assignable
    add_error_can_not_be_assigned unless self.role.assignable_to?(self.principal)
  end

  private

  def add_error_can_not_be_assigned
    self.errors[:base] << l(:error_can_not_be_assigned)
  end
end
