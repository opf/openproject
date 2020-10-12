#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module WorkPackage::Parent
  def self.prepended(base)
    base.after_save :update_parent_relation, if: :saved_change_to_parent_id?
    base.include VirtualAttribute

    base.virtual_attribute 'parent_id', cast_type: :integer

    base.define_attribute_method 'parent'

    base.scope :with_parent, ->(*args) do
      opts = Hash(args.first)
      # noinspection RubySimplifyBooleanInspection
      neg = opts[:present] == false ? "NOT" : ""
      rel = Relation.table_name
      wp = WorkPackage.table_name

      query = "#{neg} EXISTS (SELECT 1 FROM #{rel} WHERE #{rel}.to_id = #{wp}.id AND #{rel}.hierarchy > 0"

      if opts[:in].respond_to? :arel
        subset = opts[:in].arel #                            .select() (or project()) will only add columns
        subset.projections = [WorkPackage.arel_table[:id]] # but we only need the ID, so we reset the projections

        query += " AND relations.from_id IN (#{subset.to_sql})"
      end

      query += " LIMIT 1)"

      where(query)
    end

    base.scope :without_parent, ->(*args) do
      with_parent Hash(args.first).merge(present: false)
    end

    base.scope :with_children, ->(*args) do
      opts = Hash(args.first)
      # noinspection RubySimplifyBooleanInspection
      neg = opts[:present] == false ? "NOT" : ""
      rel = Relation.table_name
      wp = WorkPackage.table_name

      query = "#{neg} EXISTS (SELECT 1 FROM #{rel} WHERE #{rel}.from_id = #{wp}.id AND #{rel}.hierarchy > 0"

      if opts[:in].respond_to? :arel
        subset = opts[:in].arel #                            .select() (or project()) will only add columns
        subset.projections = [WorkPackage.arel_table[:id]] # but we only need the ID, so we reset the projections

        query += " AND relations.to_id IN (#{subset.to_sql})"
      end

      query += " LIMIT 1)"

      where(query)
    end

    base.scope :without_children, ->(*args) do
      with_children Hash(args.first).merge(present: false)
    end
  end

  attr_accessor :parent_object,
                :do_halt

  def parent=(work_package)
    id = work_package&.id

    self.parent_id = id

    @parent_object = work_package
  end

  def parent
    if @parent_id_set
      @parent_object || parent_from_id
    else
      @parent_object || parent_from_relation || parent_from_id
    end
  end

  def has_parent?
    !parent_relation.nil?
  end

  def reload(*args)
    @parent_object = nil
    # The is_leaf resetting stems fro typed_dag_defaults.rb where it was impossible to add
    # another #reload method without interfering with the virtual attribute handling defined here.
    reset_is_leaf

    super
  end

  def parent_id=(id)
    id = id.to_i > 0 ? id.to_i : nil

    super(id)
    @parent_object = nil if @parent_object && @parent_object.id != id

    @parent_id
  end

  def parent_id
    return @parent_id if @parent_id_set

    @parent_id || parent&.id
  end

  def update_parent_relation
    parent_relation&.destroy

    if parent_object
      create_parent_relation from: parent_object
    elsif @parent_id
      create_parent_relation from_id: @parent_id
    end
  end

  private

  def parent_from_relation
    if parent_relation && ((@parent_id && parent_relation.from.id == @parent_id) || !@parent_id)
      set_virtual_attribute_was('parent_id', parent_relation.from_id)
      @parent_object = parent_relation.from
    end
  end

  def parent_from_id
    if @parent_id
      set_virtual_attribute_was('parent_id', @parent_id)
      @parent_object = WorkPackage.find(@parent_id)
    end
  end
end
