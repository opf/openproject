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

class RemoveNonNullContainerOnAttachments < ActiveRecord::Migration[5.1]
  def change
    change_column_null :attachments, :container_id, true
    change_column_null :attachments, :container_type, true

    change_column_default :attachments, :container_id, from: 0, to: nil
    change_column_default :attachments, :container_type, from: '', to: nil

    change_column_null :attachment_journals, :container_id, true
    change_column_null :attachment_journals, :container_type, true

    change_column_default :attachment_journals, :container_id, from: 0, to: nil
    change_column_default :attachment_journals, :container_type, from: '', to: nil

    add_column :attachments, :updated_at, :datetime
    rename_column :attachments, :created_on, :created_at

    reversible do |change|
      change.up { Attachment.update_all("updated_at = created_at") }
    end
  end
end
