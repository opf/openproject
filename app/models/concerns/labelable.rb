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

module Labelable
  extend ActiveSupport::Concern

  MAX_LABEL_NAMES_PER_SAVE = 50

  included do
    has_many :labelings, as: :labelable, dependent: :delete_all
    has_many :labels, -> { order(:id) }, through: :labelings

    scope :labeled_with, ->(label) { joins(:labelings).where(labelings: { label_id: label }) }
    scope :without_labels, -> { where.not(id: Labeling.where(labelable_type: polymorphic_name).select(:labelable_id)) }

    before_save :abort_save_with_label_names
    after_save :persist_label_associations

    validate :validate_label_id_replacements
  end

  attr_reader :label_id_replacements, :label_name_replacements

  def label_id_replacements=(new_labels)
    @label_id_replacements = new_labels.nil? ? nil : normalize_label_ids(new_labels)
  end

  def label_name_replacements=(names)
    @label_name_replacements = names.nil? ? nil : normalize_label_names(names)
  end

  def replace_label_names_with_ids(ids)
    self.label_id_replacements = label_ids_to_assign | ids
    self.label_name_replacements = nil
  end

  def override_labels? = !label_id_replacements.nil? || !label_name_replacements.nil?

  def effective_labels
    return labels unless override_labels?

    Label.where(id: label_ids_to_assign).order(:id).to_a + labels_for_names_to_assign
  end

  def label_changes
    return {} unless override_labels?
    return {} if label_ids_to_assign.sort == label_ids.sort && label_names_to_assign.empty?

    { "labels" => [label_ids, label_ids_to_assign + label_names_to_assign] }
  end

  private

  def label_ids_to_assign = Array(label_id_replacements)

  def label_names_to_assign = Array(label_name_replacements)

  def normalize_label_ids(new_labels)
    Array.wrap(new_labels)
         .filter_map { |label| label.respond_to?(:id) ? label.id : label.to_s.presence&.to_i }
         .uniq
  end

  def normalize_label_names(names)
    Array.wrap(names).map { it.to_s.squish }.compact_blank.uniq(&:downcase)
  end

  def labels_for_names_to_assign
    existing = Label.named_any(label_names_to_assign).index_by { it.name.downcase }

    label_names_to_assign.map { |name| existing[name.downcase] || Label.new(name:) }
  end

  def validate_label_id_replacements
    return unless override_labels?

    missing = label_ids_to_assign - Label.where(id: label_ids_to_assign).pluck(:id)

    errors.add(:labels, :does_not_exist) if missing.any?
  end

  def abort_save_with_label_names
    return if label_names_to_assign.empty?

    errors.add(:labels, :invalid)
    throw :abort
  end

  def persist_label_associations
    replace_labels(label_ids_to_assign) if override_labels?

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
