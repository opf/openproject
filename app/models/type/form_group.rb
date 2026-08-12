# frozen_string_literal: true

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

class Type::FormGroup
  attr_accessor :key,
                :attributes,
                :type,
                :display_name

  def self.next_untitled_key(seen_keys)
    base_name = I18n.t("types.edit.form_configuration.untitled_group")
    candidate = base_name
    suffix = 2

    while seen_keys.include?(candidate)
      candidate = "#{base_name} #{suffix}"
      suffix += 1
    end

    candidate
  end

  def initialize(type, key, attributes, display_name: nil)
    self.key = key
    self.attributes = attributes
    self.type = type
    self.display_name = display_name
  end

  ##
  # Returns the symbol key, if it is not translated
  def internal_key?
    key.is_a?(Symbol)
  end

  ##
  # Translate the given attribute group if its internal
  # (== if it's a symbol)
  def translated_key
    if display_name.present?
      display_name
    elsif internal_key?
      I18n.t(Type.default_groups[key], default: key.to_s)
    elsif key.present?
      key
    else
      I18n.t("types.edit.form_configuration.untitled_group")
    end
  end

  def members
    raise SubclassResponsibilityError
  end

  def active_members(_project)
    raise SubclassResponsibilityError
  end
end
