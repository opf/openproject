#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

class Document < ApplicationRecord
  belongs_to :project
  belongs_to :category, class_name: "DocumentCategory", foreign_key: "category_id"
  acts_as_attachable delete_permission: :manage_documents,
                     add_permission: :manage_documents

  acts_as_journalized
  acts_as_event title: Proc.new { |o| "#{Document.model_name.human}: #{o.title}" },
                url: Proc.new { |o| { controller: '/documents', action: 'show', id: o.id } },
                datetime: :created_at,
                author: ( Proc.new do |o|
                            o.attachments.find(:first, order: "#{Attachment.table_name}.created_at ASC").try(:author)
                          end)

  acts_as_searchable columns: ['title', "#{table_name}.description"],
                     include: :project,
                     references: :projects,
                     date_column: "#{table_name}.created_at"

  validates_presence_of :project, :title, :category
  validates_length_of :title, maximum: 60

  scope :visible, ->(user = User.current) {
    includes(:project)
      .references(:projects)
      .merge(Project.allowed_to(user, :view_documents))
  }

  scope :with_attachments, lambda {
    includes(:attachments)
      .where('attachments.container_id is not NULL')
      .references(:attachments)
  }

  after_initialize :set_default_category
  after_create :notify_document_created

  def visible?(user=User.current)
    !user.nil? && user.allowed_to?(:view_documents, project)
  end

  def set_default_category
    self.category ||= DocumentCategory.default if new_record?
  end

  def updated_on
    unless @updated_on
      # attachments has a default order that conflicts with `created_at DESC`
      # #reorder removes that default order but rather than #unscoped keeps the
      # scoping by this document
      a = attachments.reorder(Arel.sql('created_at DESC')).first
      @updated_on = (a && a.created_at) || created_at
    end
    @updated_on
  end

  private

  def notify_document_created
    return unless Setting.notified_events.include?('document_added')

    recipients.each do |user|
      DocumentsMailer.document_added(user, self).deliver_now
    end
  end
end
