# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

require 'SVG/Graph/Bar'
require 'SVG/Graph/BarHorizontal'

class RepositoriesController < ApplicationController
  layout 'base'
  before_filter :find_project
  before_filter :authorize, :except => [:stats, :graph]
  before_filter :check_project_privacy, :only => [:stats, :graph]
  
  def show
    # get entries for the browse frame
    @entries = @repository.scm.entries('')
    show_error and return unless @entries
    # check if new revisions have been committed in the repository
    scm_latestrev = @entries.revisions.latest
    if Setting.autofetch_changesets? && scm_latestrev && ((@repository.latest_changeset.nil?) || (@repository.latest_changeset.revision < scm_latestrev.identifier.to_i))
      @repository.fetch_changesets
      @repository.reload
    end
    @changesets = @repository.changesets.find(:all, :limit => 5, :order => "committed_on DESC")
  end
  
  def browse
    @entries = @repository.scm.entries(@path, @rev)
    show_error and return unless @entries
  end
  
  def revisions
    unless @path == ''
      @entry = @repository.scm.entry(@path, @rev)  
      show_error and return unless @entry
    end
    @changesets = @repository.changesets_for_path(@path)
  end
  
  def entry
    if 'raw' == params[:format]
      content = @repository.scm.cat(@path, @rev)
      show_error and return unless content
      send_data content, :filename => @path.split('/').last
    end
  end
  
  def revision
    @changeset = @repository.changesets.find_by_revision(@rev)
    show_error and return unless @changeset
  end
  
  def diff
    @rev_to = params[:rev_to] || (@rev-1)
    @diff = @repository.scm.diff(params[:path], @rev, @rev_to)
    show_error and return unless @diff
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
  def find_project
    @project = Project.find(params[:id])
    @repository = @project.repository
    render_404 and return false unless @repository
    @path = params[:path].squeeze('/').gsub(/^\//, '') if params[:path]
    @path ||= ''
    @rev = params[:rev].to_i if params[:rev] and params[:rev].to_i > 0
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def show_error
    flash.now[:notice] = l(:notice_scm_error)
    render :nothing => true, :layout => true
  end
  
  def graph_commits_per_month(repository)
    @date_to = Date.today
    @date_from = @date_to << 12
    commits_by_day = repository.changesets.count(:all, :group => :commit_date, :conditions => ["commit_date BETWEEN ? AND ?", @date_from, @date_to])
    commits_by_month = [0] * 12
    commits_by_day.each {|c| commits_by_month[c.first.to_date.months_ago] += c.last }

    changes_by_day = repository.changes.count(:all, :group => :commit_date)
    changes_by_month = [0] * 12
    changes_by_day.each {|c| changes_by_month[c.first.to_date.months_ago] += c.last }
   
    fields = []
    month_names = l(:actionview_datehelper_select_month_names_abbr).split(',')
    12.times {|m| fields << month_names[((Date.today.month - 1 - m) % 12)]}
  
    graph = SVG::Graph::Bar.new(
      :height => 300,
      :width => 500,
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
    commits_by_author.sort! {|x, y| x.last <=> y.last}
    
    fields = commits_by_author.collect {|r| r.first}
    data = commits_by_author.collect {|r| r.last}
    
    fields = fields + [""]*(10 - fields.length) if fields.length<10
    data = data + [0]*(10 - data.length) if data.length<10
    
    graph = SVG::Graph::BarHorizontal.new(
      :height => 300,
      :width => 500,
      :fields => fields,
      :stack => :side,
      :scale_integers => true,
      :show_data_values => false,
      :rotate_y_labels => false,
      :graph_title => l(:label_commits_per_author),
      :show_graph_title => true
    )
    
    graph.add_data(
      :data => data,
      :title => l(:label_revision_plural)
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