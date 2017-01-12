#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

FactoryGirl.define do
  factory :menu_item do
    sequence(:name) do |n| "Item No. #{n}" end
    sequence(:title) do |n| "Menu item Title #{n}" end

    factory :wiki_menu_item, class: MenuItems::WikiMenuItem do
      wiki

      sequence(:title) do |n| "Wiki Title #{n}" end

      trait :with_menu_item_options do
        index_page true
        new_wiki_page true
      end

      factory :wiki_menu_item_with_parent do
        callback(:after_build) do |wiki_menu_item|
          parent = FactoryGirl.build(:wiki_menu_item, wiki: wiki_menu_item.wiki)
          wiki_menu_item.wiki.wiki_menu_items << parent
          wiki_menu_item.parent = parent
        end
      end
    end

    factory :query_menu_item, class: MenuItems::QueryMenuItem do
      query

      name do query.normalized_name end
      title do query.name end

      navigatable_id { query.id }
    end
  end
end
