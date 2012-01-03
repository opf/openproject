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

require 'SVG/Graph/Bar'
require 'SVG/Graph/BarHorizontal'
require 'digest/sha1'

class ChangesetNotFound < Exception; end
class InvalidRevisionParam < Exception; end

class RepositoriesController < ApplicationController
  menu_item :repository
  menu_item :settings, :only => :edit
  default_search_scope :changesets

  before_filter :find_repository, :except => :edit
  before_filter :find_project, :only => :edit
  before_filter :authorize
  accept_key_auth :revisions

  rescue_from Redmine::Scm::Adapters::CommandFailed, :with => :show_error_command_failed

  def edit
    @repository = @project.repository
    if !@repository
      @repository = Repository.factory(params[:repository_scm])
      @repository.project = @project if @repository
    end
    if request.post? && @repository
      @repository.attributes = params[:repository]
      @repository.save
    end
    render(:update) do |page|
      page.replace_html "tab-content-repository", :partial => 'projects/settings/repository'
      if @repository && !@project.repository
        @project.reload #needed to reload association
        page.replace_html "main-menu", render_main_menu(@project)
      end
    end
  end

  def committers
    @committers = @repository.committers
    @users = @project.users
    additional_user_ids = @committers.collect(&:last).collect(&:to_i) - @users.collect(&:id)
    @users += User.find_all_by_id(additional_user_ids) unless additional_user_ids.empty?
    @users.compact!
    @users.sort!
    if request.post? && params[:committers].is_a?(Hash)
      # Build a hash with repository usernames as keys and corresponding user ids as values
      @repository.committer_ids = params[:committers].values.inject({}) {|h, c| h[c.first] = c.last; h}
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'committers', :id => @project
    end
  end

  def destroy
    @repository.destroy
    redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => 'repository'
  end

  def show
    @repository.fetch_changesets if Setting.autofetch_changesets? && @path.empty?

    @entries = @repository.entries(@path, @rev)
    @changeset = @repository.find_changeset_by_name(@rev)
    if request.xhr?
      @entries ? render(:partial => 'dir_list_content') : render(:nothing => true)
    else
      (show_error_not_found; return) unless @entries
      @changesets = @repository.latest_changesets(@path, @rev)
      @properties = @repository.properties(@path, @rev)
      render :action => 'show'
    end
  end

  alias_method :browse, :show

  def changes
    @entry = @repository.entry(@path, @rev)
    (show_error_not_found; return) unless @entry
    @changesets = @repository.latest_changesets(@path, @rev, Setting.repository_log_display_limit.to_i)
    @properties = @repository.properties(@path, @rev)
    @changeset = @repository.find_changeset_by_name(@rev)
  end

  def revisions
    @changeset_count = @repository.changesets.count
    @changeset_pages = Paginator.new self, @changeset_count,
                                     per_page_option,
                                     params['page']
    @changesets = @repository.changesets.find(:all,
                       :limit  =>  @changeset_pages.items_per_page,
                       :offset =>  @changeset_pages.current.offset,
                       :include => [:user, :repository])

    respond_to do |format|
      format.html { render :layout => false if request.xhr? }
      format.atom { render_feed(@changesets, :title => "#{@project.name}: #{l(:label_revision_plural)}") }
    end
  end

  def entry
    @entry = @repository.entry(@path, @rev)
    (show_error_not_found; return) unless @entry

    # If the entry is a dir, show the browser
    (show; return) if @entry.is_dir?

    @content = @repository.cat(@path, @rev)
    (show_error_not_found; return) unless @content
    if 'raw' == params[:format] ||
         (@content.size && @content.size > Setting.file_max_size_displayed.to_i.kilobyte) ||
         ! is_entry_text_data?(@content, @path)
      # Force the download
      send_opt = { :filename => filename_for_content_disposition(@path.split('/').last) }
      send_type = Redmine::MimeType.of(@path)
      send_opt[:type] = send_type.to_s if send_type
      send_data @content, send_opt
    else
      # Prevent empty lines when displaying a file with Windows style eol
      # TODO: UTF-16
      # Is this needs? AttachmentsController reads file simply.
      @content.gsub!("\r\n", "\n")
      @changeset = @repository.find_changeset_by_name(@rev)
    end
  end

  def is_entry_text_data?(ent, path)
    # UTF-16 contains "\x00".
    # It is very strict that file contains less than 30% of ascii symbols
    # in non Western Europe.
    return true if Redmine::MimeType.is_type?('text', path)
    # Ruby 1.8.6 has a bug of integer divisions.
    # http://apidock.com/ruby/v1_8_6_287/String/is_binary_data%3F
    if ent.respond_to?("is_binary_data?") && ent.is_binary_data? # Ruby 1.8.x and <1.9.2
      return false
    elsif ent.respond_to?(:force_encoding) && (ent.dup.force_encoding("UTF-8") != ent.dup.force_encoding("BINARY") ) # Ruby 1.9.2
      # TODO: need to handle edge cases of non-binary content that isn't UTF-8
      return false
    end
    true
  end
  private :is_entry_text_data?

  def annotate
    @entry = @repository.entry(@path, @rev)
    (show_error_not_found; return) unless @entry

    @annotate = @repository.scm.annotate(@path, @rev)
    (render_error l(:error_scm_annotate); return) if @annotate.nil? || @annotate.empty?
    @changeset = @repository.find_changeset_by_name(@rev)
  end

  def revision
    raise ChangesetNotFound if @rev.blank?
    @changeset = @repository.find_changeset_by_name(@rev)
    raise ChangesetNotFound unless @changeset

    respond_to do |format|
      format.html
      format.js {render :layout => false}
    end
  rescue ChangesetNotFound
    show_error_not_found
  end

  def diff
    if params[:format] == 'diff'
      @diff = @repository.diff(@path, @rev, @rev_to)
      (show_error_not_found; return) unless @diff
      filename = "changeset_r#{@rev}"
      filename << "_r#{@rev_to}" if @rev_to
      send_data @diff.join, :filename => "#{filename}.diff",
                            :type => 'text/x-patch',
                            :disposition => 'attachment'
    else
      @diff_type = params[:type] || User.current.pref[:diff_type] || 'inline'
      @diff_type = 'inline' unless %w(inline sbs).include?(@diff_type)

      # Save diff type as user preference
      if User.current.logged? && @diff_type != User.current.pref[:diff_type]
        User.current.pref[:diff_type] = @diff_type
        User.current.preference.save
      end

      @cache_key = "repositories/diff/#{@repository.id}/" + Digest::MD5.hexdigest("#{@path}-#{@rev}-#{@rev_to}-#{@diff_type}")
      unless read_fragment(@cache_key)
        @diff = @repository.diff(@path, @rev, @rev_to)
        show_error_not_found unless @diff
      end

      @changeset = @repository.find_changeset_by_name(@rev)
      @changeset_to = @rev_to ? @repository.find_changeset_by_name(@rev_to) : nil
      @diff_format_revisions = @repository.diff_format_revisions(@changeset, @changeset_to)
    end
  end

  def stats
  end

  def graph
    data = nil
    case params[:graph]
    when "commits_per_month"
      data = graph_commits_per_month(@repository)
    when "commits_per_author"
      data = graph_commits_per_author(@repository)
    end
    if data
      headers["Content-Type"] = "image/svg+xml"
      send_data(data, :type => "image/svg+xml", :disposition => "inline")
    else
      render_404
    end
  end

  private

  REV_PARAM_RE = %r{\A[a-f0-9]*\Z}i

  def find_repository
    @project = Project.find(params[:id])
    @repository = @project.repository
    (render_404; return false) unless @repository
    @path = params[:path].join('/') unless params[:path].nil?
    @path ||= ''
    @rev = params[:rev].blank? ? @repository.default_branch : params[:rev].strip
    @rev_to = params[:rev_to]

    unless @rev.to_s.match(REV_PARAM_RE) && @rev_to.to_s.match(REV_PARAM_RE)
      if @repository.branches.blank?
        raise InvalidRevisionParam
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  rescue InvalidRevisionParam
    show_error_not_found
  end

  def show_error_not_found
    render_error :message => l(:error_scm_not_found), :status => 404
  end

  # Handler for Redmine::Scm::Adapters::CommandFailed exception
  def show_error_command_failed(exception)
    render_error l(:error_scm_command_failed, exception.message)
  end

  def graph_commits_per_month(repository)
    @date_to = Date.today
    @date_from = @date_to << 11
    @date_from = Date.civil(@date_from.year, @date_from.month, 1)
    commits_by_day = repository.changesets.count(:all, :group => :commit_date, :conditions => ["commit_date BETWEEN ? AND ?", @date_from, @date_to])
    commits_by_month = [0] * 12
    commits_by_day.each {|c| commits_by_month[c.first.to_date.months_ago] += c.last }

    changes_by_day = repository.changes.count(:all, :group => :commit_date, :conditions => ["commit_date BETWEEN ? AND ?", @date_from, @date_to])
    changes_by_month = [0] * 12
    changes_by_day.each {|c| changes_by_month[c.first.to_date.months_ago] += c.last }

    fields = []
    12.times {|m| fields << month_name(((Date.today.month - 1 - m) % 12) + 1)}

    graph = SVG::Graph::Bar.new(
      :height => 300,
      :width => 800,
      :fields => fields.reverse,
      :stack => :side,
      :scale_integers => true,
      :step_x_labels => 2,
      :show_data_values => false,
      :graph_title => l(:label_commits_per_month),
      :show_graph_title => true
    )

    graph.add_data(
      :data => commits_by_month[0..11].reverse,
      :title => l(:label_revision_plural)
    )

    graph.add_data(
      :data => changes_by_month[0..11].reverse,
      :title => l(:label_change_plural)
    )

    graph.burn
  end

  def graph_commits_per_author(repository)
    commits_by_author = repository.changesets.count(:all, :group => :committer)
    commits_by_author.to_a.sort! {|x, y| x.last <=> y.last}

    changes_by_author = repository.changes.count(:all, :group => :committer)
    h = changes_by_author.inject({}) {|o, i| o[i.first] = i.last; o}

    fields = commits_by_author.collect {|r| r.first}
    commits_data = commits_by_author.collect {|r| r.last}
    changes_data = commits_by_author.collect {|r| h[r.first] || 0}

    fields = fields + [""]*(10 - fields.length) if fields.length<10
    commits_data = commits_data + [0]*(10 - commits_data.length) if commits_data.length<10
    changes_data = changes_data + [0]*(10 - changes_data.length) if changes_data.length<10

    # Remove email adress in usernames
    fields = fields.collect {|c| c.gsub(%r{<.+@.+>}, '') }

    graph = SVG::Graph::BarHorizontal.new(
      :height => 400,
      :width => 800,
      :fields => fields,
      :stack => :side,
      :scale_integers => true,
      :show_data_values => false,
      :rotate_y_labels => false,
      :graph_title => l(:label_commits_per_author),
      :show_graph_title => true
    )

    graph.add_data(
      :data => commits_data,
      :title => l(:label_revision_plural)
    )

    graph.add_data(
      :data => changes_data,
      :title => l(:label_change_plural)
    )

    graph.burn
  end

end

class Date
  def months_ago(date = Date.today)
    (date.year - self.year)*12 + (date.month - self.month)
  end

  def weeks_ago(date = Date.today)
    (date.year - self.year)*52 + (date.cweek - self.cweek)
  end
end

class String
  def with_leading_slash
    starts_with?('/') ? self : "/#{self}"
  end
end
