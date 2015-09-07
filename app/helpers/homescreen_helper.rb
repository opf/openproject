#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module HomescreenHelper
  ##
  # Homescreen name
  def organization_name
    Setting.app_title || Setting.software_name
  end

  ##
  # Homescreen organization icon
  def organization_icon
    content_tag :span, '', class: 'icon-context icon-enterprise'
  end

  ##
  # Returns the user avatar or a default image
  def homescreen_user_avatar
    avatar = avatar(User.current)

    avatar.presence || content_tag(:span, '', class: 'icon-context icon-user1')
  end

  ##
  # Helper to list all showing blocks.
  def homescreen_blocks
    [
      {
        partial: 'welcome',
        if: -> { Setting.welcome_on_homescreen? && !Setting.welcome_text.empty? }
      },
      { partial: 'projects' },
      { partial: 'users', if: -> { User.current.admin? } },
      { partial: 'my_account', if: -> { User.current.logged? } },
      { partial: 'news', if: -> { !@news.empty? } },
      { partial: 'community' },
      { partial: 'administration', if: -> { User.current.admin? } }
    ]
  end

  ##
  # Helper to list all help icons in the lower homescreen
  def homescreen_links
    [
      {
        label: :user_guides,
        icon: 'icon-context icon-rename',
        url: 'https://www.openproject.org/help/user-guides/'
      },
      {
        label: :faq,
        icon: 'icon-context icon-faq',
        url: 'https://www.openproject.org/help/faq/'
      },
      {
        label: :glossary,
        icon: 'icon-context icon-glossar',
        url: 'https://www.openproject.org/help/user-guides/glossary/'
      },
      {
        label: :shortcuts,
        icon: 'icon-context icon-shortcuts',
        url: 'https://www.openproject.org/help/user-guides/keyboard-shortcuts-access-keys/'
      },
      {
        label: :forums,
        icon: 'icon-context icon-bubble3',
        url: 'https://community.openproject.org/projects/openproject/boards'
      },
    ]
  end

  ##
  # Helper to social media links
  # currently not present in the core
  def homescreen_socialmedia
    []
  end
end
