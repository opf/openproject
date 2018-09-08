#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

require 'model_contract'

module Queries
  class BaseContract < ::ModelContract
    attribute :name

    attribute :project_id
    attribute :is_public # => public
    attribute :display_sums # => sums
    attribute :timeline_visible
    attribute :timeline_zoom_level
    attribute :timeline_labels
    attribute :highlighting_mode
    attribute :show_hierarchies

    attribute :column_names # => columns
    attribute :filters

    attribute :sort_criteria # => sortBy
    attribute :group_by # => groupBy

    def self.model
      Query
    end

    attr_reader :user

    def initialize(query, user)
      super(query, user)

      @user = user
    end

    def validate
      validate_project
      user_allowed_to_make_public

      super
    end

    def validate_project
      errors.add :project, :error_not_found if project_id.present? && !project_visible?
    end

    def project_visible?
      Project.visible(user).where(id: project_id).exists?
    end

    def user_allowed_to_make_public
      return if model.project_id.present? && model.project.nil?

      if is_public && may_not_manage_queries?
        errors.add :public, :error_unauthorized
      end
    end

    def may_not_manage_queries?
      !user.allowed_to?(:manage_public_queries, model.project, global: model.project.nil?)
    end
  end
end
