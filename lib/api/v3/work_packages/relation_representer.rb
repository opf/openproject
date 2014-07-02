#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

require 'roar/decorator'
require 'roar/representer/json/hal'

module API
  module V3
    module WorkPackages
      class RelationRepresenter < Roar::Decorator
        include Roar::Representer::JSON::HAL
        include Roar::Representer::Feature::Hypermedia
        include ::Rails.application.routes.url_helpers

        self.as_strategy = API::Utilities::CamelCasingStrategy.new

        property :_type, exec_context: :decorator

        # link :self do
        #  { href: "#{root_url}/api/v3/relationships/#{represented.id}", title: "#{represented.type}" }
        # end

        # link :workPackage do
        #  { href: "#{root_url}/api/v3/work_packages/#{represented.related.id}", title: "#{represented.related.subject}" }
        # end

        link :relatedWorkPackage do
          { href: "#{root_url}/api/v3/work_packages/#{represented.related.id}", title: "#{represented.related.subject}" }
        end

        property :id,   render_nil: true
        property :type, render_nil: true

        property :related_work_package_id,         getter: -> (*) { related.id }, render_nil: true
        property :related_work_package_subject,    getter: -> (*) { related.subject }, render_nil: true
        property :related_work_package_type,       getter: -> (*) { related.type.try(:name) }, render_nil: true
        property :related_work_package_start_date, getter: -> (*) { related.start_date }, render_nil: true
        property :related_work_package_due_date,   getter: -> (*) { related.due_date }, render_nil: true

        def _type
          'Relationship'
        end

        private

          def default_url_options
            ActionController::Base.default_url_options
          end
      end
    end
  end
end
