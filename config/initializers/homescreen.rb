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

require 'open_project/homescreen'

OpenProject::Homescreen.manage :blocks do |blocks|
  blocks.push(
    { partial: 'welcome',
      if: Proc.new { Setting.welcome_on_homescreen? && !Setting.welcome_text.empty? } },
    { partial: 'projects' },
    { partial: 'users',
      if: Proc.new { User.current.admin? } },
    { partial: 'my_account',
      if: Proc.new { User.current.logged? } },
    { partial: 'news',
      if: Proc.new { !@news.empty? } },
    { partial: 'community' },
    { partial: 'administration',
      if: Proc.new { User.current.admin? } }
  )
end

OpenProject::Homescreen.manage :links do |links|
  links.push(
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
    }
  )
end
