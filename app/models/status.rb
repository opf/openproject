#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Status < ApplicationRecord
  default_scope { order_by_position }
  before_destroy :check_integrity
  has_many :workflows, foreign_key: 'old_status_id'
  acts_as_list

  belongs_to :color, class_name: 'Color'

  before_destroy :delete_workflows

  validates :name,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { maximum: 256 }

  validates :default_done_ratio, inclusion: { in: 0..100, allow_nil: true }

  validate :default_status_must_not_be_readonly

  after_save :unmark_old_default_value, if: :is_default?

  def unmark_old_default_value
    Status.where.not(id:).update_all(is_default: false)
  end

  # Returns the default status for new issues
  def self.default
    where_default.first
  end

  def self.where_default
    where(is_default: true)
  end

  # Update all the +Issues+ setting their done_ratio to the value of their +Status+
  def self.update_work_package_done_ratios
    if WorkPackage.use_status_for_done_ratio?
      Status.where(['default_done_ratio >= 0']).find_each do |status|
        WorkPackage
          .where(['status_id = ?', status.id])
          .update_all(['done_ratio = ?', status.default_done_ratio])
      end
    end

    WorkPackage.use_status_for_done_ratio?
  end

  def self.order_by_position
    order(:position)
  end

  def self.can_readonly?
    EnterpriseToken.allows_to?(:readonly_work_packages)
  end
  delegate :can_readonly?, to: :class

  def <=>(other)
    position <=> other.position
  end

  def to_s; name end

  def is_readonly
    return false unless can_readonly?

    super
  end
  alias :is_readonly? :is_readonly

  ##
  # Overrides cache key so that changes to EE state are reflected
  def cache_key
    super + '/' + can_readonly?.to_s
  end

  private

  def check_integrity
    raise "Can't delete status" if WorkPackage.where(status_id: id).exists?
  end

  def default_status_must_not_be_readonly
    if is_readonly? && is_default?
      errors.add(:is_readonly, :readonly_default_exlusive)
    end
  end

  # Deletes associated workflows
  def delete_workflows
    Workflow
      .where(old_status_id: id)
      .or(Workflow.where(new_status_id: id))
      .delete_all
  end
end
