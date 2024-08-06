#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

class WikiMenuItemsController < ApplicationController
  attr_reader :wiki_menu_item

  include Redmine::MenuManager::WikiMenuHelper

  current_menu_item :edit do |controller|
    next controller.wiki_menu_item.menu_identifier if controller.wiki_menu_item.try(:persisted?)

    project = controller.instance_variable_get(:@project)
    if (page = WikiPage.find_by(wiki_id: project.wiki.id, slug: controller.params[:id]))
      default_menu_item(controller, page)
    end
  end

  current_menu_item :select_main_menu_item do |controller|
    next controller.wiki_menu_item.menu_identifier if controller.wiki_menu_item.try(:persisted?)

    if (page = WikiPage.find_by(id: controller.params[:id]))
      default_menu_item(controller, page)
    end
  end

  def self.default_menu_item(controller, page)
    menu_item = controller.default_menu_item(page)
    return unless menu_item

    :"no-menu-item-#{menu_item.menu_identifier}"
  end

  before_action :find_project_by_project_id
  before_action :authorize

  def edit
    get_data_from_params(params)
  end

  def update
    wiki_menu_setting = wiki_menu_item_params[:setting]
    parent_wiki_menu_item = params[:parent_wiki_menu_item]

    get_data_from_params(params)

    if wiki_menu_setting == "no_item"
      unless @wiki_menu_item.nil?
        if @wiki_menu_item.is_only_main_item?
          if @page.only_wiki_page?
            flash.now[:error] = t(:wiki_menu_item_delete_not_permitted)
            render(:edit, id: @page_title) and return
          else
            redirect_to(select_main_menu_item_project_wiki_path(@project, @page.id)) and return
          end
        else
          @wiki_menu_item.destroy
        end
      end
    else
      @wiki_menu_item.navigatable_id = @page.wiki.id
      @wiki_menu_item.name = @page.slug
      @wiki_menu_item.title = wiki_menu_item_params[:title] || @page_title

      if wiki_menu_setting == "sub_item"
        @wiki_menu_item.parent_id = parent_wiki_menu_item
      elsif wiki_menu_setting == "main_item"
        @wiki_menu_item.parent_id = nil
        assign_wiki_menu_item_params @wiki_menu_item
      end
    end

    if @wiki_menu_item.destroyed? || @wiki_menu_item.save
      # we may have just destroyed a new record
      # e.g. there was no menu_item before, and there is none now
      if !@wiki_menu_item.new_record? && (@wiki_menu_item.changed? || @wiki_menu_item.destroyed?)
        flash[:notice] = t(:notice_successful_update)
      end

      redirect_back_or_default(action: "edit", id: @page)
    else
      respond_to do |format|
        format.html do
          render action: "edit", id: @page
        end
      end
    end
  end

  def select_main_menu_item
    @page = WikiPage.find params[:id]
    @possible_wiki_pages = @project
                           .wiki
                           .pages
                           .includes(:parent)
                           .reject do |page|
                             page != @page &&
                               page.menu_item.present? &&
                               page.menu_item.is_main_item?
                           end
  end

  def replace_main_menu_item
    current_page = WikiPage.find params[:id]

    if (current_menu_item = current_page.menu_item) && (page = WikiPage.find_by(id: params[:wiki_page][:id])) && current_menu_item != page.menu_item
      create_main_menu_item_for_wiki_page(page, current_menu_item.options)
      current_menu_item.destroy
    end

    redirect_to action: :edit, id: current_page
  end

  private

  def wiki_menu_item_params
    @wiki_menu_item_params ||= params.require(:menu_items_wiki_menu_item).permit(:name, :title, :navigatable_id, :parent_id,
                                                                                 :setting, :new_wiki_page, :index_page)
  end

  def get_data_from_params(params)
    wiki = @project.wiki

    @page = wiki.find_page(params[:id])
    @page_title = @page.title
    @wiki_menu_item = MenuItems::WikiMenuItem
                      .where(navigatable_id: wiki.id, name: @page.slug)
                      .first_or_initialize(title: @page_title)

    possible_parent_menu_items = MenuItems::WikiMenuItem.main_items(wiki.id) - [@wiki_menu_item]

    @parent_menu_item_options = possible_parent_menu_items.map { |item| [item.name, item.id] }

    @selected_parent_menu_item_id = if @wiki_menu_item.parent
                                      @wiki_menu_item.parent.id
                                    else
                                      @page.nearest_main_item.try :id
                                    end
  end

  def assign_wiki_menu_item_params(menu_item)
    if wiki_menu_item_params[:new_wiki_page] == "1"
      menu_item.new_wiki_page = true
    elsif wiki_menu_item_params[:new_wiki_page] == "0"
      menu_item.new_wiki_page = false
    end

    if wiki_menu_item_params[:index_page] == "1"
      menu_item.index_page = true
    elsif wiki_menu_item_params[:index_page] == "0"
      menu_item.index_page = false
    end
  end

  def create_main_menu_item_for_wiki_page(page, options = {})
    wiki = page.wiki

    menu_item = if item = page.menu_item
                  item.tap { |item| item.parent_id = nil }
                else
                  wiki.wiki_menu_items.build(name: page.slug, title: page.title)
                end

    menu_item.options = options
    menu_item.save
  end
end
