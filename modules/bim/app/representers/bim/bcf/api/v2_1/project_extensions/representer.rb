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

module Bim::Bcf::API::V2_1
  class ProjectExtensions::Representer < BaseRepresenter
    property :topic_type,
             getter: ->(decorator:, **) {
               decorator.with_check do
                 assignable_types.pluck(:name)
               end
             }

    # TODO: Labels do not yet exist
    property :topic_label,
             getter: ->(*) {
               []
             }

    # TODO: Snippet types do not exist
    property :snippet_type,
             getter: ->(*) {
               []
             }

    property :priority,
             getter: ->(decorator:, **) {
               decorator.with_check do
                 assignable_priorities.pluck(:name)
               end
             }

    property :user_id_type,
             getter: ->(decorator:, **) {
               decorator.with_check(%i[manage_bcf view_members]) do
                 assignable_assignees.pluck(:mail)
               end
             }

    # TODO: Stage do not yet exist
    property :stage,
             getter: ->(*) {
               []
             }

    property :project_actions,
             getter: ->(decorator:, **) {
               [].tap do |actions|
                 actions << "update" if decorator.allowed?(:edit_project)

                 if decorator.allowed?(:manage_bcf)
                   actions << "viewTopic" << "createTopic"
                 elsif decorator.allowed?(:view_linked_issues)
                   actions << "viewTopic"
                 end
               end
             }

    property :comment_actions,
             getter: ->(*) {
               []
             }

    def to_hash(*)
      topic_authorization = ::Bim::Bcf::API::V2_1::Topics::AuthorizationRepresenter
                            .new(represented)

      super.merge(topic_authorization.to_hash)
    end

    def with_check(permissions = :manage_bcf)
      if Array(permissions).all? { |permission| allowed?(permission) }
        yield
      else
        []
      end
    end

    def allowed?(permission)
      represented.user.allowed_in_project?(permission, represented.model.project)
    end
  end
end
