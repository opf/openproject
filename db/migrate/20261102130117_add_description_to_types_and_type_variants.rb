# frozen_string_literal: true

class AddDescriptionToTypesAndTypeVariants < ActiveRecord::Migration[8.1]
  def change
    add_column :types, :description, :text
    add_column :type_variants, :description, :text
  end
end
