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

module WorkPackage::Parent
  def self.prepended(base)
    base.after_save :update_parent_relation
    base.attribute 'parent_id', :integer
    base.define_attribute_method 'parent'
  end

  attr_accessor :parent_object,
                :do_halt

  def parent=(work_package)
    parent_id_will_change! if parent_id != (work_package && work_package.id)
    @parent_set = true

    if work_package
      @parent_id = work_package.id
      @parent_object = work_package
    else
      @parent_object = nil
      @parent_id = nil
    end
  end

  def parent_will_change!
    parent_id_will_change!
  end

  def parent
    if @parent_set
      @parent_object || parent_from_id
    else
      @parent_object || parent_from_relation || parent_from_id
    end
  end

  def reload(*args)
    @parent_object = nil
    @parent_id = nil
    @parent_set = nil
    @parent_id_previous_changes = nil

    super
  end

  def changes_applied
    @parent_id_previous_changes = changes.slice(:parent_id)

    super
  end

  def previous_changes
    super.merge(@parent_id_previous_changes || {})
  end

  def parent_id=(id)
    id = id.to_i > 0 ? id.to_i : nil

    parent_id_will_change! if parent_id != id
    @parent_set = true

    @parent_object = nil if @parent_object && @parent_object.id != id
    @parent_id = id
  end

  def parent_id
    return @parent_id if @parent_set

    @parent_id || parent && parent.id
  end

  private

  def update_parent_relation
    return unless changes[:parent_id]

    if parent_relation
      parent_relation.destroy
    end

    if parent_object
      create_parent_relation from: parent_object
    elsif @parent_id
      create_parent_relation from_id: @parent_id
    end
  end

  def parent_from_relation
    if parent_relation && ((@parent_id && parent_relation.from.id == @parent_id) || !@parent_id)
      @parent_object = parent_relation.from
    end
  end

  def parent_from_id
    if @parent_id
      @parent_object = WorkPackage.find(@parent_id)
    end
  end
end
