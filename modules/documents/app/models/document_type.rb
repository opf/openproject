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

class DocumentType < ApplicationRecord
  include ::Documents::EnumerationModel

  default_scope { order(:position) }
  acts_as_list

  has_many :documents, foreign_key: :type_id,
                       dependent: :nullify,
                       inverse_of: :type

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  before_destroy :prevent_deletion_of_last_type

  def self.default
    where(is_default: true).first || first
  end

  def only_remaining_record?
    self.class.where.not(id: id).none?
  end

  alias :destroy_without_reassign :destroy

  def destroy(reassign_to = nil)
    if reassign_to.is_a?(DocumentType)
      transfer_relations(reassign_to)
    end
    destroy_without_reassign
  end

  private

  def prevent_deletion_of_last_type
    if only_remaining_record?
      errors.add(:base, :one_or_more_required)
      throw(:abort)
    end
  end

  def transfer_relations(to)
    documents.update_all(type_id: to.id)
    to.update_column(:documents_count, to.documents.count)
  end
end
