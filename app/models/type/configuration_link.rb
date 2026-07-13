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

# A single reuse link: a type borrows one configuration aspect from a source type.
# Absence of a row for (type, aspect) means the type owns that aspect (Independent).
class Type::ConfigurationLink < ApplicationRecord
  ASPECTS = [
    PDF_EXPORT = "pdf_export",
    PATTERNS = "patterns",
    WORKFLOWS = "workflows",
    AUTOMATIONS = "automations",
    PROJECTS = "projects",
    FORM_CONFIGURATION = "form_configuration"
  ].freeze

  # Aspects a new sub-type inherits from its parent on creation. The remaining
  # aspects start Independent until their linked behaviour is implemented.
  SEEDED_ASPECTS = [PDF_EXPORT, PATTERNS].freeze

  belongs_to :type, optional: false
  belongs_to :source, class_name: "Type", optional: false

  enum :aspect, ASPECTS.index_with(&:itself), validate: true

  validates :type_id, uniqueness: { scope: :aspect }
  validate :source_differs_from_type

  private

  def source_differs_from_type
    errors.add(:source, :must_differ_from_type) if source_id.present? && source_id == type_id
  end
end
