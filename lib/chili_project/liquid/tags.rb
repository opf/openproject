#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module ChiliProject::Liquid
  module Tags
    class TagError < StandardError; end

    def self.register_tag(name, klass, options={})
      if options[:html]
        html_class = Class.new do
          def render(context)
            result = @tag.render(context)
            context.html_result(result)
          end

          def method_missing(*args, &block)
            @tag.send(*args, &block)
          end
        end
        html_class.send :define_method, :initialize do |*args|
          @tag = klass.new(*args)
        end
        ::Liquid::Template.register_tag(name, html_class)
      else
        ::Liquid::Template.register_tag(name, klass)
      end
    end

    register_tag('child_pages', ChildPages, :html => true)
    register_tag('hello_world', HelloWorld)
    register_tag('include', Include, :html => true)

    # Output these tags again as they were typed
    # These are to be handled later
    register_tag('toc', Identity, :html => true)
    register_tag('toc_left', Identity, :html => true)
    register_tag('toc_right', Identity, :html => true)

    # See ChiliProject::Liquid::Legacy for the definition of legacy tags,
    # most of which are also defined here
  end
end

