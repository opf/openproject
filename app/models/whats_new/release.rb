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

module WhatsNew
  class Release
    Item = Data.define(:key, :title, :description, :url)

    attr_reader :major, :minor

    def self.current
      new(major: OpenProject::VERSION::MAJOR, minor: OpenProject::VERSION::MINOR)
    end

    def initialize(major:, minor:)
      @major = major
      @minor = minor
    end

    def version
      "#{major}.#{minor}"
    end

    def version_key
      "#{major}_#{minor}"
    end

    def features
      @features ||= items_from("#{i18n_scope}.new_features_list")
    end

    def items
      @items ||= items_from("#{i18n_scope}.whats_new.items").presence || features
    end

    def visible_to?(user)
      user.logged? && items.any?
    end

    def item?(key)
      items.any? { |item| item.key == key.to_s }
    end

    def video_url
      OpenProject::Static::Links.url_for(:release_videos, url_templates: { MAJOR: major, MINOR: minor })
    end

    def unread_keys(user)
      items.map(&:key) - user.pref.whats_new_read_keys(version_key)
    end

    def seen?(user)
      user.pref.whats_new_seen_version == version_key
    end

    private

    def i18n_scope
      "homescreen.blocks.new_features.#{version_key}"
    end

    def items_from(key)
      I18n.t(key, default: {}).map do |item_key, attributes|
        Item.new(key: item_key.to_s, title: attributes[:title], description: attributes[:description], url: attributes[:url])
      end
    end
  end
end
