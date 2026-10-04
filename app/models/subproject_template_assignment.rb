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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class SubprojectTemplateAssignment < ApplicationRecord
  belongs_to :project, inverse_of: :subproject_template_assignments
  belongs_to :template, class_name: "Project"

  enum :workspace_type, {
    project: "project",
    program: "program"
  }, validate: true

  validates :project_id, presence: true
  validates :template_id, presence: true
  validates :workspace_type, presence: true
  validates :project_id, uniqueness: { scope: :workspace_type }

  validate :template_must_be_templated

  private

  def template_must_be_templated
    return if template.blank?

    unless template.templated?
      errors.add(:template, :must_be_template)
    end
  end
end
