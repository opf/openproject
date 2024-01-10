#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module RepositoriesHelper
  def format_revision(revision)
    if revision.respond_to? :format_identifier
      revision.format_identifier
    else
      revision.to_s
    end
  end

  ##
  # Format revision commits with plain formatter
  def format_revision_text(commit_message)
    format_text(commit_message, format: 'plain')
  end

  def truncate_at_line_break(text, length = 255)
    text&.gsub(%r{^(.{#{length}}[^\n]*)\n.+$}m, '\\1...')
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
    changes = @changeset.file_changes.limit(1000).order(Arel.sql('path')).filter_map do |change|
      case change.action
      when 'A'
        # Detects moved/copied files
        if change.from_path.present?
          action = @changeset.file_changes.detect { |c| c.action == 'D' && c.path == change.from_path }
          change.action = action ? 'R' : 'C'
        end
        change
      when 'D'
        @changeset.file_changes.detect { |c| c.from_path == change.path } ? nil : change
      else
        change
      end
    end

    tree = {}
    changes.each do |change|
      p = tree
      dirs = change.path.to_s.split('/').select { |d| d.present? }
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

  # Mapping from internal action to (folder|file)-icon type
  def change_action_mapping
    {
      'A' => :add,
      'B' => :remove
    }
  end

  # This calculates whether a folder was added, deleted or modified. It is based on the assumption that
  # a folder was added/deleted when all content was added/deleted since the folder changes were not tracked.
  def calculate_folder_action(tree)
    seen = Set.new
    tree.each do |_, entry|
      if folder_style = change_action_mapping[entry[:c].try(:action)]
        seen << folder_style
      end
    end

    seen.size == 1 ? seen.first : :open
  end

  def render_changes_tree(tree)
    return '' if tree.nil?

    output = '<ul>'
    tree.keys.sort.each do |file|
      style = 'change'
      text = File.basename(file)
      if s = tree[file][:s]
        style << ' folder'
        path_param = without_leading_slash(to_path_param(@repository.relative_path(file)))
        text = link_to(h(text),
                       show_revisions_path_project_repository_path(project_id: @project,
                                                                   repo_path: path_param,
                                                                   rev: @changeset.identifier),
                       title: I18n.t(:label_folder))

        output << "<li class='#{style} icon icon-folder-#{calculate_folder_action(s)}'>#{text}</li>"
        output << render_changes_tree(s)
      elsif c = tree[file][:c]
        style << " change-#{c.action}"
        path_param = without_leading_slash(to_path_param(@repository.relative_path(c.path)))

        unless c.action == 'D'
          title_text = changes_tree_change_title c.action

          text = link_to(h(text),
                         entry_revision_project_repository_path(project_id: @project,
                                                                repo_path: path_param,
                                                                rev: @changeset.identifier),
                         title: title_text)
        end

        text << raw(" - #{h(c.revision)}") if c.revision.present?

        if c.action == 'M'
          text << raw(' (' + link_to(I18n.t(:label_diff),
                                     diff_revision_project_repository_path(project_id: @project,
                                                                           repo_path: path_param,
                                                                           rev: @changeset.identifier)) + ') ')
        end

        text << raw(' ' + content_tag('span', h(c.from_path), class: 'copied-from')) if c.from_path.present?

        output << changes_tree_li_element(c.action, text, style)
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
    return str if /\A[\r\n\t\x20-\x7e]*\Z/n.match?(str) # for us-ascii

    if str.respond_to?(:force_encoding)
      str.force_encoding('UTF-8')
    end
    @encodings ||= Setting.repositories_encodings.split(',').map(&:strip)
    @encodings.each do |encoding|
      return str.to_s.encode('UTF-8', encoding)
    rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
      # do nothing here and try the next encoding
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
        (str + '  ').encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')[0..-3]
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
    options = []
    OpenProject::SCM::Manager.enabled.each do |vendor, klass|
      # Skip repositories that were configured to have no
      # available types left.
      next if klass.available_types.empty?

      options << [klass.vendor_name, vendor]
    end

    existing_vendor = repository.nil? ? nil : repository.vendor
    options_for_select([default_selected_option] + options, existing_vendor)
  end

  def default_selected_option
    [
      "--- #{I18n.t(:actionview_instancetag_blank_option)} ---",
      '',
      { disabled: true, selected: true }
    ]
  end

  def scm_vendor_tag(repository)
    # rubocop:disable Rails/HelperInstanceVariable
    url = url_for(controller: '/projects/settings/repository', action: 'show', id: @project.id)
    # rubocop:enable Rails/HelperInstanceVariable
    #
    select_tag('scm_vendor',
               scm_options(repository),
               class: 'form--select',
               data: {
                 url:,
                 action: 'repository-settings#updateSelectedType',
                 'repository-settings-target': 'scmVendor'
               },
               disabled: repository && !repository.new_record?)
  end

  def git_path_encoding_options(repository)
    default = repository.new_record? ? 'UTF-8' : repository.path_encoding
    options_for_select(Setting::ENCODINGS, default)
  end

  ##
  # Determines whether the repository settings save button should be shown.
  # By default, it is not shown when repository exists and is managed.
  def show_settings_save_button?(_repository)
    @repository.nil? ||
      @repository.new_record? ||
      !@repository.managed?
  end

  def with_leading_slash(path)
    path.to_s.starts_with?('/') ? path : "/#{path}"
  end

  def without_leading_slash(path)
    path.gsub(%r{\A/+}, '')
  end

  def changes_tree_change_title(action)
    case action
    when 'A'
      I18n.t(:label_added)
    when 'D'
      I18n.t(:label_deleted)
    when 'C'
      I18n.t(:label_copied)
    when 'R'
      I18n.t(:label_renamed)
    else
      I18n.t(:label_modified)
    end
  end

  def changes_tree_li_element(action, text, style)
    icon_name = case action
                when 'A'
                  'icon-add'
                when 'D'
                  'icon-delete'
                when 'C'
                  'icon-copy'
                when 'R'
                  'icon-rename'
                else
                  'icon-arrow-left-right'
                end

    "<li class='#{style} icon #{icon_name}'
         title='#{changes_tree_change_title(action)}'>#{text}</li>"
  end
end
