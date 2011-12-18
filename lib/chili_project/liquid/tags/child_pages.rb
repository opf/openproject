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

module ChiliProject::Liquid::Tags
  class ChildPages < Tag
    def initialize(tag_name, markup, tokens)
      markup = markup.strip.gsub(/["']/, '')
      if markup.present?
        tag_args = markup.split(',')
        @args, @options = extract_macro_options(tag_args, :parent)
      else
        @args = []
        @options = {}
      end
      super
    end

    def render(context)
      # inside of a project
      @project = Project.find(context['project'].identifier) if context['project'].present?

      if @args.present?
        page_name = @args.first.to_s
        cross_project_page = page_name.include?(':')

        page = Wiki.find_page(page_name, :project => (cross_project_page ? nil : @project))
      # FIXME: :object and :attribute should be variables, not registers
      elsif context.registers[:object].is_a?(WikiContent)
        page = context.registers[:object].page
        page_name = page.title
      elsif @project
        return render_all_pages(context)
      else
        raise TagError.new('With no argument, this tag can be called from projects only.')
      end

      raise TagError.new("No such page '#{page_name}'") if page.nil? || !User.current.allowed_to?(:view_wiki_pages, page.wiki.project)
      pages = ([page] + page.descendants).group_by(&:parent_id)
      context.registers[:view].render_page_hierarchy(pages, @options[:parent] ? page.parent_id : page.id)
    end

  private
    def render_all_pages(context)
      return '' unless @project.wiki.present? && @project.wiki.pages.present?
      raise TagError.new('Page not found') if !User.current.allowed_to?(:view_wiki_pages, @project)

      context.registers[:view].render_page_hierarchy(@project.wiki.pages.group_by(&:parent_id))
    end

    # @param args [Array, String] An array of strings in "key=value" format
    # @param keys [Hash, Symbol] List of keyword args to extract
    def extract_macro_options(args, *keys)
      options = {}
      args.each do |arg|
        if arg.to_s.gsub(/["']/,'').strip =~ %r{^(.+)\=(.+)$} && keys.include?($1.downcase.to_sym)
          options[$1.downcase.to_sym] = $2
          args.pop
        end
      end
      return [args, options]
    end
  end
end