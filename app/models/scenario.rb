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

class Scenario < ActiveRecord::Base
  unloadable

  self.table_name = 'scenarios'

  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :project

  has_many :alternate_dates, :class_name  => 'AlternateDate',
                             :foreign_key => 'scenario_id',
                             :dependent   => :delete_all

  validates_presence_of :name, :project

  validates_length_of :name, :maximum => 255, :unless => lambda { |e| e.name.blank? }
end
