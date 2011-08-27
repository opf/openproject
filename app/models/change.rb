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

class Change < ActiveRecord::Base
  belongs_to :changeset

  validates_presence_of :changeset_id, :action, :path
  before_save :init_path

  delegate :repository_encoding, :to => :changeset, :allow_nil => true, :prefix => true

  def relative_path
    changeset.repository.relative_path(path)
  end

  def path
    # TODO: shouldn't access Changeset#to_utf8 directly
    self.path = Changeset.to_utf8(read_attribute(:path), changeset_repository_encoding)
  end

  def from_path
    # TODO: shouldn't access Changeset#to_utf8 directly
    self.path = Changeset.to_utf8(read_attribute(:from_path), changeset_repository_encoding)
  end

  def init_path
    self.path ||= ""
  end
end
