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

require 'model_contract'

module Relations
  class BaseContract < ::ModelContract
    attribute :relation_type
    attribute :delay
    attribute :description
    attribute :from
    attribute :to

    validate :manage_relations_permission?
    validate :validate_from_exists
    validate :validate_to_exists
    validate :validate_only_one_follow_direction_between_hierarchies

    attr_reader :user

    def self.model
      Relation
    end

    def initialize(relation, user)
      super relation

      @user = user
    end

    def validate!(*args)
      # same as before_validation callback
      model.send(:reverse_if_needed)
      super
    end

    private

    def validate_from_exists
      errors.add :from, :error_not_found unless visible_work_packages.exists? model.from_id
    end

    def validate_to_exists
      errors.add :to, :error_not_found unless visible_work_packages.exists? model.to_id
    end

    def validate_only_one_follow_direction_between_hierarchies
      return unless [Relation::TYPE_HIERARCHY, Relation::TYPE_FOLLOWS].include? model.relation_type

      if follow_relations_in_oposite_direction.exists?
        errors.add :base, I18n.t(:'activerecord.errors.messages.circular_dependency')
      end
    end

    def manage_relations_permission?
      if !manage_relations?
        errors.add :base, :error_unauthorized
      end
    end

    def visible_work_packages
      ::WorkPackage.visible(user)
    end

    def manage_relations?
      user.allowed_to? :manage_work_package_relations, model.from.project
    end

    def follow_relations_in_oposite_direction
      from_set = hierarchy_or_follows_of(model.from)
      to_set = hierarchy_or_follows_of(model.to).where('follows > 0')

      from_set.where(to_id: to_set.select(:to_id))
    end

    def hierarchy_or_follows_of(work_package)
      root_id = Relation.to_root(work_package).select(:from_id)
      Relation.hierarchy_or_follows.where(from_id: root_id)
    end
  end
end
