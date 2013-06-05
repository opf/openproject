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

class UserPreference < ActiveRecord::Base
  belongs_to :user
  serialize :others

  validates_presence_of :user

  attr_accessible :user

  # attributes that have their own column
  attr_accessible :hide_mail, :time_zone, :impaired

  # shortcut methods to others hash
  attr_accessible :comments_sorting, :warn_on_leaving_unsaved

  after_initialize :init_other_preferences

  def [](attr_name)
    attribute_present?(attr_name) ? super : others[attr_name]
  end

  def []=(attr_name, value)
    attribute_present?(attr_name) ? super : others[attr_name] = value
  end

  def comments_sorting
    others[:comments_sorting]
  end

  def comments_sorting=(order)
    others[:comments_sorting] = order
  end

  def warn_on_leaving_unsaved
    others.fetch(:warn_on_leaving_unsaved) { '1' }
  end

  def warn_on_leaving_unsaved=(value)
    others[:warn_on_leaving_unsaved] = value
  end

private

  def init_other_preferences
    self.others ||= {}
  end
end
