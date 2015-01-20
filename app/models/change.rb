#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class Change < ActiveRecord::Base
  belongs_to :changeset

  validates_presence_of :changeset_id, :action, :path
  before_save :init_path

  delegate :repository_encoding, to: :changeset, allow_nil: true, prefix: true

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
    self.path ||= ''
  end
end
