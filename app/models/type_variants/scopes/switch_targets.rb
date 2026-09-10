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

module TypeVariants::Scopes
  module SwitchTargets
    extend ActiveSupport::Concern

    class_methods do
      # The variants of the source's type a user may move a project onto. Deciding which variant a
      # project runs on goes with authoring its variants, not with choosing which types it uses.
      # Another project's variant is never among them.
      def switch_targets(user:, project:, source:)
        return none unless user.allowed_in_project?(:manage_project_variants, project)

        source.type.variants.available_in(project)
      end

      def switchable?(user:, project:, source:, target:)
        switch_targets(user:, project:, source:).exists?(id: target.id)
      end
    end
  end
end
