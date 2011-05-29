module Redmine::MenuManager
  def self.map(menu_name)
    @items ||= {}
    mapper = Mapper.new(menu_name.to_sym, @items)
    if block_given?
      yield mapper
    else
      mapper
    end
  end
  
  def self.items(menu_name)
    @items[menu_name.to_sym] || Redmine::MenuManager::TreeNode.new(:root, {})
  end
end
