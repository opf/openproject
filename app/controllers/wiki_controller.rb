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

require 'diff'
require 'htmldiff'

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
  before_filter :find_existing_page, only: [:edit_parent_page,
                                            :update_parent_page,
                                            :rename,
                                            :protect,
                                            :history,
                                            :diff,
                                            :annotate,
                                            :add_attachment,
                                            :list_attachments,
                                            :destroy]
  before_filter :build_wiki_page_and_content, only: [:new, :create]

  verify method: :post, only: [:protect], redirect_to: { action: :show }
  verify method: :get,  only: [:new, :new_child], render: { nothing: true, status: :method_not_allowed }
  verify method: :post, only: :create,            render: { nothing: true, status: :method_not_allowed }

  include AttachmentsHelper
  include PaginationHelper
  include OpenProject::Concerns::Preview

  attr_reader :page, :related_page

  current_menu_item :index do |controller|
    controller.current_menu_item_sym :related_page, '_toc'
  end

  current_menu_item :new_child do |controller|
    controller.current_menu_item_sym :page, '_new_page'
  end

  current_menu_item do |controller|
    controller.current_menu_item_sym :page
  end

  # List of pages, sorted alphabetically and by parent (hierarchy)
  def index
    @related_page = WikiPage.find_by_wiki_id_and_title(@wiki.id, params[:id])

    load_pages_for_index
    @pages_by_parent_id = @pages.group_by(&:parent_id)
  end

  # List of page, by last update
  def date_index
    load_pages_for_index
    @pages_by_date = @pages.group_by { |p| p.updated_on.to_date }
  end

  def new
  end

  def new_child
    find_existing_page
    return if performed?

    old_page = @page

    build_wiki_page_and_content

    @page.parent = old_page
    render action: 'new'
  end

  def create
    @page.attributes = permitted_params.wiki_page

    @content.attributes = permitted_params.wiki_content
    @content.author = User.current

    if @page.save
      attachments = Attachment.attach_files(@page, params[:attachments])
      render_attachment_warning_if_needed(@page)
      call_hook(:controller_wiki_edit_after_save, params: params, page: @page)
      flash[:notice] = l(:notice_successful_create)
      redirect_to_show
    else
      render action: 'new'
    end
  end

  # display a page (in editing mode if it doesn't exist)
  def show
    # TODO FIXME OMG! this is the ugliest hack I ever performed
    # We need to hide the clearfix in the wiki to avoid additional spacing in the wiki
    # THIS HACK NEEDS TO BE REPLACED BY AN ENGINEERS SOLUTION!
    @no_clearfix = true

    page_title = params[:id]
    @page = @wiki.find_or_new_page(page_title)
    if @page.new_record?
      if User.current.allowed_to?(:edit_wiki_pages, @project) && editable?
        edit
        render action: 'edit'
      else
        render_404
      end
      return
    end
    if params[:version] && !User.current.allowed_to?(:view_wiki_edits, @project)
      # Redirects user to the current version if he's not allowed to view previous versions
      redirect_to version: nil
      return
    end
    @content = @page.content_for_version(params[:version])
    if User.current.allowed_to?(:export_wiki_pages, @project)
      if params[:format] == 'html'
        export = render_to_string action: 'export', layout: false
        send_data(export, type: 'text/html', filename: "#{@page.title}.html")
        return
      elsif params[:format] == 'txt'
        send_data(@content.text, type: 'text/plain', filename: "#{@page.title}.txt")
        return
      end
    end
    @editable = editable?
  end

  # edit an existing page or a new one
  def edit
    @page = @wiki.find_or_new_page(params[:id])
    return render_403 unless editable?
    @page.content = WikiContent.new(page: @page) if @page.new_record?

    @content = @page.content_for_version(params[:version])
    @content.text = initial_page_content(@page) if @content.text.blank?
    # don't keep previous comment
    @content.comments = nil

    # To prevent StaleObjectError exception when reverting to a previous version
    @content.lock_version = @page.content.lock_version
  end

  verify method: :put, only: :update, render: { nothing: true, status: :method_not_allowed }
  # Creates a new page or updates an existing one
  def update
    @page = @wiki.find_or_new_page(params[:id])
    return render_403 unless editable?
    @page.content = WikiContent.new(page: @page) if @page.new_record?

    @content = @page.content_for_version(params[:version])
    @content.text = initial_page_content(@page) if @content.text.blank?
    # don't keep previous comment
    @content.comments = nil

    if !@page.new_record? && params[:content].present? && @content.text == params[:content][:text]
      attachments = Attachment.attach_files(@page, params[:attachments])
      render_attachment_warning_if_needed(@page)
      # don't save if text wasn't changed
      redirect_to_show
      return
    end
    @content.attributes = permitted_params.wiki_content
    @content.author = User.current
    @content.add_journal User.current, params['content']['comments']
    # if page is new @page.save will also save content, but not if page isn't a new record
    if @page.new_record? ? @page.save : @content.save
      attachments = Attachment.attach_files(@page, params[:attachments])
      render_attachment_warning_if_needed(@page)
      call_hook(:controller_wiki_edit_after_save,  params: params, page: @page)
      redirect_to_show
    else
      render action: 'edit'
    end

  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash.now[:error] = l(:notice_locking_conflict)
    render action: 'edit'
  end

  # rename a page
  def rename
    return render_403 unless editable?
    @page.redirect_existing_links = true
    # used to display the *original* title if some AR validation errors occur
    @original_title = @page.pretty_title
    if request.put? && @page.update_attributes(permitted_params.wiki_page_rename)
      flash[:notice] = l(:notice_successful_update)
      redirect_to_show
    end
  end

  def edit_parent_page
    return render_403 unless editable?
    @parent_pages = @wiki.pages.all(include: :parent) - @page.self_and_descendants
  end

  def update_parent_page
    return render_403 unless editable?
    @page.parent_id = params[:wiki_page][:parent_id]
    if @page.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to_show
    else
      @parent_pages = @wiki.pages.all(include: :parent) - @page.self_and_descendants
      render 'edit_parent_page'
    end
  end

  def protect
    @page.update_attribute :protected, params[:protected]
    redirect_to_show
  end

  # show page history
  def history
    # don't load text
    @versions = @page.content.versions.select('id, user_id, notes, created_at, version')
                .order('version DESC')
                .page(params[:page])
                .per_page(per_page_param)

    render layout: !request.xhr?
  end

  def diff
    if @diff = @page.diff(params[:version], params[:version_from])
      @html_diff = HTMLDiff::DiffBuilder.new(@diff.content_from.data.text, @diff.content_to.data.text).build
    else
      render_404
    end
  end

  def annotate
    @annotate = @page.annotate(params[:version])
    render_404 unless @annotate
  end

  verify method: :delete, only: [:destroy], redirect_to: { action: :show }
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

    if page = @wiki.find_page(@wiki.start_page) || @wiki.pages.first
      redirect_to action: 'index', project_id: @project, id: page
    else
      redirect_to project_path(@project)
    end
  end

  # Export wiki to a single html file
  def export
    if User.current.allowed_to?(:export_wiki_pages, @project)
      @pages = @wiki.pages.find :all, order: 'title'
      export = render_to_string action: 'export_multiple', layout: false
      send_data(export, type: 'text/html', filename: 'wiki.html')
    else
      redirect_to action: 'show', project_id: @project, id: nil
    end
  end

  def add_attachment
    return render_403 unless editable?
    attachments = Attachment.attach_files(@page, params[:attachments])
    render_attachment_warning_if_needed(@page)
    redirect_to action: 'show', id: @page, project_id: @project
  end

  def list_attachments
    respond_to do |format|
      format.json { render 'common/list_attachments', locals: { attachments: @page.attachments } }
      format.html {}
    end
  end

  def current_menu_item_sym(page, symbol_postfix = '')
    menu_item = send(page).try(:nearest_menu_item)

    menu_item.present? ?
      :"#{menu_item.item_class}#{symbol_postfix}" :
      nil
  end

  protected

  def parse_preview_data
    page = @wiki.find_page(params[:id])
    # page is nil when previewing a new page
    return render_403 unless page.nil? || editable?(page)

    attachments = page && page.attachments
    previewed = page && page.content

    text = { WikiPage.human_attribute_name(:content) => params[:content][:text] }

    [text, attachments, previewed]
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
    @page = @wiki.find_page(params[:id])
    render_404 if @page.nil?
  end

  def build_wiki_page_and_content
    @page = WikiPage.new wiki: @wiki
    @page.content = WikiContent.new page: @page

    @content = @page.content_for_version nil
    @content.text = initial_page_content @page
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

  def load_pages_for_index
    @pages = @wiki.pages.with_updated_on.all(order: 'title', include: { wiki: :project })
  end

  def default_breadcrumb
    Wiki.name.humanize
  end

  def redirect_to_show
    redirect_to action: :show, project_id: @project, id: @page
  end
end
