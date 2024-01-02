#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class AttributeHelpText < ApplicationRecord
  acts_as_attachable viewable_by_all_users: true

  def self.available_types
    subclasses.map { |child| child.name.demodulize }
  end

  def self.used_attributes(type)
    where(type:)
      .select(:attribute_name)
      .distinct
      .pluck(:attribute_name)
  end

  def self.all_by_scope
    all.group_by(&:attribute_scope)
  end

  def self.visible(user)
    scope = AttributeHelpText.subclasses[0].visible_condition(user)

    AttributeHelpText.subclasses[1..-1].each do |subclass|
      scope = scope.or(subclass.visible_condition(user))
    end

    scope
  end

  validates :help_text, presence: true
  validates :attribute_name, uniqueness: { scope: :type }

  def attribute_caption
    @attribute_caption ||= self.class.available_attributes[attribute_name]
  end

  def attribute_scope
    self.class.to_s.demodulize
  end

  def type_caption
    raise NotImplementedError
  end

  def self.visible_condition
    raise NotImplementedError
  end

  def self.available_attributes
    raise NotImplementedError
  end
end

require 'attribute_help_text/work_package'
require 'attribute_help_text/project'
