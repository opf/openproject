#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

module Type::AttributeVisibility
  extend ActiveSupport::Concern

  included do
    serialize :attribute_visibility, Hash
    validates_each :attribute_visibility do |record, _attr, visibility|
      visibility.each do |attr_name, value|
        unless attribute_visibilities.include? value.to_s
          record.errors.add(:attribute_visibility, "for '#{attr_name}' cannot be '#{value}'")
        end
      end
    end
  end

  class_methods do
    ##
    # The possible visibility values for a work package attribute
    # as defined by a type are:
    #
    #   - default The attribute is displayed in forms if it has a value.
    #   - visible The attribute is displayed in forms even if empty.
    #   - hidden  The attribute is hidden in forms even if it has a value.
    def attribute_visibilities
      ['visible', 'hidden', 'default']
    end

    def default_attribute_visibility
      'visible'
    end
  end
end
