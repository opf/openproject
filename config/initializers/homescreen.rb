#-- encoding: UTF-8
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

require 'open_project/static/homescreen'
require 'open_project/static/links'

OpenProject::Static::Homescreen.manage :blocks do |blocks|
  blocks.push(
    { partial: 'welcome',
      if: Proc.new { Setting.welcome_on_homescreen? && Setting.welcome_text.present? } },
    { partial: 'projects' },
    { partial: 'users',
      if: Proc.new { User.current.admin? } },
    { partial: 'my_account',
      if: Proc.new { User.current.logged? } },
    { partial: 'news',
      if: Proc.new { !@news.empty? } },
    { partial: 'community' },
    { partial: 'administration',
      if: Proc.new { User.current.admin? } },
    { partial: 'upsale',
      if: Proc.new { EnterpriseToken.show_banners? } }
  )
end

OpenProject::Static::Homescreen.manage :links do |links|
  static_links = OpenProject::Static::Links.links

  links.push(
    {
      label: :user_guides,
      icon: 'icon-context icon-rename',
      url: static_links[:user_guides][:href]
    },
    {
      label: :glossary,
      icon: 'icon-context icon-glossar',
      url: static_links[:glossary][:href]
    },
    {
      label: :shortcuts,
      icon: 'icon-context icon-shortcuts',
      url: static_links[:shortcuts][:href]
    },
    {
      label: :boards,
      icon: 'icon-context icon-forums',
      url: static_links[:boards][:href]
    }
  )
end
