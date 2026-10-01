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

module Labelable
  extend ActiveSupport::Concern

  included do
    has_many :labelings, as: :labelable, dependent: :delete_all
    has_many :labels, -> { order(:id) }, through: :labelings

    scope :labeled_with, ->(label) { joins(:labelings).where(labelings: { label_id: label }) }

    after_save :persist_label_associations

    validate :validate_label_id_replacements
  end

  attr_reader :label_id_replacements

  def label_id_replacements=(new_labels)
    @label_id_replacements = new_labels.nil? ? nil : normalize_label_ids(new_labels)
  end

  def override_labels? = !label_id_replacements.nil?

  def effective_labels
    return labels unless override_labels?

    Label.where(id: label_id_replacements).order(:id)
  end

  def label_changes
    return {} unless override_labels?
    return {} if label_id_replacements.sort == label_ids.sort

    { "labels" => [label_ids, label_id_replacements] }
  end

  private

  def normalize_label_ids(new_labels)
    Array.wrap(new_labels)
         .filter_map { |label| label.respond_to?(:id) ? label.id : label.to_s.presence&.to_i }
         .uniq
  end

  def validate_label_id_replacements
    return unless override_labels?

    missing = label_id_replacements - Label.where(id: label_id_replacements).pluck(:id)

    errors.add(:labels, :does_not_exist) if missing.any?
  end

  def persist_label_associations
    replace_labels(label_id_replacements) if override_labels?

    self.label_id_replacements = nil
  end

  def replace_labels(new_label_ids)
    existing = labelings.pluck(:label_id)

    to_remove = existing - new_label_ids
    to_add    = new_label_ids - existing

    return if to_remove.empty? && to_add.empty?

    labelings.where(label_id: to_remove).delete_all if to_remove.any?
    labelings.insert_all(to_add.map { |id| { label_id: id } }) if to_add.any?

    reset_label_associations
  end

  def reset_label_associations
    labelings.reset
    labels.reset
  end
end
