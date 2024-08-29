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

module OpenProject::TextFormatting
  module Formats
    class << self
      attr_reader :plain, :rich

      %i(plain rich).each do |flavor|
        define_method(:"#{flavor}_format") do
          send(flavor).format
        end

        define_method(:"#{flavor}_formatter") do
          send(flavor).formatter
        end

        define_method(:"#{flavor}_helper") do
          send(flavor).helper
        end

        define_method(:"register_#{flavor}!") do |klass|
          instance_variable_set(:"@#{flavor}", klass)
        end
      end

      def supported?(name)
        [plain, rich].map(&:format).include?(name.to_sym)
      end

      def plain?(name)
        name && plain.format == name.to_sym
      end
    end
  end
end

OpenProject::TextFormatting::Formats.register_plain! OpenProject::TextFormatting::Formats::Plain::Format
OpenProject::TextFormatting::Formats.register_rich! OpenProject::TextFormatting::Formats::Markdown::Format
