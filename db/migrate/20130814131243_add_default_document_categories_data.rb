class AddDefaultDocumentCategoriesData < ActiveRecord::Migration
  def self.up
    unless DocumentCategory.any?
      DocumentCategory.create!(:name => l(:default_doc_category_user), :position => 1)
      DocumentCategory.create!(:name => l(:default_doc_category_tech), :position => 2)
    end
  end

  def self.down
    DocumentCategory.destroy_all
  end
end
