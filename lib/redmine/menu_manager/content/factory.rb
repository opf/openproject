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

module Redmine::MenuManager::Content
  module Factory
    def self.build(content, options = {})
      if content.respond_to?(:call)
        content
      elsif content.is_a?(Hash) || content.is_a?(Symbol)
        Redmine::MenuManager::Content::Link.new(content, options)
      else
        raise "Don't know what content to create from #{content}, #{options}"
      end
    end
  end
end

