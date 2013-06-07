#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'redmine/scm/adapters/filesystem_adapter'

class Repository::Filesystem < Repository
  attr_protected :root_url
  validates_presence_of :url

  ATTRIBUTE_KEY_NAMES = {
      "url"          => "Root directory",
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

  def supports_all_revisions?
    false
  end

  def entries(path=nil, identifier=nil)
    scm.entries(path, identifier)
  end

  def fetch_changesets
    nil
  end

end
