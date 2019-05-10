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

module Versions
  class BaseContract < ::ModelContract
    def self.model
      Version
    end

    def validate
      user_allowed_to_manage
      validate_project_is_set
      validate_sharing_included

      super
    end

    attribute :project_id
    attribute :name
    attribute :description
    attribute :start_date
    attribute :effective_date
    attribute :status
    attribute :sharing
    attribute :wiki_page_title

    private

    def validate_sharing_included
      if model.sharing_changed? && !model.allowed_sharings(user).include?(model.sharing)
        errors.add :sharing, :inclusion
      end
    end

    def user_allowed_to_manage
      if model.project && !user.allowed_to?(:manage_versions, model.project)
        errors.add :base, :error_unauthorized
      end
    end

    def validate_project_is_set
      errors.add :project_id, :blank if model.project.nil?
    end
  end
end
