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

module RepositoriesHelper
  def format_revision(revision)
    if revision.respond_to? :format_identifier
      revision.format_identifier
    else
      revision.to_s
    end
  end

  def truncate_at_line_break(text, length = 255)
    if text
      text.gsub(%r{^(.{#{length}}[^\n]*)\n.+$}m, '\\1...')
    end
  end

  def render_properties(properties)
    unless properties.nil? || properties.empty?
      content = ''
      properties.keys.sort.each do |property|
        content << content_tag('li', raw("<b>#{h property}</b>: <span>#{h properties[property]}</span>"))
      end
      content_tag('ul', content.html_safe, class: 'properties')
    end
  end

  def render_changeset_changes
    changes = @changeset.changes.find(:all, limit: 1000, order: 'path').map do |change|
      case change.action
      when 'A'
        # Detects moved/copied files
        if !change.from_path.blank?
          action = @changeset.changes.detect { |c| c.action == 'D' && c.path == change.from_path }
          change.action = action ? 'R' : 'C'
        end
        change
      when 'D'
        @changeset.changes.detect { |c| c.from_path == change.path } ? nil : change
      else
        change
      end
    end.compact

    tree = {}
    changes.each do |change|
      p = tree
      dirs = change.path.to_s.split('/').select { |d| !d.blank? }
      path = ''
      dirs.each do |dir|
        path += with_leading_slash(dir)
        p[:s] ||= {}
        p = p[:s]
        p[path] ||= {}
        p = p[path]
      end
      p[:c] = change
    end

    render_changes_tree(tree[:s])
  end

  def render_changes_tree(tree)
    return '' if tree.nil?

    output = ''
    output << '<ul>'
    tree.keys.sort.each do |file|
      style = 'change'
      text = File.basename(h(file))
      if s = tree[file][:s]
        style << ' folder'
        path_param = without_leading_slash(to_path_param(@repository.relative_path(file)))
        text = link_to(h(text),
                       controller: '/repositories',
                       action: 'show',
                       project_id: @project,
                       path: path_param,
                       rev: @changeset.identifier)
        output << "<li class='#{style}'>#{text}</li>"
        output << render_changes_tree(s)
      elsif c = tree[file][:c]
        style << " change-#{c.action}"
        path_param = without_leading_slash(to_path_param(@repository.relative_path(c.path)))
        text = link_to(h(text),
                       controller: '/repositories',
                       action: 'entry',
                       project_id: @project,
                       path: path_param,
                       rev: @changeset.identifier) unless c.action == 'D'
        text << raw(" - #{h(c.revision)}") unless c.revision.blank?
        text << raw(' (' + link_to(l(:label_diff),
                                   controller: '/repositories',
                                   action: 'diff',
                                   project_id: @project,
                                   path: path_param,
                                   rev: @changeset.identifier) + ') ') if c.action == 'M'
        text << raw(' ' + content_tag('span', h(c.from_path), class: 'copied-from')) unless c.from_path.blank?
        output << "<li class='#{style}'>#{text}</li>"
      end
    end
    output << '</ul>'
    output.html_safe
  end

  def to_utf8_for_repositories(str)
    return str if str.nil?
    str = to_utf8_internal(str)
    if str.respond_to?(:force_encoding)
      str.force_encoding('UTF-8')
    end
    str
  end

  def to_utf8_internal(str)
    return str if str.nil?
    if str.respond_to?(:force_encoding)
      str.force_encoding('ASCII-8BIT')
    end
    return str if str.empty?
    return str if /\A[\r\n\t\x20-\x7e]*\Z/n.match(str) # for us-ascii
    if str.respond_to?(:force_encoding)
      str.force_encoding('UTF-8')
    end
    @encodings ||= Setting.repositories_encodings.split(',').map(&:strip)
    @encodings.each do |encoding|
      begin
        return str.to_s.encode('UTF-8', encoding)
      rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
        # do nothing here and try the next encoding
      end
    end
    str = replace_invalid_utf8(str)
  end

  private :to_utf8_internal

  def replace_invalid_utf8(str)
    return str if str.nil?
    if str.respond_to?(:force_encoding)
      str.force_encoding('UTF-8')
      if !str.valid_encoding?
        str = str.encode("US-ASCII", invalid: :replace,
                         undef: :replace, replace: '?').encode("UTF-8")
      end
    else
      # removes invalid UTF8 sequences
      begin
        (str + '  ').encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")[0..-3]
      rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
      end
    end
    str
  end

  ##
  # Retrieves all valid SCM vendors from the Manager
  # and injects an already persisted repository for correctly
  # displaying an existing repository.
  def scm_options(repository = nil)
    scms = OpenProject::Scm::Manager.enabled
    vendor = repository.nil? ? nil : repository.vendor

    if vendor && !repository.new_record?
      scms[vendor] = vendor
    end

    scms = [default_selected_option] + scms.keys
    options_for_select(scms, vendor)
  end

  def default_selected_option
    [
      "--- #{l(:actionview_instancetag_blank_option)} ---",
      '',
      { disabled: true, selected: true }
    ]
  end

  def vendor_name(repository)
    repository.vendor.underscore
  end

  def scm_vendor_tag(repository)
    select_tag('scm_vendor',
               scm_options(repository),
               class: 'form--select repositories--remote-select',
               data: {
                 remote: true,
                 url: url_for(controller: '/repositories',
                              action: 'edit', project_id: @project.id),
               },
               disabled: (repository && !repository.new_record?)
              )
  end

  def with_leading_slash(path)
    path.to_s.starts_with?('/') ? path : "/#{path}"
  end

  def without_leading_slash(path)
    path.gsub(%r{\A/+}, '')
  end
end
