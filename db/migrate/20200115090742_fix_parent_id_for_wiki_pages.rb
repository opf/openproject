class FixParentIdForWikiPages < ActiveRecord::Migration[6.0]
  class MyWikiPages < ActiveRecord::Base
    self.table_name = "wiki_pages"
  end

  def up
    MyWikiPages.where(parent_id: 0).update_all(parent_id: nil)
  end
end
