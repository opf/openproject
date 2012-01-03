#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class UserPreference < ActiveRecord::Base
  belongs_to :user
  serialize :others

  attr_protected :others

  def initialize(attributes = nil)
    super
    self.others ||= {}
  end

  def before_save
    self.others ||= {}
  end

  def [](attr_name)
    if attribute_present? attr_name
      super
    else
      others ? others[attr_name] : nil
    end
  end

  def []=(attr_name, value)
    if attribute_present? attr_name
      super
    else
      h = read_attribute(:others).dup || {}
      h.update(attr_name => value)
      write_attribute(:others, h)
      value
    end
  end

  def comments_sorting; self[:comments_sorting] end
  def comments_sorting=(order); self[:comments_sorting]=order end

  def warn_on_leaving_unsaved; self[:warn_on_leaving_unsaved] || '1'; end
  def warn_on_leaving_unsaved=(value); self[:warn_on_leaving_unsaved]=value; end
end
