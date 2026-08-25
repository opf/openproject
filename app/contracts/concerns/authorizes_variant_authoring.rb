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

# Who may author a variant. A global one is instance configuration and stays with the
# administrators; one a project owns may also be authored from inside that project.
#
module AuthorizesVariantAuthoring
  extend ActiveSupport::Concern

  included do
    validate :validate_may_author_variant
  end

  def validate_may_author_variant
    return errors.add(:base, :error_unauthorized) unless user.active?
    return if user.admin?
    return if owning_project && user.allowed_in_project?(:manage_project_variants, owning_project)

    errors.add(:base, :error_unauthorized)
  end

  private

  def owning_project = model.project
end
