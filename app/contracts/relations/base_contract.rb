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
    validate :validate_nodes_relatable
    validate :validate_accepted_type

    def self.model
      Relation
    end

    private

    def validate_from_exists
      errors.add :from, :error_not_found unless visible_work_packages.exists? model.from_id
    end

    def validate_to_exists
      errors.add :to, :error_not_found unless visible_work_packages.exists? model.to_id
    end

    def validate_nodes_relatable
      if (model.from_id_changed? || model.to_id_changed?) &&
         WorkPackage.relatable(model.from, model.relation_type, ignored_relation: model).where(id: model.to_id).empty?
        errors.add :base, I18n.t(:'activerecord.errors.messages.circular_dependency')
      end
    end

    def validate_accepted_type
      return if (Relation::TYPES.keys + [Relation::TYPE_PARENT]).include?(model.relation_type)

      errors.add :relation_type, :inclusion
    end

    def manage_relations_permission?
      unless manage_relations?
        errors.add :base, :error_unauthorized
      end
    end

    def visible_work_packages
      ::WorkPackage.visible(user)
    end

    def manage_relations?
      user.allowed_in_work_package?(:manage_work_package_relations, model.from)
    end
  end
end
