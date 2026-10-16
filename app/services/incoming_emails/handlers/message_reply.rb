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
module IncomingEmails::Handlers
  class MessageReply < Base
    # Override in subclasses to determine if this handler can process the email
    def self.handles?(_email, reference:, automated_email:)
      !automated_email && reference[:klass] == "message"
    end

    # Override in subclasses to process the email
    def process
      receive_message_reply(reference[:id])
    end

    private

    # Receives a reply to a forum message
    def receive_message_reply(message_id)
      message = Message.find_by(id: message_id)
      if message
        message = message.root

        if !options[:no_permission_check] && !user.allowed_in_project?(:add_messages, message.project)
          raise ::IncomingEmails::UnauthorizedAction
        end

        if message.locked?
          ServiceResult.failure(message: "ignoring reply from [#{sender_email}] to a locked topic",
                                mesage_type: :warn)
        else
          create_reply_message(message)
        end
      end
    end

    def create_reply_message(root)
      reply = Message.new(subject: email.subject.gsub(%r{^.*msg\d+\]}, "").strip,
                          content: cleaned_up_text_body)
      reply.author = user
      reply.forum = root.forum
      root.children << reply
      add_attachments(reply)
      reply

      ServiceResult.success(result: reply,
                            message: "Reply added to message ##{root.id}")
    end
  end
end
