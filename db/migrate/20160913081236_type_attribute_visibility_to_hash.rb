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

class TypeAttributeVisibilityToHash < ActiveRecord::Migration[5.0]
  class TypeWithWhatever < ActiveRecord::Base
    self.table_name = :types

    serialize :attribute_visibility
  end

  class TypeWithHash < ActiveRecord::Base
    self.table_name = :types

    serialize :attribute_visibility, Hash
  end

  def up
    TypeWithWhatever.transaction do
      TypeWithWhatever.all.to_a.each do |type|
        visibility = type.attribute_visibility
        if visibility.respond_to?(:permit!)
          visibility.permit!
        end
        visibility = visibility.to_h

        TypeWithHash
          .where(id: type.id)
          .update_all(attribute_visibility: visibility)
      end
    end
  end

  def down
    TypeWithHash.transaction do
      TypeWithHash.all.to_a.each do |type|
        visibility = ActionController::Parameter.new(type.attribute_visibility)

        TypeWithWhatever
          .where(id: type.id)
          .update_all(attribute_visibility: visibility)
      end
    end
  end
end
