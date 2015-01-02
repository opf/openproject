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

# store email header and footer localized (take Setting.default_language first, then english)
class LocalizeEmailHeaderAndFooter < ActiveRecord::Migration
  def self.up
    emails_header = Setting.find_by_name 'emails_header'
    emails_footer = Setting.find_by_name 'emails_footer'

    default_language = Setting.default_language
    default_language = 'en' if default_language.blank?

    if emails_header
      translation = { default_language => emails_header.read_attribute(:value) }
      emails_header.write_attribute(:value, translation.to_yaml.to_s)
      emails_header.save!
    end

    if emails_footer
      translation = { default_language => emails_footer.read_attribute(:value) }
      emails_footer.write_attribute(:value, translation.to_yaml.to_s)
      emails_footer.save!
    end
  end

  def self.down
    emails_header = Setting.find_by_name 'emails_header'
    emails_footer = Setting.find_by_name 'emails_footer'

    default_language = Setting.default_language
    default_language = 'en' if default_language.blank?

    if emails_header
      translations = YAML::load(emails_header.read_attribute(:value))
      text = translations[default_language]
      text = translations.values.first if text.blank?
      # mimick Setting.value=
      emails_header.write_attribute(:value, text)
      emails_header.save!
    end

    if emails_footer
      translations = YAML::load(emails_footer.read_attribute(:value))
      text = translations[default_language]
      text = translations.values.first if text.blank?
      # mimick Setting.value=
      emails_footer.write_attribute(:value, text)
      emails_footer.save!
    end
  end
end
