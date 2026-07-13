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
module EnvData
  class CustomDesignSeeder < Seeder
    def seed_data!
      custom_style = CustomStyle.current || CustomStyle.create!

      print_status "    ↳ Setting custom design colors" do
        seed_colors
        seed_export_color(custom_style)
      end

      print_status "    ↳ Setting custom logos" do
        seed_logos(custom_style)
      end

      custom_style.save!
    end

    def applicable?
      Setting.seed_design.present?
    end

    private

    def seed_logos(custom_style)
      CustomStyle.uploaders.each_key do |key|
        data = Setting.seed_design[key.to_s]

        if data.blank?
          custom_style.public_send(:"remove_#{key}!")
        elsif data.match?(/^https?:\/\//)
          seed_remote_url(custom_style, key, data)
        else
          io = Base64StringIO.new(data, key.to_s)
          custom_style.public_send(:"#{key}=", io)
        end
      end
    end

    def seed_colors
      OpenProject::CustomStyles::Design.customizable_variables.each do |variable|
        key = variable.to_s.underscore
        value = Setting.seed_design[key]

        if value.blank?
          DesignColor.where(variable:).delete_all
        else
          design_color = DesignColor.find_or_initialize_by(variable:)
          design_color.hexcode = value
          design_color.save!
        end
      end
    end

    def seed_export_color(custom_style)
      value = Setting.seed_design["export_cover_text_color"]
      custom_style.export_cover_text_color = value.presence
    end

    def seed_remote_url(custom_style, key, url)
      custom_style.public_send(:"remote_#{key}_url=", url)
      custom_style.save!
    rescue StandardError => e
      Rails.logger.error "Failed to seed remote URL for design variable '#{key}': #{e.message}"
    end

    class Base64StringIO < StringIO
      attr_reader :filename

      def initialize(data_url, base_name)
        metadata, encoded = data_url.split(",")

        if metadata.blank? || encoded.blank? || !metadata.start_with?("data:")
          raise ArgumentError, "Expected data URL, got #{data_url}"
        end

        @filename = "#{base_name}.#{extension(metadata)}"
        bytes = ::Base64.strict_decode64(encoded)

        super(bytes)
      end

      def original_filename
        filename
      end

      def extension(metadata)
        content_type = metadata.match(%r{data:([^;]+)})&.captures&.first
        raise ArgumentError, "Failed to parse content type from metadata: #{metadata}" if content_type.nil?

        mime_type = MIME::Types[content_type].last
        raise ArgumentError, "Unknown mime type: #{content_type}" if mime_type.nil?

        mime_type.preferred_extension
      end
    end
  end
end
