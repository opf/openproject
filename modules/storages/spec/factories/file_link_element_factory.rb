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

# Expects parameters: storage, container_id
FactoryBot.define do
  factory :file_link_element, class: Hash do
    sequence(:origin_id) { |n| "20000#{n}" } # ID within external storage (i.e. Nextcloud)
    sequence(:origin_name) { |n| "file_name_#{n}.txt" } # File name within external storage (i.e. Nextcloud)
    origin_mime_type { "text/plain" }
    origin_created_at { Time.zone.now }
    origin_updated_at { Time.zone.now }
    origin_created_by_name { "Peter Pan" }
    origin_last_modified_by_name { "Petra Panadera" }
    storage_url { "https://nextcloud.example.com" }

    trait :invalid do
      origin_id { " " }
    end

    initialize_with do
      origin_data = attributes.select { |key, _| key.starts_with?("origin_") }
                              .transform_keys { |key| key.to_s.gsub("origin_", "").camelcase(:lower).to_sym }
                              .then { |data| data.transform_values { |v| v.respond_to?(:iso8601) ? v.iso8601 : v } }
                              .then { |data| data.transform_keys { |k| k.to_sym == :updatedAt ? :lastModifiedAt : k } }
      {
        originData: origin_data,
        _links: {
          storageUrl: {
            href: attributes[:storage_url]
          }
        }
      }
    end
  end
end
