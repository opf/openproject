class AddDefaultDocumentCategoriesData < ActiveRecord::Migration
  def up
    unless DocumentCategory.any?
      require "i18n"
      DocumentCategory.create!(:name => I18n.t(:default_doc_category_user), :position => 1)
      DocumentCategory.create!(:name => I18n.t(:default_doc_category_tech), :position => 2)
    end
  end

  def down
    DocumentCategory.destroy_all
  end
end
