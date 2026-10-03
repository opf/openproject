# frozen_string_literal: true

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

module Collaboration
  module Collaborative
    extend ActiveSupport::Concern

    included do
      class_attribute :collaboration_options, instance_writer: false
    end

    class_methods do
      def collaborative_content(view_permission:, edit_permission:, api_path:)
        self.collaboration_options = { view_permission:, edit_permission:, api_path: }.freeze
      end
    end

    def collaboration_api_path
      ::API::V3::Utilities::PathHelper::ApiV3Path.public_send(collaboration_options[:api_path], id)
    end

    def collaboration_resource_url
      URI.join(OpenProject::StaticRouting::StaticUrlHelpers.new.root_url, collaboration_api_path).to_s
    end

    def collaboration_viewable_by?(user)
      user.allowed_in_project?(collaboration_options[:view_permission], project)
    end

    def collaboration_editable_by?(user)
      user.allowed_in_project?(collaboration_options[:edit_permission], project)
    end

    def collaboration_readonly_for?(user)
      collaboration_viewable_by?(user) && !collaboration_editable_by?(user)
    end
  end
end
