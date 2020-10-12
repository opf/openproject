# OpenProject Avatars plugin
#
# Copyright (C) 2017  OpenProject GmbH
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

module OpenProject::Avatars
  module Patches
    module UserPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          acts_as_attachable

          include InstanceMethods

          class << self
            def get_local_avatar(user_id)
              Attachment.find_by(container_id: user_id, container_type: 'Principal', description: 'avatar')
            end
          end
        end
      end

      module InstanceMethods
        def reload(*args)
          reset_avatar_attachment_cache!

          super
        end

        def local_avatar_attachment
          # @local_avatar_attachment can legitimately be nil which is why the
          # typical
          # inst_var ||= calculation
          # pattern does not work for caching
          return @local_avatar_attachment if @local_avatar_attachment_calculated

          @local_avatar_attachment_calculated ||= begin
                                                    @local_avatar_attachment = attachments.find_by_description('avatar')

                                                    true
                                                  end

          @local_avatar_attachment
        end

        def local_avatar_attachment=(file)
          local_avatar_attachment&.destroy
          reset_avatar_attachment_cache!

          attach_files('first' => { 'file' => file, 'description' => 'avatar' })
          save
        end

        def reset_avatar_attachment_cache!
          @local_avatar_attachment = nil
          @local_avatar_attachment_calculated = nil
        end
      end
    end
  end
end
