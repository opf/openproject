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

class Change < ActiveRecord::Base
  belongs_to :changeset

  validates_presence_of :changeset_id, :action, :path
  before_save :init_path

  delegate :repository_encoding, :to => :changeset, :allow_nil => true, :prefix => true

  attr_protected :changeset_id

  def relative_path
    changeset.repository.relative_path(path)
  end

  def path
    # TODO: shouldn't access Changeset#to_utf8 directly
    self.path = Changeset.to_utf8(read_attribute(:path), changeset_repository_encoding)
  end

  def from_path
    # TODO: shouldn't access Changeset#to_utf8 directly
    self.from_path = Changeset.to_utf8(read_attribute(:from_path), changeset_repository_encoding)
  end

  def init_path
    self.path ||= ""
  end
end
