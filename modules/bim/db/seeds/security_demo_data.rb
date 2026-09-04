# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#--

puts "🔐 Creating Security & Authentication Demo Data..."

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
end

engineer_user = User.find_or_create_by!(login: 'engineer') do |u|
  u.firstname = 'Bob'
  u.lastname = 'Engineer'
  u.mail = 'bob.engineer@example.com'
  u.status = User.statuses[:active]
end

api_user = User.find_or_create_by!(login: 'api_service') do |u|
  u.firstname = 'API'
  u.lastname = 'Service'
  u.mail = 'api@example.com'
  u.status = User.statuses[:active]
  puts "  ✓ Created API Service User"
end

users = [admin_user, architect_user, engineer_user, api_user]

puts "\n  → Creating API Tokens..."

# Create API tokens for different use cases
revit_token = Bim::ApiToken.find_or_create_by!(
  user: architect_user,
  name: 'Revit Plugin Integration'
) do |token|
  token_obj, plain_token = Bim::ApiToken.generate(
    user: architect_user,
    name: 'Revit Plugin Integration',
    description: 'Token for automated model uploads from Revit',
    scopes: ['read:models', 'write:models', 'read:clashes'],
    expires_in: 90.days,
    project: project
  )

  # For demo, we'll use the generated token
  token.token_hash = token_obj.token_hash
  token.token_prefix = token_obj.token_prefix
  token.description = token_obj.description
  token.scopes = token_obj.scopes
  token.expires_at = token_obj.expires_at
  token.project = project

  # Simulate some usage
  token.last_used_at = 2.hours.ago
  token.last_used_ip = '192.168.1.100'
  token.usage_count = 47

  puts "    ✓ Revit Integration Token (47 uses, expires in 90 days)"
end

ci_token = Bim::ApiToken.find_or_create_by!(
  user: api_user,
  name: 'CI/CD Pipeline'
) do |token|
  token_obj, _plain = Bim::ApiToken.generate(
    user: api_user,
    name: 'CI/CD Pipeline',
    description: 'Automated testing and validation pipeline',
    scopes: ['read:models', 'run:clashes', 'read:baselines'],
    project: project
  )

  token.token_hash = token_obj.token_hash
  token.token_prefix = token_obj.token_prefix
  token.description = token_obj.description
  token.scopes = token_obj.scopes
  token.expires_at = nil # Never expires
  token.project = project

  # Heavy usage
  token.last_used_at = 15.minutes.ago
  token.last_used_ip = '10.0.2.50'
  token.usage_count = 1523

  puts "    ✓ CI/CD Pipeline Token (1523 uses, never expires)"
end

dashboard_token = Bim::ApiToken.find_or_create_by!(
  user: engineer_user,
  name: 'Dashboard Integration'
) do |token|
  token_obj, _plain = Bim::ApiToken.generate(
    user: engineer_user,
    name: 'Dashboard Integration',
    description: 'Read-only access for external dashboard',
    scopes: ['read:models', 'read:clashes', 'read:baselines', 'read:dashboards'],
    expires_in: 30.days,
    project: project
  )

  token.token_hash = token_obj.token_hash
  token.token_prefix = token_obj.token_prefix
  token.description = token_obj.description
  token.scopes = token_obj.scopes
  token.expires_at = token_obj.expires_at
  token.project = project

  # Recent light usage
  token.last_used_at = 30.minutes.ago
  token.last_used_ip = '192.168.1.200'
  token.usage_count = 12

  puts "    ✓ Dashboard Integration Token (12 uses, expires in 30 days)"
end

# Create an expired token
expired_token = Bim::ApiToken.find_or_create_by!(
  user: architect_user,
  name: 'Old Test Token (Expired)'
) do |token|
  token_obj, _plain = Bim::ApiToken.generate(
    user: architect_user,
    name: 'Old Test Token (Expired)',
    description: 'Legacy token that has expired',
    scopes: ['read:models'],
    expires_in: -7.days, # Expired 7 days ago
    project: project
  )

  token.token_hash = token_obj.token_hash
  token.token_prefix = token_obj.token_prefix
  token.description = token_obj.description
  token.scopes = token_obj.scopes
  token.expires_at = token_obj.expires_at
  token.project = project

  token.last_used_at = 10.days.ago
  token.last_used_ip = '192.168.1.100'
  token.usage_count = 3

  puts "    ✓ Expired Token (expired 7 days ago)"
end

# Create a revoked token
revoked_token = Bim::ApiToken.find_or_create_by!(
  user: api_user,
  name: 'Revoked Testing Token'
) do |token|
  token_obj, _plain = Bim::ApiToken.generate(
    user: api_user,
    name: 'Revoked Testing Token',
    description: 'Token that was revoked for security reasons',
    scopes: ['admin:all'],
    project: project
  )

  token.token_hash = token_obj.token_hash
  token.token_prefix = token_obj.token_prefix
  token.description = token_obj.description
  token.scopes = token_obj.scopes
  token.project = project
  token.active = false # Revoked

  token.last_used_at = 5.days.ago
  token.last_used_ip = '10.0.2.50'
  token.usage_count = 8

  puts "    ✓ Revoked Token (revoked for security review)"
end

puts "\n  → Creating Audit Log Entries..."

# Sample audit logs for the past 30 days
audit_logs_created = 0

# Model uploads
3.times do |i|
  Bim::AuditLog.create!(
    user: architect_user,
    project: project,
    action_type: :model_upload,
    details: {
      model_id: 100 + i,
      file_name: "architecture_floor_#{i + 1}.ifc",
      file_size: (10 + i * 5) * 1024 * 1024,
      duration_seconds: 45 + i * 15
    },
    ip_address: '192.168.1.100',
    user_agent: 'OpenProject-Revit-Plugin/2.1',
    request_id: SecureRandom.uuid,
    created_at: (5 + i).days.ago
  )
  audit_logs_created += 1
end
puts "    ✓ 3 model upload logs"

# Clash detection runs
2.times do |i|
  Bim::AuditLog.create!(
    user: engineer_user,
    project: project,
    action_type: :clash_detection_run,
    details: {
      model_ids: [100, 101],
      clash_count: 15 - i * 5,
      tolerance: 0.01,
      disciplines: %w[architecture structure],
      duration_seconds: 120
    },
    ip_address: '192.168.1.150',
    user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    request_id: SecureRandom.uuid,
    created_at: (3 + i).days.ago
  )
  audit_logs_created += 1
end
puts "    ✓ 2 clash detection logs"

# Baseline creation
Bim::AuditLog.create!(
  user: architect_user,
  project: project,
  action_type: :baseline_created,
  details: {
    baseline_id: 1,
    baseline_name: 'Design Development - Week 12',
    element_count: 1542,
    snapshot_size: 2.3 # MB
  },
  ip_address: '192.168.1.100',
  user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
  request_id: SecureRandom.uuid,
  created_at: 2.days.ago
)
audit_logs_created += 1
puts "    ✓ 1 baseline creation log"

# API token operations (security sensitive)
Bim::AuditLog.create!(
  user: admin_user,
  project: project,
  action_type: :api_token_created,
  details: {
    token_id: revit_token.id,
    token_name: revit_token.name,
    scopes: revit_token.scopes,
    expires_at: revit_token.expires_at&.iso8601
  },
  ip_address: '192.168.1.50',
  user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X)',
  request_id: SecureRandom.uuid,
  created_at: 10.days.ago
)
audit_logs_created += 1

Bim::AuditLog.create!(
  user: admin_user,
  project: project,
  action_type: :api_token_revoked,
  details: {
    token_id: revoked_token.id,
    token_name: revoked_token.name,
    reason: 'Security review - excessive permissions'
  },
  ip_address: '192.168.1.50',
  user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X)',
  request_id: SecureRandom.uuid,
  created_at: 5.days.ago
)
audit_logs_created += 1
puts "    ✓ 2 API token operation logs (security sensitive)"

# Permission changes (security sensitive)
Bim::AuditLog.create!(
  user: admin_user,
  project: project,
  action_type: :permission_changed,
  details: {
    target_user_id: engineer_user.id,
    target_user_name: engineer_user.name,
    old_role: 'member',
    new_role: 'manager',
    permission_scope: 'project'
  },
  ip_address: '192.168.1.50',
  user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X)',
  request_id: SecureRandom.uuid,
  created_at: 7.days.ago
)
audit_logs_created += 1
puts "    ✓ 1 permission change log (security sensitive)"

# Data export (security sensitive)
Bim::AuditLog.create!(
  user: admin_user,
  project: project,
  action_type: :data_exported,
  details: {
    export_type: 'audit_logs',
    format: 'csv',
    record_count: 150,
    time_period: '30 days',
    file_size: 0.5 # MB
  },
  ip_address: '192.168.1.50',
  user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X)',
  request_id: SecureRandom.uuid,
  created_at: 1.day.ago
)
audit_logs_created += 1
puts "    ✓ 1 data export log (security sensitive)"

# Dashboard creation
Bim::AuditLog.create!(
  user: engineer_user,
  project: project,
  action_type: :dashboard_created,
  details: {
    dashboard_id: 1,
    dashboard_name: 'Project Health Dashboard',
    widget_count: 5
  },
  ip_address: '192.168.1.150',
  user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
  request_id: SecureRandom.uuid,
  created_at: 4.days.ago
)
audit_logs_created += 1
puts "    ✓ 1 dashboard creation log"

# Federation creation
Bim::AuditLog.create!(
  user: architect_user,
  project: project,
  action_type: :federation_created,
  details: {
    federation_id: 1,
    federation_name: 'Multi-Discipline Coordination',
    model_count: 3,
    disciplines: %w[architecture structure mep]
  },
  ip_address: '192.168.1.100',
  user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
  request_id: SecureRandom.uuid,
  created_at: 6.days.ago
)
audit_logs_created += 1
puts "    ✓ 1 federation creation log"

# Security review (security sensitive)
Bim::AuditLog.create!(
  user: nil, # System action
  project: project,
  action_type: :security_review,
  details: {
    review_type: 'automated_scan',
    findings_count: 0,
    status: 'passed',
    scanned_items: %w[api_tokens permissions audit_logs]
  },
  ip_address: nil,
  user_agent: 'OpenProject-SecurityScanner/1.0',
  request_id: SecureRandom.uuid,
  created_at: 12.hours.ago
)
audit_logs_created += 1
puts "    ✓ 1 security review log (system action)"

# Add some older audit logs for time-based filtering demo
5.times do |i|
  Bim::AuditLog.create!(
    user: [architect_user, engineer_user, api_user].sample,
    project: project,
    action_type: [:model_upload, :clash_detection_run, :comparison_created].sample,
    details: { note: "Historical log #{i + 1}" },
    ip_address: "192.168.1.#{100 + rand(100)}",
    user_agent: 'Mozilla/5.0',
    request_id: SecureRandom.uuid,
    created_at: (30 + i * 10).days.ago
  )
  audit_logs_created += 1
end
puts "    ✓ 5 historical logs (30+ days old)"

# Print summary
puts "\n✅ Security & Authentication Demo Data Created Successfully!"
puts "\n📊 Summary:"
puts "  → Project: #{project.name}"
puts "  → Users: #{users.size}"
users.each do |user|
  puts "    • #{user.name} (#{user.login})"
end

puts "\n  🔑 API Tokens: 5"
puts "    • Revit Plugin Integration"
puts "      - User: #{architect_user.name}"
puts "      - Scopes: read:models, write:models, read:clashes"
puts "      - Status: Active (#{revit_token.usage_count} uses)"
puts "      - Expires: #{revit_token.days_until_expiration} days"
puts ""
puts "    • CI/CD Pipeline"
puts "      - User: #{api_user.name}"
puts "      - Scopes: read:models, run:clashes, read:baselines"
puts "      - Status: Active (#{ci_token.usage_count} uses)"
puts "      - Expires: Never"
puts ""
puts "    • Dashboard Integration"
puts "      - User: #{engineer_user.name}"
puts "      - Scopes: read:models, read:clashes, read:baselines, read:dashboards"
puts "      - Status: Active (#{dashboard_token.usage_count} uses)"
puts "      - Expires: #{dashboard_token.days_until_expiration} days"
puts ""
puts "    • Old Test Token"
puts "      - User: #{architect_user.name}"
puts "      - Status: Expired (#{expired_token.days_until_expiration.abs} days ago)"
puts ""
puts "    • Revoked Testing Token"
puts "      - User: #{api_user.name}"
puts "      - Status: Revoked (security review)"

puts "\n  📝 Audit Logs: #{audit_logs_created}"
puts "    • Model Uploads: 3"
puts "    • Clash Detections: 2"
puts "    • Baseline Created: 1"
puts "    • Dashboard Created: 1"
puts "    • Federation Created: 1"
puts "    • API Token Created: 1 (security sensitive)"
puts "    • API Token Revoked: 1 (security sensitive)"
puts "    • Permission Changed: 1 (security sensitive)"
puts "    • Data Exported: 1 (security sensitive)"
puts "    • Security Review: 1 (security sensitive)"
puts "    • Historical Logs: 5 (30+ days old)"
puts ""
puts "    → Security Sensitive Actions: 5"
puts "    → Regular Actions: 8"
puts "    → Time Range: Last 40 days"

puts "\n🎯 To explore the data:"
puts "   # View all API tokens for a user"
puts "   Bim::ApiToken.for_user(User.find_by(login: 'architect').id)"
puts ""
puts "   # View active tokens"
puts "   Bim::ApiToken.active.not_expired"
puts ""
puts "   # View audit logs for project"
puts "   Bim::AuditLog.for_project(#{project.id}).recent.limit(10)"
puts ""
puts "   # View security sensitive actions"
puts "   Bim::AuditLog.for_project(#{project.id}).select(&:security_sensitive?)"
puts ""
puts "   # Generate security report"
puts "   service = Bim::Security::AuditService.new(user: User.admin.first, project: Project.find(#{project.id}))"
puts "   report = service.generate_security_report(since: 30.days.ago)"
puts ""
puts "   # Export audit logs to CSV"
puts "   csv = service.export_to_csv(since: 30.days.ago)"
puts ""
puts "   # Activity summary"
puts "   Bim::AuditLog.activity_summary(#{project.id}, since: 30.days.ago)"
puts ""
puts "   # Top users by activity"
puts "   Bim::AuditLog.top_users(#{project.id}, limit: 5)"
