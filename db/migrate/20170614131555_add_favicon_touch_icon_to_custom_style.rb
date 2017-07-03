class AddFaviconTouchIconToCustomStyle < ActiveRecord::Migration[5.0]
  def change
    add_column :custom_styles, :favicon, :string
    add_column :custom_styles, :touch_icon, :string
  end
end
