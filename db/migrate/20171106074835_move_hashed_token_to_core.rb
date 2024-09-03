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

class MoveHashedTokenToCore < ActiveRecord::Migration[5.1]
  class OldToken < ApplicationRecord
    self.table_name = :plaintext_tokens
  end

  def up
    rename_table :tokens, :plaintext_tokens
    create_tokens_table
    migrate_existing_tokens
  end

  def down
    drop_table :tokens
    rename_table :plaintext_tokens, :tokens
  end

  private

  def create_tokens_table
    create_table :tokens, id: :integer do |t|
      t.references :user, index: true
      t.string :type
      t.string :value, default: "", null: false, limit: 128
      t.datetime :created_on, null: false
      t.datetime :expires_on, null: true
    end
  end

  def migrate_existing_tokens
    # API tokens
    ::Token::API.transaction do
      OldToken.where(action: "api").find_each do |token|
        result = ::Token::API.create(user_id: token.user_id, value: ::Token::API.hash_function(token.value))
        warn "Failed to migrate API token for ##{user.id}" unless result
      end
    end

    # RSS tokens
    ::Token::RSS.transaction do
      OldToken.where(action: "feeds").find_each do |token|
        result = ::Token::RSS.create(user_id: token.user_id, value: token.value)
        warn "Failed to migrate RSS token for ##{user.id}" unless result
      end
    end

    # We do not migrate the rest, they are short-lived anyway.
  end
end
