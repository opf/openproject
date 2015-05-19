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

require 'api/v3/relations/relation_representer'

module API
  module V3
    module Relations
      class RelationsAPI < ::API::OpenProjectAPI
        resources :relations do
          params do
            optional :to_id, desc: 'Id of related work package'
            optional :relation_type, desc: 'Type of relationship'
            optional :delay
          end
          post do
            authorize(:manage_work_package_relations, context: @work_package.project)
            declared_params = declared(params).reject { |key, value| key.to_sym == :id || value.nil? }

            relation = @work_package.new_relation.tap do |r|
              r.to = WorkPackage.visible.find_by_id(declared_params[:to_id].match(/\d+/).to_s)
              r.relation_type = declared_params[:relation_type]
              r.delay = declared_params[:delay_id]
            end

            if relation.valid? && relation.save
              representer = RelationRepresenter.new(relation, work_package: relation.to)
              representer
            else
              fail ::API::Errors::Validation.new(I18n.t('api_v3.errors.invalid_relation'))
            end
          end

          route_param :relation_id do
            delete do
              authorize(:manage_work_package_relations, context: @work_package.project)
              Relation.destroy(params[:relation_id])
              status 204
            end
          end
        end
      end
    end
  end
end
