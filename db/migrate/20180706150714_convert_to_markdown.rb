#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class ConvertToMarkdown < ActiveRecord::Migration[5.1]
  def up
    setting = Setting.where(name: 'text_formatting').pluck(:value)
    return unless setting && setting[0] == 'textile'

    if ENV['OPENPROJECT_SKIP_TEXTILE_MIGRATION'].present?
      warn <<~WARNING
        Your instance is configured with Textile text formatting, this means you have likely been running OpenProject before 8.0.0

        Since you have requested skip the textile migration, your data will NOT be converted. You can do this in a subsequent step:

        $> bundle exec rails runner "OpenProject::TextFormatting::Formats::Markdown::TextileConverter.new.run!"

        or in a packaged installation:

        $> openproject run bundle exec rails runner "OpenProject::TextFormatting::Formats::Markdown::TextileConverter.new.run!"

        For more information, please visit this page: https://www.openproject.org/textile-to-markdown-migration

        WARNING
      return
    end

    if setting && setting[0] == 'textile'
      converter = OpenProject::TextFormatting::Formats::Markdown::TextileConverter.new
      converter.run!
    end

    Setting.where(name: %w(text_formatting use_wysiwyg)).delete_all
  end
end
