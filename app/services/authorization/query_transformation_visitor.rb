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

# rubocop:disable Naming/MethodName

class Authorization::QueryTransformationVisitor < Arel::Visitors::Visitor
  attr_accessor :transformations,
                :args

  def initialize(transformations:,
                 args:)
    self.transformations = transformations
    self.args = args

    super()
  end

  def accept(ast)
    applied_transformations.clear

    super
  end

  private

  def visit_Arel_SelectManager(ast)
    ast = replace_if_equals(ast, :all)

    ast.join_sources.each do |join_source|
      visit join_source
    end
  end

  def visit_Arel_Nodes_OuterJoin(ast)
    visit ast.right
  end

  def visit_Arel_Nodes_On(ast)
    ast.expr = replace_if_equals(ast.expr)

    visit ast.expr
  end

  def visit_Arel_Nodes_Grouping(ast)
    ast.expr = replace_if_equals(ast.expr)

    visit ast.expr
  end

  def visit_Arel_Nodes_Or(ast)
    ast.left = replace_if_equals(ast.left)

    visit ast.left

    ast.right = replace_if_equals(ast.right)

    visit ast.right
  end

  def visit_Arel_Nodes_And(ast)
    ast.children.each_with_index do |_, i|
      ast.children[i] = replace_if_equals(ast.children[i])

      visit ast.children[i]
    end
  end

  def method_missing(name, *args, &)
    super unless name.to_s.start_with?("visit_")
  end

  def replace_if_equals(ast, key = nil)
    if applicable_transformation?(key || ast)
      transformations.for(key || ast).each do |transformation|
        ast = transformation.apply(ast, *args)
      end
    end

    ast
  end

  def applicable_transformation?(key)
    if transformations.for?(key) && !applied_transformations.include?(key)
      applied_transformations << key

      true
    else
      false
    end
  end

  def applied_transformations
    @applied_transformations ||= []
  end
end
