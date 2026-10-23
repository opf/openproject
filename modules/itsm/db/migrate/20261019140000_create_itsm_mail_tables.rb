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

class CreateITSMMailTables < ActiveRecord::Migration[8.1]
  def change
    create_mail_servers
    create_mailboxes
    create_email_threads
    create_email_messages
  end

  private

  def create_mail_servers
    create_table :itsm_mail_servers do |t|
      t.string :name, null: false

      t.string :imap_host, null: false
      t.integer :imap_port, null: false
      t.string :imap_encryption, null: false

      t.string :smtp_host, null: false
      t.integer :smtp_port, null: false
      t.string :smtp_encryption, null: false

      t.timestamps

      t.index "lower(name)", unique: true, name: "index_itsm_mail_servers_on_lower_name"
    end
  end

  def create_mailboxes # rubocop:disable Metrics/AbcSize
    create_table :itsm_mailboxes do |t|
      t.references :mail_server, null: false, index: false,
                                 foreign_key: { to_table: :itsm_mail_servers, on_delete: :restrict }
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.string :email, null: false, index: { unique: true }
      t.text :aliases, array: true, null: false, default: []
      t.string :sender_name

      t.string :imap_username, null: false
      t.text :imap_password, null: false

      t.string :smtp_username, null: false
      t.text :smtp_password, null: false

      t.boolean :active, null: false, default: true
      t.datetime :last_fetched_at
      t.datetime :next_fetch_at
      t.integer :consecutive_failures, null: false, default: 0
      t.text :last_error
      t.timestamps

      t.index "mail_server_id, lower(imap_username)", unique: true, name: "index_itsm_mailboxes_on_server_and_imap_username"
    end
  end

  def create_email_threads
    create_table :itsm_email_threads do |t|
      t.references :work_package, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.references :mailbox, foreign_key: { to_table: :itsm_mailboxes, on_delete: :nullify }
      t.string :requester_email, null: false
      t.string :requester_name
      t.text :recipients, array: true, null: false, default: []
      t.timestamps
    end
  end

  def create_email_messages # rubocop:disable Metrics/AbcSize
    create_table :itsm_email_messages do |t|
      t.references :mailbox, index: false, foreign_key: { to_table: :itsm_mailboxes, on_delete: :nullify }
      t.references :thread, foreign_key: { to_table: :itsm_email_threads, on_delete: :cascade }
      t.references :journal, foreign_key: { on_delete: :nullify }
      t.string :direction, null: false
      t.string :status, null: false
      t.string :message_id, null: false
      t.string :in_reply_to
      t.text :referenced_message_ids, array: true, null: false, default: []
      t.string :from_address, null: false
      t.string :from_name
      t.text :to_addresses, array: true, null: false, default: []
      t.text :cc_addresses, array: true, null: false, default: []
      t.string :subject
      t.text :error_message
      t.timestamps

      t.index %i[mailbox_id message_id], unique: true
    end
  end
end
