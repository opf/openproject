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

require 'redmine/scm/adapters/filesystem_adapter'

class Repository::Filesystem < Repository
  attr_protected :root_url
  validates_presence_of :url

  validate :validate_whitelisted_url,
           :validate_url_is_dir

  ATTRIBUTE_KEY_NAMES = {
    'url'          => 'Root directory',
  }
  def self.human_attribute_name(attribute_key_name, options = {})
    ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
  end

  def self.scm_adapter_class
    Redmine::Scm::Adapters::FilesystemAdapter
  end

  def self.scm_name
    'Filesystem'
  end

  def self.configured?
    !whitelisted_paths.empty?
  end

  def supports_all_revisions?
    false
  end

  def entries(path = nil, identifier = nil)
    scm.entries(path, identifier)
  end

  def fetch_changesets
    nil
  end

  private

  def self.whitelisted_paths
    OpenProject::Configuration['scm_filesystem_path_whitelist']
  end

  # validates that the url is a directory
  def validate_url_is_dir
    errors.add :url, :no_directory unless Dir.exists?(url)
  end

  # validate url against whitelisted urls as provided by the
  # scm_filesystem_path_whitelist configuration parameter.
  #
  # The url needs to exist and needs to match one of the directories
  # returned when globbing the configuration setting.
  def validate_whitelisted_url
    globbed_url = Dir.glob(url).first

    unless globbed_url
      errors.add :url, :not_whitelisted
      return
    end

    globbed_whitelisted = Dir.glob(self.class.whitelisted_paths)

    unless globbed_whitelisted.include?(globbed_url)
      errors.add :url, :not_whitelisted
    end
  end
end
