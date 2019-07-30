class AddViewpointToBcfComment < ActiveRecord::Migration[5.1]
  def change
    add_reference :bcf_comments, :viewpoint, foreign_key: { to_table: :bcf_viewpoints }, index: true
  end
end
