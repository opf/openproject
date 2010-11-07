xml.instruct!
xml.projects :type => 'array' do
  @projects.each do |project|
    xml.project do
      xml.id          project.id
      xml.name        project.name
      xml.identifier  project.identifier
      xml.description project.description
      xml.parent(:id => project.parent_id, :name => project.parent.name) unless project.parent.nil?
      xml.custom_fields do
        project.visible_custom_field_values.each do |custom_value|
          xml.custom_field custom_value.value, :id => custom_value.custom_field_id, :name => custom_value.custom_field.name
        end
      end unless project.custom_field_values.empty?
      xml.created_on  project.created_on
      xml.updated_on  project.updated_on
    end
  end
end
