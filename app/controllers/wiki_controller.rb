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

require 'diff'

# The WikiController follows the Rails REST controller pattern but with
# a few differences
#
# * index - shows a list of WikiPages grouped by page or date
# * new - not used
# * create - not used
# * show - will also show the form for creating a new wiki page
# * edit - used to edit an existing or new page
# * update - used to save a wiki page update to the database, including new pages
# * destroy - normal
#
# Other member and collection methods are also used
#
# TODO: still being worked on
class WikiController < ApplicationController
  default_search_scope :wiki_pages
  before_filter :find_wiki, :authorize
  before_filter :find_existing_page, :only => [:rename, :protect, :history, :diff, :annotate, :add_attachment, :destroy]
  
  verify :method => :post, :only => [:protect], :redirect_to => { :action => :show }

  helper :attachments
  include AttachmentsHelper   
  helper :watchers

  # List of pages, sorted alphabetically and by parent (hierarchy)
  def index
    load_pages_grouped_by_date_without_content
  end

  # display a page (in editing mode if it doesn't exist)
  def show
    page_title = params[:page]
    @page = @wiki.find_or_new_page(page_title)
    if @page.new_record?
      if User.current.allowed_to?(:edit_wiki_pages, @project) && editable?
        edit
        render :action => 'edit'
      else
        render_404
      end
      return
    end
    if params[:version] && !User.current.allowed_to?(:view_wiki_edits, @project)
      # Redirects user to the current version if he's not allowed to view previous versions
      redirect_to :version => nil
      return
    end
    @content = @page.content_for_version(params[:version])
    if User.current.allowed_to?(:export_wiki_pages, @project)
      if params[:format] == 'html'
        export = render_to_string :action => 'export', :layout => false
        send_data(export, :type => 'text/html', :filename => "#{@page.title}.html")
        return
      elsif params[:format] == 'txt'
        send_data(@content.text, :type => 'text/plain', :filename => "#{@page.title}.txt")
        return
      end
    end
    @editable = editable?
    render :action => 'show'
  end
  
  # edit an existing page or a new one
  def edit
    @page = @wiki.find_or_new_page(params[:page])    
    return render_403 unless editable?
    @page.content = WikiContent.new(:page => @page) if @page.new_record?
    
    @content = @page.content_for_version(params[:version])
    @content.text = initial_page_content(@page) if @content.text.blank?
    # don't keep previous comment
    @content.comments = nil

    # To prevent StaleObjectError exception when reverting to a previous version
    @content.version = @page.content.version
  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash[:error] = l(:notice_locking_conflict)
  end

  verify :method => :post, :only => :update, :render => {:nothing => true, :status => :method_not_allowed }
  # Creates a new page or updates an existing one
  def update
    @page = @wiki.find_or_new_page(params[:page])    
    return render_403 unless editable?
    @page.content = WikiContent.new(:page => @page) if @page.new_record?
    
    @content = @page.content_for_version(params[:version])
    @content.text = initial_page_content(@page) if @content.text.blank?
    # don't keep previous comment
    @content.comments = nil

    if !@page.new_record? && params[:content].present? && @content.text == params[:content][:text]
      attachments = Attachment.attach_files(@page, params[:attachments])
      render_attachment_warning_if_needed(@page)
      # don't save if text wasn't changed
      redirect_to :action => 'show', :project_id => @project, :page => @page.title
      return
    end
    @content.attributes = params[:content]
    @content.author = User.current
    # if page is new @page.save will also save content, but not if page isn't a new record
    if (@page.new_record? ? @page.save : @content.save)
      attachments = Attachment.attach_files(@page, params[:attachments])
      render_attachment_warning_if_needed(@page)
      call_hook(:controller_wiki_edit_after_save, { :params => params, :page => @page})
      redirect_to :action => 'show', :project_id => @project, :page => @page.title
    end

  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash[:error] = l(:notice_locking_conflict)
  end

  # rename a page
  def rename
    return render_403 unless editable?
    @page.redirect_existing_links = true
    # used to display the *original* title if some AR validation errors occur
    @original_title = @page.pretty_title
    if request.post? && @page.update_attributes(params[:wiki_page])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'show', :project_id => @project, :page => @page.title
    end
  end
  
  def protect
    @page.update_attribute :protected, params[:protected]
    redirect_to :action => 'show', :project_id => @project, :page => @page.title
  end

  # show page history
  def history
    @version_count = @page.content.versions.count
    @version_pages = Paginator.new self, @version_count, per_page_option, params['p']
    # don't load text    
    @versions = @page.content.versions.find :all, 
                                            :select => "id, author_id, comments, updated_on, version",
                                            :order => 'version DESC',
                                            :limit  =>  @version_pages.items_per_page + 1,
                                            :offset =>  @version_pages.current.offset

    render :layout => false if request.xhr?
  end
  
  def diff
    @diff = @page.diff(params[:version], params[:version_from])
    render_404 unless @diff
  end
  
  def annotate
    @annotate = @page.annotate(params[:version])
    render_404 unless @annotate
  end

  verify :method => :delete, :only => [:destroy], :redirect_to => { :action => :show }
  # Removes a wiki page and its history
  # Children can be either set as root pages, removed or reassigned to another parent page
  def destroy
    return render_403 unless editable?
    
    @descendants_count = @page.descendants.size
    if @descendants_count > 0
      case params[:todo]
      when 'nullify'
        # Nothing to do
      when 'destroy'
        # Removes all its descendants
        @page.descendants.each(&:destroy)
      when 'reassign'
        # Reassign children to another parent page
        reassign_to = @wiki.pages.find_by_id(params[:reassign_to_id].to_i)
        return unless reassign_to
        @page.children.each do |child|
          child.update_attribute(:parent, reassign_to)
        end
      else
        @reassignable_to = @wiki.pages - @page.self_and_descendants
        return
      end
    end
    @page.destroy
    redirect_to :action => 'index', :project_id => @project
  end

  # Export wiki to a single html file
  def export
    if User.current.allowed_to?(:export_wiki_pages, @project)
      @pages = @wiki.pages.find :all, :order => 'title'
      export = render_to_string :action => 'export_multiple', :layout => false
      send_data(export, :type => 'text/html', :filename => "wiki.html")
    else
      redirect_to :action => 'show', :project_id => @project, :page => nil
    end
  end

  def date_index
    load_pages_grouped_by_date_without_content
  end
  
  def preview
    page = @wiki.find_page(params[:page])
    # page is nil when previewing a new page
    return render_403 unless page.nil? || editable?(page)
    if page
      @attachements = page.attachments
      @previewed = page.content
    end
    @text = params[:content][:text]
    render :partial => 'common/preview'
  end

  def add_attachment
    return render_403 unless editable?
    attachments = Attachment.attach_files(@page, params[:attachments])
    render_attachment_warning_if_needed(@page)
    redirect_to :action => 'show', :page => @page.title
  end

private
  
  def find_wiki
    @project = Project.find(params[:project_id])
    @wiki = @project.wiki
    render_404 unless @wiki
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  # Finds the requested page and returns a 404 error if it doesn't exist
  def find_existing_page
    @page = @wiki.find_page(params[:page])
    render_404 if @page.nil?
  end
  
  # Returns true if the current user is allowed to edit the page, otherwise false
  def editable?(page = @page)
    page.editable_by?(User.current)
  end

  # Returns the default content of a new wiki page
  def initial_page_content(page)
    helper = Redmine::WikiFormatting.helper_for(Setting.text_formatting)
    extend helper unless self.instance_of?(helper)
    helper.instance_method(:initial_page_content).bind(self).call(page)
  end

  # eager load information about last updates, without loading text
  def load_pages_grouped_by_date_without_content
    @pages = @wiki.pages.find :all, :select => "#{WikiPage.table_name}.*, #{WikiContent.table_name}.updated_on",
                                    :joins => "LEFT JOIN #{WikiContent.table_name} ON #{WikiContent.table_name}.page_id = #{WikiPage.table_name}.id",
                                    :order => 'title'
    @pages_by_date = @pages.group_by {|p| p.updated_on.to_date}
    @pages_by_parent_id = @pages.group_by(&:parent_id)
  end
  
end
