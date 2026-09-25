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

class Project::PhaseDefinition < ApplicationRecord
  include ::Scopes::Scoped
  include Lists::MoveAfterAnchor

  has_many :phases,
           class_name: "Project::Phase",
           foreign_key: :definition_id,
           inverse_of: :definition,
           dependent: :destroy
  has_many :projects, through: :phases
  belongs_to :color, optional: false
  has_many :work_packages, inverse_of: :project_phase_definition, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :start_gate_name, presence: true, if: :start_gate?
  validates :finish_gate_name, presence: true, if: :finish_gate?
  acts_as_list

  default_scope { order(:position) }

  scopes :with_project_count

  def to_s; name end
end
