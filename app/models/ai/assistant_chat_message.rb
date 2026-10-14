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

module AI
  # A question of the user, or an answer of the model. An answer can carry proposals
  # (AI::AssistantProposal), each applied or dismissed on its own.
  class AssistantChatMessage < ApplicationRecord
    include AI::EventLog

    belongs_to :chat, class_name: "AI::AssistantChat", inverse_of: :messages
    has_many :proposals, -> { ordered },
             class_name: "AI::AssistantProposal", foreign_key: :message_id, inverse_of: :message, dependent: :delete_all

    enum :role, { user: "user", assistant: "assistant" }, validate: true, prefix: :from
    enum :status, { pending: "pending", done: "done", failed: "failed" }, default: "done", validate: true

    validates :content, presence: true, if: :from_user?
  end
end
