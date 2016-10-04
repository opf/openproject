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

if Rails.gem_version > Gem::Version.new('5.0.0.1')
  raise <<-MESSAGE


  Patching active record is no longer necessary as rails/rails#3cffae5953021966204854fa73bef2f9cd366e9b is part of the used rails version now. Remove the patch in config/initializers/ar_readonly_patch.rb


  MESSAGE
end

module MacroReflectionPatch
  def scope_for(klass)
    scope ? klass.unscoped.instance_exec(nil, &scope) : klass.unscoped
  end
end

ActiveRecord::Reflection::MacroReflection.prepend(MacroReflectionPatch)
ActiveRecord::Reflection::ThroughReflection.prepend(MacroReflectionPatch)

module JoinDependencyPatch
  def construct(ar_parent, parent, row, rs, seen, model_cache, aliases)
    return if ar_parent.nil?

    parent.children.each do |node|
      if node.reflection.collection?
        other = ar_parent.association(node.reflection.name)
        other.loaded!
      elsif ar_parent.association_cached?(node.reflection.name)
        model = ar_parent.association(node.reflection.name).target
        construct(model, node, row, rs, seen, model_cache, aliases)
        next
      end

      key = aliases.column_alias(node, node.primary_key)
      id = row[key]
      if id.nil?
        nil_association = ar_parent.association(node.reflection.name)
        nil_association.loaded!
        next
      end

      model = seen[ar_parent.object_id][node.base_klass][id]

      if model
        construct(model, node, row, rs, seen, model_cache, aliases)
      else
        model = construct_model(ar_parent, node, row, model_cache, id, aliases)

        if node.reflection.scope_for(node.base_klass).readonly_value
          model.readonly!
        end

        seen[ar_parent.object_id][node.base_klass][id] = model
        construct(model, node, row, rs, seen, model_cache, aliases)
      end
    end
  end
end

ActiveRecord::Associations::JoinDependency.prepend(JoinDependencyPatch)

module PreloaderAssociationPatch
  def reflection_scope
    @reflection_scope ||= reflection.scope_for(klass)
  end
end

ActiveRecord::Associations::Preloader::Association.prepend(JoinDependencyPatch)
