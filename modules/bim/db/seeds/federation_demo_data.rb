# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#--

puts "🏗️  Creating Federated Models Demo Data..."

# Find or create demo project
project = Project.find_by(name: 'BIM Demo Project') || Project.create!(
  name: 'BIM Demo Project',
  identifier: 'bim-demo',
  description: 'Demo project for BIM features'
)

# Find or create demo user
admin_user = User.admin.first || User.create!(
  login: 'admin',
  firstname: 'Admin',
  lastname: 'User',
  admin: true,
  mail: 'admin@example.com',
  status: User.statuses[:active]
)

# Create IFC models for different disciplines
puts "  → Creating IFC models for different disciplines..."

architectural_model = Bim::IfcModels::IfcModel.find_or_create_by!(
  project: project,
  title: 'Office Building - Architecture',
  uploader: admin_user,
  conversion_status: :completed
) do |model|
  puts "    ✓ Created Architectural Model"
end

structural_model = Bim::IfcModels::IfcModel.find_or_create_by!(
  project: project,
  title: 'Office Building - Structure',
  uploader: admin_user,
  conversion_status: :completed
) do |model|
  puts "    ✓ Created Structural Model"
end

mechanical_model = Bim::IfcModels::IfcModel.find_or_create_by!(
  project: project,
  title: 'Office Building - HVAC',
  uploader: admin_user,
  conversion_status: :completed
) do |model|
  puts "    ✓ Created Mechanical Model"
end

electrical_model = Bim::IfcModels::IfcModel.find_or_create_by!(
  project: project,
  title: 'Office Building - Electrical',
  uploader: admin_user,
  conversion_status: :completed
) do |model|
  puts "    ✓ Created Electrical Model"
end

plumbing_model = Bim::IfcModels::IfcModel.find_or_create_by!(
  project: project,
  title: 'Office Building - Plumbing',
  uploader: admin_user,
  conversion_status: :completed
) do |model|
  puts "    ✓ Created Plumbing Model"
end

# Add metadata to models for spatial extent
[architectural_model, structural_model, mechanical_model, electrical_model, plumbing_model].each_with_index do |ifc_model, index|
  unless ifc_model.ifc_model_metadata
    metadata = Bim::IfcModels::IfcModelMetadata.create!(
      ifc_model: ifc_model,
      spatial_structure: {
        'extent' => {
          'min' => [index * 10, 0, 0],
          'max' => [(index + 1) * 100, 100, 50]
        },
        'IfcSite' => {
          'name' => 'Project Site',
          'RefLatitude' => 40.7128,
          'RefLongitude' => -74.0060,
          'RefElevation' => 10.0
        }
      },
      element_index: {
        'grid_A' => {
          'type' => 'IfcGrid',
          'name' => 'Grid A',
          'geometry' => { 'position' => [0, 0, 0] }
        },
        'grid_B' => {
          'type' => 'IfcGrid',
          'name' => 'Grid B',
          'geometry' => { 'position' => [50, 0, 0] }
        }
      },
      element_count: (index + 1) * 1000
    )
  end
end

puts "\n  → Creating Model Federations..."

# Federation 1: Full Building Coordination
full_federation = Bim::ModelFederation.find_or_create_by!(
  project: project,
  name: 'Office Building - Full Coordination'
) do |fed|
  fed.description = 'Complete building coordination with all disciplines'
  fed.base_point = { x: 0, y: 0, z: 0 }
  fed.rotation = { x: 0, y: 0, z: 0 }
  fed.units = 'meters'
  puts "    ✓ Created Full Coordination Federation"
end

# Add all models to full federation
[
  { model: architectural_model, discipline: :architectural, order: 0, color: '#3498DB' },
  { model: structural_model, discipline: :structural, order: 1, color: '#E74C3C' },
  { model: mechanical_model, discipline: :mechanical, order: 2, color: '#2ECC71' },
  { model: electrical_model, discipline: :electrical, order: 3, color: '#F39C12' },
  { model: plumbing_model, discipline: :plumbing, order: 4, color: '#9B59B6' }
].each do |config|
  Bim::FederationModel.find_or_create_by!(
    model_federation: full_federation,
    ifc_model: config[:model]
  ) do |fm|
    fm.discipline = config[:discipline]
    fm.display_order = config[:order]
    fm.color = config[:color]
    fm.visible = true
    fm.opacity = 1.0
    fm.transform = {
      'translation' => [0, 0, 0],
      'rotation' => [0, 0, 0],
      'scale' => [1, 1, 1]
    }
  end
end

puts "      → Added 5 models to Full Coordination Federation"

# Federation 2: Architectural + Structural
arch_struct_federation = Bim::ModelFederation.find_or_create_by!(
  project: project,
  name: 'Office Building - Arch + Structure'
) do |fed|
  fed.description = 'Architectural and structural coordination'
  fed.base_point = { x: 0, y: 0, z: 0 }
  fed.rotation = { x: 0, y: 0, z: 0 }
  fed.units = 'meters'
  puts "    ✓ Created Arch + Structure Federation"
end

[
  { model: architectural_model, discipline: :architectural, order: 0 },
  { model: structural_model, discipline: :structural, order: 1 }
].each do |config|
  Bim::FederationModel.find_or_create_by!(
    model_federation: arch_struct_federation,
    ifc_model: config[:model]
  ) do |fm|
    fm.discipline = config[:discipline]
    fm.display_order = config[:order]
    fm.visible = true
    fm.opacity = 1.0
    fm.transform = {
      'translation' => [0, 0, 0],
      'rotation' => [0, 0, 0],
      'scale' => [1, 1, 1]
    }
  end
end

puts "      → Added 2 models to Arch + Structure Federation"

# Federation 3: MEP Coordination
mep_federation = Bim::ModelFederation.find_or_create_by!(
  project: project,
  name: 'Office Building - MEP Only'
) do |fed|
  fed.description = 'Mechanical, Electrical, and Plumbing coordination'
  fed.base_point = { x: 0, y: 0, z: 0 }
  fed.rotation = { x: 0, y: 0, z: 0 }
  fed.units = 'meters'
  puts "    ✓ Created MEP Only Federation"
end

[
  { model: mechanical_model, discipline: :mechanical, order: 0 },
  { model: electrical_model, discipline: :electrical, order: 1 },
  { model: plumbing_model, discipline: :plumbing, order: 2 }
].each do |config|
  Bim::FederationModel.find_or_create_by!(
    model_federation: mep_federation,
    ifc_model: config[:model]
  ) do |fm|
    fm.discipline = config[:discipline]
    fm.display_order = config[:order]
    fm.visible = true
    fm.opacity = config[:discipline] == :mechanical ? 0.7 : 1.0 # Make HVAC semi-transparent
    fm.transform = {
      'translation' => [0, 0, 0],
      'rotation' => [0, 0, 0],
      'scale' => [1, 1, 1]
    }
  end
end

puts "      → Added 3 models to MEP Only Federation"

# Federation 4: Clash Coordination (with transforms)
clash_federation = Bim::ModelFederation.find_or_create_by!(
  project: project,
  name: 'Office Building - Clash Coordination'
) do |fed|
  fed.description = 'Coordination for clash detection with alignment transforms'
  fed.base_point = { x: 100, y: 200, z: 0 }
  fed.rotation = { x: 0, y: 0, z: 0 }
  fed.units = 'meters'
  puts "    ✓ Created Clash Coordination Federation"
end

[
  { model: architectural_model, discipline: :architectural, order: 0, offset: [0, 0, 0] },
  { model: structural_model, discipline: :structural, order: 1, offset: [2, 1, 0] },
  { model: mechanical_model, discipline: :mechanical, order: 2, offset: [0, 0, 3] }
].each do |config|
  Bim::FederationModel.find_or_create_by!(
    model_federation: clash_federation,
    ifc_model: config[:model]
  ) do |fm|
    fm.discipline = config[:discipline]
    fm.display_order = config[:order]
    fm.visible = true
    fm.opacity = 0.8
    fm.transform = {
      'translation' => config[:offset],
      'rotation' => [0, 0, 0],
      'scale' => [1, 1, 1]
    }
  end
end

puts "      → Added 3 models with transforms to Clash Coordination Federation"

# Print summary
puts "\n✅ Federation Demo Data Created Successfully!"
puts "\n📊 Summary:"
puts "  → Projects: 1 (#{project.name})"
puts "  → IFC Models: 5"
puts "    • Architectural: #{architectural_model.title}"
puts "    • Structural: #{structural_model.title}"
puts "    • Mechanical: #{mechanical_model.title}"
puts "    • Electrical: #{electrical_model.title}"
puts "    • Plumbing: #{plumbing_model.title}"
puts "  → Federations: 4"
puts "    • #{full_federation.name} (5 models)"
puts "    • #{arch_struct_federation.name} (2 models)"
puts "    • #{mep_federation.name} (3 models)"
puts "    • #{clash_federation.name} (3 models with transforms)"

puts "\n🎯 To view the federations:"
puts "   rails runner 'puts Bim::ModelFederation.all.map(&:viewer_config).to_yaml'"
