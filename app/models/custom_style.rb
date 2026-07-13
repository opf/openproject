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

require "ttfunk"

class CustomStyle < ApplicationRecord
  mount_uploader :logo, OpenProject::Configuration.file_uploader
  mount_uploader :logo_mobile, OpenProject::Configuration.file_uploader
  mount_uploader :export_logo, OpenProject::Configuration.file_uploader
  mount_uploader :export_cover, OpenProject::Configuration.file_uploader
  mount_uploader :export_footer, OpenProject::Configuration.file_uploader
  mount_uploader :favicon, OpenProject::Configuration.file_uploader
  mount_uploader :touch_icon, OpenProject::Configuration.file_uploader
  mount_uploader :export_font_regular, OpenProject::Configuration.file_uploader
  mount_uploader :export_font_bold, OpenProject::Configuration.file_uploader
  mount_uploader :export_font_italic, OpenProject::Configuration.file_uploader
  mount_uploader :export_font_bold_italic, OpenProject::Configuration.file_uploader

  class << self
    def current
      RequestStore.fetch(:current_custom_style) do
        custom_style = CustomStyle.order(Arel.sql("created_at DESC")).first
        if custom_style.nil?
          return nil
        else
          custom_style
        end
      end
    end
  end

  def digest
    updated_at.to_i
  end

  %i(favicon touch_icon export_logo export_cover export_footer logo logo_mobile
     export_font_regular export_font_bold export_font_italic export_font_bold_italic).each do |name|
    define_method :"#{name}_path" do
      attachment = send(name)

      if attachment.readable?
        attachment.local_file.path
      end
    end

    define_method :"remove_#{name}!" do
      super()
      save!
    end
  end
end
