#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Status < ActiveRecord::Base
  extend Pagination::Model

  default_scope { order('position ASC') }
  before_destroy :check_integrity
  has_many :workflows, foreign_key: 'old_status_id'
  acts_as_list

  belongs_to :color, class_name:  'Color', foreign_key: 'color_id'

  before_destroy :delete_workflows

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, maximum: 30
  validates_inclusion_of :default_done_ratio, in: 0..100, allow_nil: true

  after_save :unmark_old_default_value, if: :is_default?

  def unmark_old_default_value
    Status.where(['id <> ?', id]).update_all("is_default=#{self.class.connection.quoted_false}")
  end

  # Returns the default status for new issues
  def self.default
    where_default.first
  end

  def self.where_default
    where(['is_default=?', true])
  end

  # Update all the +Issues+ setting their done_ratio to the value of their +Status+
  def self.update_work_package_done_ratios
    if WorkPackage.use_status_for_done_ratio?
      Status.where(['default_done_ratio >= 0']).each do |status|
        WorkPackage
          .where(['status_id = ?', status.id])
          .update_all(['done_ratio = ?', status.default_done_ratio])
      end
    end

    WorkPackage.use_status_for_done_ratio?
  end

  # Returns an array of all statuses the given role can switch to
  def new_statuses_allowed_to(roles, type, author = false, assignee = false)
    self.class.new_statuses_allowed(self, roles, type, author, assignee)
  end

  def self.new_statuses_allowed(status, roles, type, author = false, assignee = false)
    if roles.present? && type.present?
      status_id = status.try(:id) || 0

      workflows = Workflow
                  .from_status(status_id,
                               type.id,
                               roles.map(&:id),
                               author,
                               assignee)

      Status.where(id: workflows.select(:new_status_id))
    else
      Status.where('1 = 0')
    end
  end

  def self.order_by_position
    order(:position)
  end

  def <=>(status)
    position <=> status.position
  end

  def to_s; name end

  private

  def check_integrity
    raise "Can't delete status" if WorkPackage.where(status_id: id).exists?
  end

  # Deletes associated workflows
  def delete_workflows
    Workflow
      .where(old_status_id: id)
      .or(Workflow.where(new_status_id: id))
      .delete_all
  end
end
