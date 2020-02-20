class MigrateXmlViewpointToJson < ActiveRecord::Migration[6.0]
  def up
    # Add JSON viewpoint
    change_table :bcf_viewpoints do |t|
      t.jsonb :json_viewpoint
    end

    # Convert viewpoints
    ::Bim::Bcf::Viewpoint.reset_column_information
    ::Bim::Bcf::Viewpoint.find_each do |resource|
      mapper = ::OpenProject::Bim::BcfJson::ViewpointReader
        .new(resource.uuid, resource.viewpoint)

      resource.update_column(:json_viewpoint, mapper.result)

      Rails.logger.debug { "Converted viewpoint (##{resource.id}) #{resource.uuid} to JSON." }
    rescue => e
      warn "Failed to convert viewpoint #{viewpoint.uuid}: #{e} #{e.message}"
    end

    # Remove the old XML viewpoint
    change_table :bcf_viewpoints do |t|
      t.remove :viewpoint
    end
  end

  def down
    raise "Cannot be reverted yet!"
  end
end
