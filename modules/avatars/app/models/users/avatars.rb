# OpenProject Avatars plugin
#
# Copyright (C) the OpenProject GmbH
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

module Users
  module Avatars
    extend ActiveSupport::Concern

    included do
      acts_as_attachable view_permission: :view_users,
                         add_on_new_permission: :manage_user,
                         add_on_persisted_permission: :manage_user,
                         delete_permission: :manage_user
    end

    class_methods do
      def get_local_avatar(user_id)
        Attachment.find_by(container_id: user_id, container_type: "Principal", description: "avatar")
      end
    end

    def reload(*args)
      reset_avatar_attachment_cache!

      super
    end

    def local_avatar_attachment
      defined?(@local_avatar_attachment) || begin
        @local_avatar_attachment = attachments.find_by(description: "avatar")
      end

      @local_avatar_attachment
    end

    def local_avatar_attachment=(file)
      local_avatar_attachment&.destroy
      reset_avatar_attachment_cache!

      @local_avatar_attachment = Attachments::CreateService
        .new(user: User.system, contract_class: EmptyContract)
        .call(file:, container: self, filename: file.original_filename, description: "avatar")
        .result

      touch
    end

    def reset_avatar_attachment_cache!
      @local_avatar_attachment = nil
    end
  end
end
