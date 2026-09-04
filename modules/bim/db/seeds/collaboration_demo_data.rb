# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#--

puts "🤝 Creating Collaboration Demo Data..."

# Find or create demo project
project = Project.find_by(name: 'BIM Demo Project') || Project.create!(
  name: 'BIM Demo Project',
  identifier: 'bim-demo',
  description: 'Demo project for BIM features'
)

# Find or create demo users
admin_user = User.admin.first || User.create!(
  login: 'admin',
  firstname: 'Admin',
  lastname: 'User',
  admin: true,
  mail: 'admin@example.com',
  status: User.statuses[:active]
)

architect_user = User.find_or_create_by!(login: 'architect') do |u|
  u.firstname = 'Alice'
  u.lastname = 'Architect'
  u.mail = 'alice.architect@example.com'
  u.status = User.statuses[:active]
  puts "  ✓ Created Architect User"
end

engineer_user = User.find_or_create_by!(login: 'engineer') do |u|
  u.firstname = 'Bob'
  u.lastname = 'Engineer'
  u.mail = 'bob.engineer@example.com'
  u.status = User.statuses[:active]
  puts "  ✓ Created Engineer User"
end

coordinator_user = User.find_or_create_by!(login: 'coordinator') do |u|
  u.firstname = 'Carol'
  u.lastname = 'Coordinator'
  u.mail = 'carol.coordinator@example.com'
  u.status = User.statuses[:active]
  puts "  ✓ Created Coordinator User"
end

users = [admin_user, architect_user, engineer_user, coordinator_user]

# Find or create IFC model
ifc_model = Bim::IfcModels::IfcModel.find_or_create_by!(
  project: project,
  title: 'Office Building - Main Model'
) do |model|
  model.uploader = admin_user
  model.conversion_status = :completed
  puts "  ✓ Created IFC Model"
end

# Create work package and BCF issue
work_package = WorkPackage.find_or_create_by!(
  project: project,
  subject: 'Review wall placement on Floor 2'
) do |wp|
  wp.type = Type.find_or_create_by!(name: 'Task')
  wp.author = architect_user
  wp.status = Status.find_or_create_by!(name: 'New', is_closed: false)
  puts "  ✓ Created Work Package"
end

bcf_issue = Bim::Bcf::Issue.find_or_create_by!(
  work_package: work_package
) do |issue|
  issue.uuid = SecureRandom.uuid
  puts "  ✓ Created BCF Issue"
end

puts "\n  → Creating BCF Comments with Mentions and Reactions..."

# Comment 1: Question with mentions
journal1 = Journal.create!(
  journable: work_package,
  user: architect_user,
  notes: "Hey @engineer and @coordinator, can you review the wall alignment? I think we might have an issue with the structural grid.",
  created_at: 2.days.ago
)

comment1 = Bim::Bcf::Comment.find_or_create_by!(
  uuid: SecureRandom.uuid,
  issue: bcf_issue
) do |c|
  c.journal = journal1
  c.status = 'question'
  c.reactions = {
    '👍' => [engineer_user.id, coordinator_user.id],
    '👀' => [admin_user.id]
  }
end

# Create mentions
Bim::CommentMention.find_or_create_by!(comment: comment1, user: engineer_user)
Bim::CommentMention.find_or_create_by!(comment: comment1, user: coordinator_user)

puts "    ✓ Comment 1 (Question with 2 mentions, 3 reactions)"

# Comment 2: Response with status
journal2 = Journal.create!(
  journable: work_package,
  user: engineer_user,
  notes: "@architect I checked the structural drawings. The wall is 50mm off from Grid Line C. This needs to be fixed before we pour the slab.",
  created_at: 1.day.ago
)

comment2 = Bim::Bcf::Comment.find_or_create_by!(
  uuid: SecureRandom.uuid,
  issue: bcf_issue
) do |c|
  c.journal = journal2
  c.reply_to = comment1.id
  c.status = 'issue'
  c.reactions = {
    '✅' => [architect_user.id, coordinator_user.id],
    '🎉' => [admin_user.id]
  }
end

Bim::CommentMention.find_or_create_by!(comment: comment2, user: architect_user)

puts "    ✓ Comment 2 (Issue response with 1 mention, 3 reactions)"

# Comment 3: Resolution
journal3 = Journal.create!(
  journable: work_package,
  user: architect_user,
  notes: "Thanks @engineer! I've updated the model. The wall is now properly aligned with Grid Line C. @coordinator please verify in the coordination meeting.",
  created_at: 12.hours.ago
)

comment3 = Bim::Bcf::Comment.find_or_create_by!(
  uuid: SecureRandom.uuid,
  issue: bcf_issue
) do |c|
  c.journal = journal3
  c.reply_to = comment2.id
  c.status = 'resolved'
  c.reactions = {
    '👍' => [engineer_user.id, coordinator_user.id, admin_user.id],
    '🚀' => [engineer_user.id]
  }
end

Bim::CommentMention.find_or_create_by!(comment: comment3, user: engineer_user)
Bim::CommentMention.find_or_create_by!(comment: comment3, user: coordinator_user)

puts "    ✓ Comment 3 (Resolved with 2 mentions, 4 reactions)"

# Comment 4: Info update
journal4 = Journal.create!(
  journable: work_package,
  user: coordinator_user,
  notes: "Verified in today's coordination meeting. Change looks good. Marking this as complete.",
  created_at: 6.hours.ago
)

comment4 = Bim::Bcf::Comment.find_or_create_by!(
  uuid: SecureRandom.uuid,
  issue: bcf_issue
) do |c|
  c.journal = journal4
  c.reply_to = comment3.id
  c.status = 'info'
  c.reactions = {
    '✅' => [architect_user.id, engineer_user.id, admin_user.id]
  }
end

puts "    ✓ Comment 4 (Info with 3 reactions)"

puts "\n  → Creating Viewer Presence Records..."

# Create active presence for multiple users
users.each_with_index do |user, index|
  Bim::ViewerPresence.find_or_create_by!(
    ifc_model: ifc_model,
    user: user
  ) do |presence|
    presence.last_seen_at = (index * 30).seconds.ago # Stagger the times
    presence.camera_position = {
      eye: [10 + index * 5, 10, 5 + index * 2],
      look: [0, 0, 0],
      up: [0, 1, 0]
    }
  end
end

puts "    ✓ Created 4 viewer presence records"

# Print summary
puts "\n✅ Collaboration Demo Data Created Successfully!"
puts "\n📊 Summary:"
puts "  → Project: #{project.name}"
puts "  → Users: #{users.size}"
puts "    • #{architect_user.name} (architect)"
puts "    • #{engineer_user.name} (engineer)"
puts "    • #{coordinator_user.name} (coordinator)"
puts "    • #{admin_user.name} (admin)"
puts "  → IFC Model: #{ifc_model.title}"
puts "  → Work Package: #{work_package.subject}"
puts "  → BCF Comments: 4"
puts "    • 1 Question (2 mentions)"
puts "    • 1 Issue (1 mention)"
puts "    • 1 Resolved (2 mentions)"
puts "    • 1 Info"
puts "  → Total Mentions: 5"
puts "  → Total Reactions: 13 across 4 comments"
puts "  → Viewer Presence: 4 active users"

puts "\n🎯 To view the data:"
puts "   # Mentions for a user"
puts "   Bim::CommentMention.for_user(User.find_by(login: 'engineer').id)"
puts ""
puts "   # Comments with reactions"
puts "   Bim::Bcf::Comment.where.not(reactions: '{}')"
puts ""
puts "   # Active viewers"
puts "   Bim::ViewerPresence.active_viewers(Bim::IfcModels::IfcModel.first)"
