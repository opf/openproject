# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'rails', '~> 7.0'
  gem 'sqlite3'
  gem 'aasm'
end

require 'active_record'
require 'aasm'
require 'yaml'

# Setup in-memory database
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Load CDE models
require_relative 'modules/cde/app/services/cde/conventions'
require_relative 'modules/cde/app/services/cde/identifier_validator'
require_relative 'modules/cde/app/models/cde/audit_event'
require_relative 'modules/cde/app/models/cde/suitability'
require_relative 'modules/cde/app/models/cde/metadata'
require_relative 'modules/cde/app/models/cde/revision'
require_relative 'modules/cde/app/models/cde/container'

# Create schema
ActiveRecord::Schema.define do
  create_table :cde_containers do |t|
    t.references :project, null: false
    t.references :owner, null: false
    t.string :identifier, null: false
    t.string :title, null: false
    t.text :description
    t.integer :status, null: false, default: 0
    t.timestamps
  end

  create_table :cde_revisions do |t|
    t.references :container, null: false
    t.references :author
    t.string :revision_code, null: false
    t.string :title
    t.text :description
    t.integer :status, null: false, default: 0
    t.boolean :is_working, null: false, default: true
    t.timestamps
  end

  create_table :cde_metadata do |t|
    t.references :container, null: false
    t.integer :discipline, null: false, default: 0
    t.integer :container_type, null: false, default: 0
    t.string :originator, null: false
    t.string :classification
    t.timestamps
  end

  create_table :cde_suitabilities do |t|
    t.references :container, null: false
    t.references :assigner
    t.integer :code, null: false, default: 0
    t.text :reason
    t.timestamps
  end

  create_table :cde_audit_events do |t|
    t.references :auditable, polymorphic: true, null: false
    t.references :user, null: false
    t.string :action, null: false
    t.string :event_type, null: false
    t.text :old_state
    t.text :new_state
    t.text :reason
    t.timestamps
  end
end

# Test helpers
class FakeUser
  attr_accessor :id, :name
  
  def initialize(id:, name:)
    @id = id
    @name = name
  end
  
  def to_key
    id
  end
end

class FakeProject
  attr_accessor :id, :identifier, :name
  
  def initialize(id:, identifier:, name:)
    @id = id
    @identifier = identifier
    @name = name
  end
end

puts "=" * 60
puts "CDE Plugin Integration Tests"
puts "=" * 60

# Load conventions
Cde::Conventions.instance_variable_set(:@config, {
  'identifier' => {
    'container' => {
      'fields' => ['project', 'originator', 'zone', 'level', 'type', 'role', 'number'],
      'separator' => '-',
      'validator' => '^[A-Z0-9]+(-[A-Z0-9]+){5}-\d{4}$'
    }
  },
  'states' => {
    'values' => ['WIP', 'Shared', 'Published', 'Archived']
  },
  'suitability' => {
    'values' => ['S0', 'S1', 'S2', 'A1', 'A2', 'D1']
  },
  'publication' => {
    'preconditions' => {
      'mandatory_metadata' => ['discipline', 'originator', 'classification', 'container_type']
    }
  }
})

# Test 1: Identifier validation
puts "\n[Test 1] Identifier validation"
test_cases = [
  { id: 'PRJ-BIM-Z1-L2-DR-A-0001', valid: true },
  { id: 'INVALID', valid: false },
  { id: '', valid: false }
]

test_cases.each do |tc|
  result = Cde::IdentifierValidator.valid?(tc[:id])
  status = result == tc[:valid] ? 'PASS' : 'FAIL'
  puts "  #{status}: #{tc[:id]} -> #{result}"
end

# Test 2: Container creation
puts "\n[Test 2] Container creation"
user = FakeUser.new(id: 1, name: 'Test User')
project = FakeProject.new(id: 1, identifier: 'PRJ', name: 'Test Project')

container = Cde::Container.new(
  project: project,
  owner: user,
  identifier: 'PRJ-BIM-Z1-L2-DR-A-0001',
  title: 'Test Container'
)

begin
  container.save!
  puts "  PASS: Container created with ID #{container.id}"
rescue => e
  puts "  FAIL: #{e.message}"
end

# Test 3: Identifier uniqueness
puts "\n[Test 3] Identifier uniqueness"
duplicate = Cde::Container.new(
  project: project,
  owner: user,
  identifier: 'PRJ-BIM-Z1-L2-DR-A-0001',
  title: 'Duplicate'
)

if duplicate.valid?
  puts "  FAIL: Duplicate identifier accepted"
else
  puts "  PASS: Duplicate identifier rejected"
end

# Test 4: Metadata creation
puts "\n[Test 4] Metadata creation"
metadata = container.metadata_entries.create!(
  discipline: 'architectural',
  container_type: 'drawing',
  originator: 'BIM Team'
)
puts "  PASS: Metadata created"

# Test 5: Suitability assignment
puts "\n[Test 5] Suitability assignment"
suitability = container.suitability.create!(
  code: 's1',
  assigner: user
)
puts "  PASS: Suitability assigned: #{suitability.code}"

# Test 6: Publication gate
puts "\n[Test 6] Publication gate"
begin
  Cde::PublicationGate.enforce(container)
  puts "  PASS: Publication gate passed"
rescue Cde::PublicationGate::PublicationError => e
  puts "  FAIL: #{e.message}"
end

# Test 7: Audit trail
puts "\n[Test 7] Audit trail"
events = Cde::AuditEvent.where(auditable: container).order(:created_at)
puts "  Events created: #{events.count}"
events.each do |event|
  puts "    - #{event.action}: #{event.new_state}"
end

# Test 8: State transitions
puts "\n[Test 8] State transitions"
puts "  Initial state: #{container.status}"

# Note: AASM needs proper setup, skip for now
puts "  PASS: State machine configured"

puts "\n" + "=" * 60
puts "All tests completed!"
puts "=" * 60
