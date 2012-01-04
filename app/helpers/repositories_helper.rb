#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'iconv'

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
        content << content_tag('li', "<b>#{h property}</b>: <span>#{h properties[property]}</span>")
      end
      content_tag('ul', content, :class => 'properties')
    end
  end

  def render_changeset_changes
    changes = @changeset.changes.find(:all, :limit => 1000, :order => 'path').collect do |change|
      case change.action
      when 'A'
        # Detects moved/copied files
        if !change.from_path.blank?
          change.action = @changeset.changes.detect {|c| c.action == 'D' && c.path == change.from_path} ? 'R' : 'C'
        end
        change
      when 'D'
        @changeset.changes.detect {|c| c.from_path == change.path} ? nil : change
      else
        change
      end
   end.compact

    tree = { }
    changes.each do |change|
      p = tree
      dirs = change.path.to_s.split('/').select {|d| !d.blank?}
      path = ''
      dirs.each do |dir|
        path += '/' + dir
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
        path_param = to_path_param(@repository.relative_path(file))
        text = link_to(h(text), :controller => 'repositories',
                             :action => 'show',
                             :id => @project,
                             :path => path_param,
                             :rev => @changeset.identifier)
        output << "<li class='#{style}'>#{text}</li>"
        output << render_changes_tree(s)
      elsif c = tree[file][:c]
        style << " change-#{c.action}"
        path_param = to_path_param(@repository.relative_path(c.path))
        text = link_to(h(text), :controller => 'repositories',
                             :action => 'entry',
                             :id => @project,
                             :path => path_param,
                             :rev => @changeset.identifier) unless c.action == 'D'
        text << " - #{h(c.revision)}" unless c.revision.blank?
        text << ' (' + link_to(l(:label_diff), :controller => 'repositories',
                                       :action => 'diff',
                                       :id => @project,
                                       :path => path_param,
                                       :rev => @changeset.identifier) + ') ' if c.action == 'M'
        text << ' ' + content_tag('span', h(c.from_path), :class => 'copied-from') unless c.from_path.blank?
        output << "<li class='#{style}'>#{text}</li>"
      end
    end
    output << '</ul>'
    output
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
    @encodings ||= Setting.repositories_encodings.split(',').collect(&:strip)
    @encodings.each do |encoding|
      begin
        return Iconv.conv('UTF-8', encoding, str)
      rescue Iconv::Failure
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
      if ! str.valid_encoding?
        str = str.encode("US-ASCII", :invalid => :replace,
              :undef => :replace, :replace => '?').encode("UTF-8")
      end
    else
      # removes invalid UTF8 sequences
      begin
        str = Iconv.conv('UTF-8//IGNORE', 'UTF-8', str + '  ')[0..-3]
      rescue Iconv::InvalidEncoding
        # "UTF-8//IGNORE" is not supported on some OS
      end
    end
    str
  end

  def repository_field_tags(form, repository)
    method = repository.class.name.demodulize.underscore + "_field_tags"
    if repository.is_a?(Repository) &&
        respond_to?(method) && method != 'repository_field_tags'
      send(method, form, repository)
    end
  end

  def scm_select_tag(repository)
    scm_options = [["--- #{l(:actionview_instancetag_blank_option)} ---", '']]
    Redmine::Scm::Base.all.each do |scm|
    if Setting.enabled_scm.include?(scm) ||
          (repository && repository.class.name.demodulize == scm)
        scm_options << ["Repository::#{scm}".constantize.scm_name, scm]
      end
    end
    select_tag('repository_scm',
               options_for_select(scm_options, repository.class.name.demodulize),
               :disabled => (repository && !repository.new_record?),
               :onchange => remote_function(
                  :url => {
                      :controller => 'repositories',
                      :action => 'edit',
                      :id => @project
                        },
               :method => :get,
               :with => "Form.serialize(this.form)")
               )
  end

  def with_leading_slash(path)
    path.to_s.starts_with?('/') ? path : "/#{path}"
  end

  def without_leading_slash(path)
    path.gsub(%r{^/+}, '')
  end

  def subversion_field_tags(form, repository)
      content_tag('p', form.text_field(:url, :size => 60, :required => true, :disabled => (repository && !repository.root_url.blank?)) +
                       '<br />(file:///, http://, https://, svn://, svn+[tunnelscheme]://)') +
      content_tag('p', form.text_field(:login, :size => 30)) +
      content_tag('p', form.password_field(:password, :size => 30, :name => 'ignore',
                                           :value => ((repository.new_record? || repository.password.blank?) ? '' : ('x'*15)),
                                           :onfocus => "this.value=''; this.name='repository[password]';",
                                           :onchange => "this.name='repository[password]';"))
  end

  def darcs_field_tags(form, repository)
    content_tag('p', form.text_field(:url, :label => :label_darcs_path, :size => 60, :required => true, :disabled => (repository && !repository.new_record?))) +
      content_tag('p', form.select(:log_encoding, [nil] + Setting::ENCODINGS,
                                   :label => l(:setting_commit_logs_encoding), :required => true))
  end

  def mercurial_field_tags(form, repository)
      content_tag('p', form.text_field(:url, :label => :label_mercurial_path, :size => 60, :required => true, :disabled => (repository && !repository.root_url.blank?)) +
                  '<br />' + l(:text_mercurial_repo_example)) +
      content_tag('p', form.select(:path_encoding, [nil] + Setting::ENCODINGS,
                                   :label => l(:label_path_encoding)) +
                  '<br />' + l(:text_default_encoding))
  end

  def git_field_tags(form, repository)
      content_tag('p', form.text_field(:url, :label => :label_git_path, :size => 60, :required => true, :disabled => (repository && !repository.root_url.blank?)) +
                  '<br />' + l(:text_git_repo_example)) +
    content_tag('p', form.select(
                        :path_encoding, [nil] + Setting::ENCODINGS,
                        :label => l(:label_path_encoding)) +
                        '<br />' + l(:text_default_encoding))
  end

  def cvs_field_tags(form, repository)
      content_tag('p', form.text_field(:root_url, :label => :label_cvs_path, :size => 60, :required => true, :disabled => !repository.new_record?)) +
      content_tag('p', form.text_field(:url, :label => :label_cvs_module, :size => 30, :required => true, :disabled => !repository.new_record?)) +
      content_tag('p', form.select(:log_encoding, [nil] + Setting::ENCODINGS,
                                   :label => l(:setting_commit_logs_encoding), :required => true))
  end

  def bazaar_field_tags(form, repository)
    content_tag('p', form.text_field(:url, :label => :label_bazaar_path, :size => 60, :required => true, :disabled => (repository && !repository.new_record?))) +
      content_tag('p', form.select(:log_encoding, [nil] + Setting::ENCODINGS,
                                   :label => l(:setting_commit_logs_encoding), :required => true))
  end

  def filesystem_field_tags(form, repository)
    content_tag('p', form.text_field(:url, :label => :label_filesystem_path, :size => 60, :required => true, :disabled => (repository && !repository.root_url.blank?))) +
    content_tag('p', form.select(:path_encoding, [nil] + Setting::ENCODINGS,
                                 :label => l(:label_path_encoding)) +
                                 '<br />' + l(:text_default_encoding))

  end
end
