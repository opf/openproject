#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class MenuItem < ApplicationRecord
  belongs_to :parent, class_name: "MenuItem", optional: true
  has_many :children, -> {
    order("id ASC")
  }, class_name: "MenuItem", dependent: :destroy, foreign_key: :parent_id

  serialize :options, type: Hash

  validates :title,
            presence: true,
            uniqueness: { scope: %i[navigatable_id type], case_sensitive: true }

  validates :name,
            presence: true,
            uniqueness: { scope: %i[navigatable_id parent_id], case_sensitive: true }

  def setting
    if new_record?
      :no_item
    elsif is_main_item?
      :main_item
    else
      :sub_item
    end
  end

  def is_main_item?
    parent_id.nil?
  end

  def is_sub_item?
    !parent_id.nil?
  end

  def is_only_main_item?
    self.class.main_items(wiki.id) == [self]
  end
end
