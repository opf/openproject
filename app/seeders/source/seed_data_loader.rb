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

# Loads the right seed files according to the given edition name.
#
# Seed files with the same name as the edition name are merged together. Then
# all seed files names `common.yml` are merged as well, allowing to share seed
# data between standard and bim editions.
class Source::SeedDataLoader
  include Source::Translate

  class << self
    def get_data(edition: nil, only: nil)
      edition ||= OpenProject::Configuration["edition"]
      loader = new(seed_name: edition, only:)
      loader.seed_data
    end
  end

  attr_reader :seed_name, :locale, :only

  def initialize(seed_name: "standard", locale: I18n.locale, only: nil)
    @seed_name = seed_name
    @locale = locale
    @only = only
  end

  def seed_data
    @seed_data ||= Source::SeedData.new(translated_seed_files_content)
  end

  def translated_seed_files_content
    seed_files
      .map { |seed_file| translate_seed_file(seed_file) }
      .reduce({}) do |merged_content, seed_file_content|
        merged_content.deep_merge(seed_file_content)
      end
  end

  private

  def seed_files
    Source::SeedFile.with_names(seed_name, "common")
  end

  def translate_seed_file(seed_file)
    raw_content = only ? seed_file.raw_content.slice(*Array(only)) : seed_file.raw_content
    translate(raw_content, "#{Source::Translate::I18N_PREFIX}.#{seed_file.name}")
  end
end
