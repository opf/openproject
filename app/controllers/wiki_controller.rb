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

class WikiController < ApplicationController
  layout 'base'
  before_filter :find_wiki, :check_project_privacy, :except => [:preview]
  before_filter :authorize, :only => :destroy
  
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :index }
  
  # display a page (in editing mode if it doesn't exist)
  def index
    page_title = params[:page]
    @page = @wiki.find_or_new_page(page_title)
    if @page.new_record?
      edit
      render :action => 'edit' and return
    end
    @content = @page.content_for_version(params[:version])
    if params[:export] == 'html'
      export = render_to_string :action => 'export', :layout => false
      send_data(export, :type => 'text/html', :filename => "#{@page.title}.html")
      return
    elsif params[:export] == 'txt'
      send_data(@content.text, :type => 'text/plain', :filename => "#{@page.title}.txt")
      return
    end
    render :action => 'show'
  end
  
  # edit an existing page or a new one
  def edit
    @page = @wiki.find_or_new_page(params[:page])    
    @page.content = WikiContent.new(:page => @page) if @page.new_record?
    
    @content = @page.content_for_version(params[:version])
    @content.text = "h1. #{@page.pretty_title}" if @content.text.blank?
    # don't keep previous comment
    @content.comments = nil
    if request.post?      
      if @content.text == params[:content][:text]
        # don't save if text wasn't changed
        redirect_to :action => 'index', :id => @project, :page => @page.title
        return
      end
      @content.text = params[:content][:text]
      @content.comments = params[:content][:comments]
      @content.author = logged_in_user
      # if page is new @page.save will also save content, but not if page isn't a new record
      if (@page.new_record? ? @page.save : @content.save)
        redirect_to :action => 'index', :id => @project, :page => @page.title
      end
    end
  end
  
  # show page history
  def history
    @page = @wiki.find_page(params[:page])
    # don't load text
    @versions = @page.content.versions.find :all, 
                                            :select => "id, author_id, comments, updated_on, version",
                                            :order => 'version DESC'
  end
  
  # remove a wiki page and its history
  def destroy
    @page = @wiki.find_page(params[:page])
    @page.destroy if @page
    redirect_to :action => 'special', :id => @project, :page => 'Page_index'
  end

  # display special pages
  def special
    page_title = params[:page].downcase
    case page_title
    # show pages index, sorted by title
    when 'page_index'
      # eager load information about last updates, without loading text
      @pages = @wiki.pages.find :all, :select => "#{WikiPage.table_name}.*, #{WikiContent.table_name}.updated_on",
                                      :joins => "LEFT JOIN #{WikiContent.table_name} ON #{WikiContent.table_name}.page_id = #{WikiPage.table_name}.id",
                                      :order => 'title'
    # export wiki to a single html file
    when 'export'
      @pages = @wiki.pages.find :all, :order => 'title'
      export = render_to_string :action => 'export_multiple', :layout => false
      send_data(export, :type => 'text/html', :filename => "wiki.html")
      return      
    else
      # requested special page doesn't exist, redirect to default page
      redirect_to :action => 'index', :id => @project, :page => nil and return
    end
    render :action => "special_#{page_title}"
  end
  
  def preview
    @text = params[:content][:text]
    render :partial => 'preview'
  end

private
  
  def find_wiki
    @project = Project.find(params[:id])
    @wiki = @project.wiki
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
