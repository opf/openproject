class WikiMenuItemsController < ApplicationController
  def edit
    get_data_from_params(params)
  end

  def update
    wiki_menu_setting = params[:wiki_menu_item][:setting]
    parent_wiki_menu_item = params[:parent_wiki_menu_item]

    get_data_from_params(params)

    if wiki_menu_setting == 'no_item'
      @wiki_menu_item.destroy unless @wiki_menu_item.nil?
    else
      @wiki_menu_item.wiki_id = @page.wiki.id
      @wiki_menu_item.name = params[:wiki_menu_item][:name]
      @wiki_menu_item.title = @page_title

      if wiki_menu_setting == 'sub_item'
        @wiki_menu_item.parent_id = parent_wiki_menu_item
      elsif wiki_menu_setting == 'main_item'
        @wiki_menu_item.parent_id = nil

        if params[:wiki_menu_item][:new_wiki_page] == "1"
          @wiki_menu_item.new_wiki_page = true
        elsif params[:wiki_menu_item][:new_wiki_page] == "0"
          @wiki_menu_item.new_wiki_page = false
        end

        if params[:wiki_menu_item][:index_page] == "1"
          @wiki_menu_item.index_page = true
        elsif params[:wiki_menu_item][:index_page] == "0"
          @wiki_menu_item.index_page = false
        end
      end
    end

    if not @wiki_menu_item.errors.size >= 1 and (@wiki_menu_item.destroyed? or @wiki_menu_item.save)
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default({ :action => 'edit', :id => @page_title })
    else
      respond_to do |format|
        format.html { render :action => 'edit', :id => @page_title }
      end
    end
  end

  private

  def get_data_from_params(params)
    @project = Project.find(params[:project_id])

    @page_title = params[:id]
    @page = WikiPage.find_by_title_and_wiki_id(@page_title, @project.wiki.id)


    @wiki_menu_item = WikiMenuItem.find_or_initialize_by_wiki_id_and_title(@page.wiki.id, @page_title)

    @possible_parent_menu_items = WikiMenuItem.main_items(@page.wiki.id) - [@wiki_menu_item]
    @possible_parent_menu_items.map! {|item| [item.name, item.id]}
  end
end
