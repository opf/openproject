# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

class Source::SeedDataLoader
  include Source::Translate

  class << self
    def get_data(edition: nil)
      edition ||= OpenProject::Configuration['edition']
      loader = new(seed_file_name: edition)
      loader.seed_data
    end
  end

  attr_reader :seed_file_name, :locale

  def initialize(seed_file_name: 'standard', locale: I18n.locale)
    @seed_file_name = seed_file_name
    @locale = locale
  end

  def seed_data
    @seed_data ||= Source::SeedData.new(translate(seed_file.raw_content))
  end

  private

  def seed_file
    Source::SeedFile.find(seed_file_name)
  end
end
