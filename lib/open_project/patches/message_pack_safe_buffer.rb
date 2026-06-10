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

module OpenProject
  module Patches
    # Upstream fix: https://github.com/rails/rails/pull/57429 (merged, not yet released)
    #
    # Rails registers ActiveSupport::SafeBuffer as MessagePack ext type 18 with
    # packer: :to_s, unpacker: :new. Ext payload bytes are always BINARY, so
    # SafeBuffer.new(payload) reconstructs with ASCII-8BIT encoding, causing
    # Encoding::CompatibilityError when cached HTML is later concatenated into a
    # UTF-8 output buffer.
    #
    # The upstream fix switches to recursive: true with nested packer.write /
    # unpacker.read so the MessagePack string codec preserves the original
    # encoding across the round-trip.
    module MessagePackSafeBufferFix
      def register_type(type_id, klass = nil, **options, &)
        if klass == ActiveSupport::SafeBuffer
          options[:packer] = ->(buffer, packer) { packer.write(buffer.to_str) }
          options[:unpacker] = ->(unpacker) { ActiveSupport::SafeBuffer.new(unpacker.read) }
          options[:recursive] = true
        end

        super
      end
    end
  end
end

OpenProject::Patches.patch_gem_version "activesupport", "8.1.3" do
  MessagePack::Factory.prepend OpenProject::Patches::MessagePackSafeBufferFix
end
