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

class RemoveDefaultValuesFromJournalTablesDefinition < ActiveRecord::Migration[7.0]
  # rubocop:disable Metrics/AbcSize
  def change
    change_table :attachable_journals, bulk: true do |t|
      t.change_default :filename, from: "", to: nil
    end

    change_table :attachment_journals, bulk: true do |t|
      t.change_default :filename, from: "", to: nil
      t.change_default :disk_filename, from: "", to: nil
      t.change_default :filesize, from: 0, to: nil
      t.change_default :content_type, from: "", to: nil
      t.change_default :digest, from: "", to: nil
      t.change_default :downloads, from: 0, to: nil
    end

    change_table :document_journals, bulk: true do |t|
      t.change_default :title, from: "", to: nil
    end

    change_table :message_journals, bulk: true do |t|
      t.change_default :subject, from: "", to: nil
      t.change_default :locked, from: false, to: nil
      t.change_default :sticky, from: 0, to: nil
    end

    change_table :news_journals, bulk: true do |t|
      t.change_default :title, from: "", to: nil
      t.change_default :summary, from: "", to: nil
      t.change_default :comments_count, from: 0, to: nil
    end

    change_table :work_package_journals, bulk: true do |t|
      t.change_default :subject, from: "", to: nil
      t.change_default :done_ratio, from: 0, to: nil
      t.change_default :schedule_manually, from: false, to: nil
    end
  end
  # rubocop:enable Metrics/AbcSize
end
