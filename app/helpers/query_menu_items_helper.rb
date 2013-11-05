module QueryMenuItemsHelper
  def update_query_menu_item_path(project, query_menu_item)
    query_menu_item.persisted? ? query_menu_item_path(project, query_menu_item.query, query_menu_item) : query_menu_items_path(project, query_menu_item.query)
  end
end