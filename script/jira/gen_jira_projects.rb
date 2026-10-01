#!/usr/bin/env ruby
# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Script to mass-create projects, issues, and users in a Jira Data Center server for testing.
#
# Usage:
#   ruby script/jira/gen_jira_projects.rb [options]
#
# Options:
#   --projects N       Number of projects to create (default: 1000)
#   --min-issues N     Minimum issues per project (default: 10)
#   --max-issues N     Maximum issues per project (default: 100)
#   --users N          Number of users to create (default: 0, uses existing users only)
#   --min-comments N   Minimum comments per issue (default: 0)
#   --max-comments N   Maximum comments per issue (default: 5)
#   --dry-run          Show what would be created without making API calls
#   --help             Show this help message
#
# Environment variables (in .env file):
#   JIRA_URL           Jira Data Center URL (e.g., https://jira.example.com)
#   JIRA_TOKEN         Personal Access Token for authentication

require "bundler/setup"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/enumerable"
require "colored2"
require "httpx"
require "json"
require "optparse"
require "securerandom"

# rubocop:disable Metrics/CollectionLiteralLength, Metrics/PerceivedComplexity, Metrics/AbcSize

class JiraProjectCreator
  ISSUE_TYPES = %w[Task Bug Story Epic].freeze
  PRIORITIES = %w[Highest High Medium Low Lowest].freeze
  PROJECT_TEMPLATES = %w[
    com.pyxis.greenhopper.jira:gh-scrum-template
    com.pyxis.greenhopper.jira:gh-kanban-template
    com.pyxis.greenhopper.jira:basic-software-development-template
  ].freeze
  FIRST_NAMES = %w[
    James Mary John Patricia Robert Jennifer Michael Linda William Elizabeth
    David Barbara Richard Susan Joseph Jessica Thomas Sarah Charles Karen
    Christopher Nancy Daniel Lisa Matthew Betty Anthony Margaret Mark Sandra
    Donald Ashley Steven Kimberly Paul Emily Andrew Donna Joshua Michelle
    Kenneth Dorothy Kevin Carol Brian Amanda George Rebecca Timothy Sharon
    Ronald Cynthia Edward Kathleen Jason Anna Jeffrey Shirley Ryan Amy
    Jacob Angela Nicholas Brenda Gary Helen Eric Samantha Jonathan Jean
    Stephen Victoria Frank Katherine Larry Theresa Scott Alice Raymond Nicole
    Benjamin Marie Patrick Judy Alexander Janet Jack Carolyn Dennis Catherine
    Jerry Frances Tyler Christine Peter Debra Aaron Janice Jose Maria
    Adam Rachel Nathan Heather Zachary Diane Kyle Diana Howard Gloria
    Douglas Sara Ethan Janet Henry Megan Albert Christina Phillip Lauren
    Roy Andrea Russell Doris Eugene Evelyn Bobby Julia Gabriel Madison
    Louis Grace Lawrence Kelly Dylan Ashley Willie Amber Carl Lori
    Jesse Melissa Bruce Christina Alan Cheryl Sean Marie Jordan Christine
    Ralph Judy Gabriel Paula Roy Amber Oscar Phyllis Louis Jane
    Randy Norma Philip Stephanie Eugene Ruth Willie Christina Johnny Lillian
    Billy Deborah Terry Judith Todd Rachel Craig Judith Jesse Deborah
    Steve Gloria Frank Kathy Timothy Marilyn Edward Diana Danny Rose
    Philip Nicole Keith Theresa Scott Emily Gerald Christina Marcus Paula
    Rodney Donna Derrick Julie Eugene Michelle Cody Laura Ricardo Lillian
    Shane Robin Clarence Gloria Alex Andrea Eduardo Cheryl Marcus Christine
    Fernando Judith Bryan Ruby Sidney Diana Travis Dolores Geoffrey Frances
  ].freeze

  LAST_NAMES = %w[
    Smith Johnson Williams Brown Jones Garcia Miller Davis Rodriguez Martinez
    Hernandez Lopez Gonzalez Wilson Anderson Thomas Taylor Moore Jackson Martin
    Lee Perez Thompson White Harris Sanchez Clark Ramirez Lewis Robinson Walker
    Young Allen King Wright Scott Torres Nguyen Hill Flores Green Adams Nelson
    Baker Hall Rivera Campbell Mitchell Carter Roberts Turner Phillips Evans
    Parker Edwards Collins Stewart Morris Morales Murphy Cook Rogers Gutierrez
    Ortiz Morgan Cooper Peterson Bailey Reed Kelly Howard Ramos Kim Cox Ward
    Richardson Watson Brooks Chavez Wood James Bennett Gray Mendoza Ruiz Hughes
    Price Alvarez Castillo Sanders Patel Myers Long Ross Foster Jimenez Powell
    Jenkins Perry Russell Sullivan Bell Coleman Butler Henderson Barnes Gonzales
    Fisher Vasquez Simmons Graham Murray Romero Freeman Wells Webb Simpson
    Stevens Tucker Porter Hunter Hicks Crawford Henry Boyd Mason Moreno Kennedy
    Warren Dixon Ramos Burns Gordon Shaw Holmes Rice Robertson Hunt Black
    Daniels Palmer Mills Nichols Grant Knight Ferguson Rose Stone Hawkins Dunn
    Perkins Hudson Spencer Gardner Stephens Payne Pierce Berry Matthews Arnold
  ].freeze

  COMMENT_TEMPLATES = [
    "I've started working on this. Will update once I have more progress.",
    "Can someone clarify the requirements here? I'm not sure about %s.",
    "This is blocked by %s. We need to resolve that first.",
    "I've completed the initial implementation. Ready for review.",
    "Found an issue with %s during testing. Investigating now.",
    "This looks good to me. Approving the changes.",
    "We should consider %s as an alternative approach.",
    "Updated the documentation for this change.",
    "Running into some issues with %s. Any suggestions?",
    "This is more complex than initially estimated. Might need more time.",
    "Great work on this! The %s implementation is clean.",
    "I have some concerns about %s. Can we discuss?",
    "Deployed to staging for testing. Please verify.",
    "All tests are passing. Ready for production.",
    "Need to add more test coverage for %s.",
    "Reverted the previous change due to %s issues.",
    "This needs a design review before we proceed.",
    "Performance looks good after the %s optimization.",
    "Security review completed. No issues found.",
    "Added logging for better debugging of %s.",
    "Waiting on feedback from the product team.",
    "This is a duplicate of the %s issue.",
    "Closing as won't fix. The %s behavior is expected.",
    "Reopening this - the fix didn't fully address %s.",
    "Updated the priority based on customer feedback."
  ].freeze

  PROJECT_CATEGORIES = [
    { name: "Frontend", description: "User interface and client-side projects" },
    { name: "Backend", description: "Server-side and API projects" },
    { name: "Infrastructure", description: "DevOps, CI/CD, and platform projects" },
    { name: "Mobile", description: "iOS and Android applications" },
    { name: "Data", description: "Analytics, ML, and data pipeline projects" },
    { name: "Security", description: "Security and compliance projects" },
    { name: "Platform", description: "Core platform and shared services" },
    { name: "Experiments", description: "R&D and proof of concept projects" },
    { name: "Legacy", description: "Maintenance and migration projects" },
    { name: "Integrations", description: "Third-party integrations and APIs" },
    { name: "Internal Tools", description: "Developer tooling and automation" },
    { name: "Customer Success", description: "Customer-facing improvements" }
  ].freeze

  PROJECT_ADJECTIVES = %w[
    Alpha Beta Gamma Delta Omega Phoenix Quantum Nova Solar Lunar
    Stellar Cosmic Rapid Swift Agile Smart Digital Cloud Native
    Modern Legacy Core Prime Elite Ultra Hyper Mega Super Turbo
    Atomic Dynamic Fusion Global Infinite Neural Optical Prism
    Radiant Shadow Titan Vector Vertex Zenith Aurora Blaze Cipher
    Crystal Diamond Echo Ember Falcon Glacier Harbor Horizon Iron
    Jade Kinetic Liberty Marble Neptune Onyx Pacific Quartz Raven
    Sapphire Thunder Unity Vortex Wildfire Xenon Yeti Zephyr Amber
    Bronze Cobalt Crimson Emerald Frost Golden Indigo Jasper Neon
    Obsidian Pearl Ruby Scarlet Silver Topaz Violet Copper Coral
    Azure Cerulean Ivory Slate Storm Arctic Boreal Evergreen Summit
    Pioneer Venture Apex Astral Bright Central Cyber Edge Frontier
    Ignite Impulse Lunar Micro Nano Nitro Polar Presto Pulse Sonic
    Spark Sprint Steady Stream Surge Synergy Terra Thrust Titan Trek
    Vital Wave Zero Nexus Orbit Pinnacle Precision Proton Radix
    Chunky Fluffy Wobbly Sneaky Dizzy Fuzzy Grumpy Spicy Crispy Crunchy
    Bouncy Giggly Wiggly Bubbly Sparkly Twisty Zippy Zesty Snappy Peppy
    Mighty Squishy Sleepy Groovy Funky Wacky Quirky Nerdy Geeky Fancy
    Cosmic Mystic Magic Ninja Pirate Robot Zombie Viking Wizard Dragon
    Caffeine Turbo Rocket Laser Plasma Stealth Ninja Secret Covert Hidden
    Overdue Urgent Blocking Critical Legendary Epic Mythic Heroic Supreme
    Confused Bewildered Puzzled Random Chaotic Mysterious Cryptic Obscure
    Sloppy Messy Untidy Cluttered Disorganized Haphazard Jumbled Scattered
    Hangry Salty Caffeinated Decaf Debugging Compiling Deploying Refactored
    Botched Hacked Glitched Crashed Frozen Laggy Janky Wonky
    Careless Reckless Fearless Witty Quirky
  ].freeze

  PROJECT_NOUNS = %w[
    Platform System Portal Gateway Engine Framework Module Suite
    Hub Network Bridge Pipeline Toolkit Factory Studio Workspace
    Tracker Manager Console Dashboard Registry Vault Nexus Matrix
    Accelerator Analyzer Architect Archive Beacon Catalyst Chamber
    Compass Conduit Controller Curator Depot Director Dispatcher
    Dome Endpoint Explorer Forge Frontier Generator Guardian Harvester
    Incubator Inspector Integrator Junction Kernel Launchpad
    Lighthouse Link Mainframe Monitor Navigator Observatory Operator
    Oracle Orchestrator Outpost Pavilion Processor Prototype Radar
    Reactor Relay Repository Resolver Router Sanctuary Scheduler
    Sentinel Server Shield Shuttle Signal Simulator Socket Sphere
    Station Streamer Switchboard Terminal Tower Transmitter Tunnel
    Warehouse Watcher Workshop Zone Amplifier Basecamp Command
    Datastore Exchange Grid Index Ledger Mesh Node Pathway Pulse
    Cluster Core Cortex Database Dock Domain Drive Dynamo Ecosystem
    Element Emitter Encoder Entity Express Extractor Fabric Fleet
    Flow Focus Foundry Frame Funnel Hive Interface Inventory Lab
    Layer Library Loader Locus Logic Loop Machine Map Marker Memory
    Mill Mind Mirror Mover Multiplexer Nerve Ocean Office Optimizer
    Panel Parser Partner Pattern Planner Plugin Point Pool Port
    Powerhouse Producer Profile Projector Provider Queue Ranch Range
    Reader Receiver Recorder Refinery Register Repeater Resource Ring
    Scale Scanner Scope Screen Seeker Segment Sequencer Service Shop
    Silo Site Slice Source Space Spectrum Spire Spot Stack Stage
    Store Strategy Structure Studio Surface Switch Table Tank Target
    Template Thread Tier Timer Token Tool Track Trail Transform Tree
    Trunk Unit Utility Valve Vessel View Viewer Vision Warehouse Web
    Unicorn Narwhal Llama Penguin Panda Octopus Kraken Phoenix Dragon
    Waffle Pancake Taco Burrito Pretzel Donut Bagel Cookie Muffin Pizza
    Mongoose Hamster Badger Otter Koala Sloth Platypus Capybara Wombat
    Dumpster Trashcan Landfill Bonfire Trainwreck Rollercoaster Circus
    Spaghetti Lasagna Noodle Pickle Banana Avocado Coconut Pineapple
    Thunderdome Treehouse Clubhouse Bunker Fortress Castle Dungeon Lair
    Contraption Gizmo Widget Gadget Doodad Thingamajig Whatchamacallit
    Overlord Minion Sidekick Henchman Mastermind Genius Prodigy Wizard
    Boomerang Catapult Trebuchet Cannon Slingshot Jetpack Hovercraft
  ].freeze

  EPIC_NAMES = [
    "Operation Rubber Duck",
    "Project Unicorn Tears",
    "Mission Impossible Deadline",
    "The Great Refactoring",
    "Caffeine-Driven Development",
    "Bug Hunt 3000",
    "The Neverending Sprint",
    "Deploy and Pray",
    "Technical Debt Apocalypse",
    "Feature Creep Chronicles",
    "The Spaghetti Untangler",
    "Quantum Bug Squasher",
    "Legacy Code Archaelogy",
    "The Memory Leak Saga",
    "Operation Stack Overflow",
    "Project Copy-Paste",
    "The Infinite Loop Escape",
    "Null Pointer Nightmare",
    "The Merge Conflict Resolution",
    "Friday Deploy Disaster",
    "The Production Firefighter",
    "Scope Creep Monster",
    "The Database Migration Dance",
    "Operation Hot Fix",
    "The Dependency Hell Escape",
    "Project Works On My Machine",
    "The Meeting That Could Be An Email",
    "Agile Theater Production",
    "The Standup Marathon",
    "Operation Ship It",
    "The Code Review Gauntlet",
    "Project TODO Later",
    "The Callback Pyramid",
    "Async Await Awakening",
    "The Cache Invalidation Puzzle",
    "Operation Naming Things",
    "The Off-By-One Adventure",
    "Project YAGNI Violation",
    "The Premature Optimization",
    "Rubber Band Architecture"
  ].freeze

  SUMMARY_TEMPLATES = [
    "Implement %s feature",
    "Fix %s bug in module",
    "Update %s documentation",
    "Refactor %s component",
    "Add tests for %s",
    "Optimize %s performance",
    "Review %s code",
    "Configure %s settings",
    "Deploy %s changes",
    "Investigate %s issue",
    "Upgrade %s dependencies",
    "Add support for %s",
    "Remove deprecated %s code",
    "Improve %s error handling",
    "Create %s endpoint",
    "Design %s architecture",
    "Migrate %s to new version",
    "Debug %s failure",
    "Enable %s functionality",
    "Disable legacy %s behavior",
    "Document %s API",
    "Benchmark %s operations",
    "Profile %s bottleneck",
    "Secure %s endpoint",
    "Validate %s input",
    "Sanitize %s data",
    "Cache %s responses",
    "Index %s records",
    "Batch %s processing",
    "Stream %s events",
    "Monitor %s health",
    "Alert on %s errors",
    "Audit %s access",
    "Archive %s data",
    "Restore %s backup",
    "Scale %s infrastructure",
    "Load balance %s traffic",
    "Throttle %s requests",
    "Rate limit %s API",
    "Encrypt %s storage",
    "Decrypt %s payload",
    "Compress %s assets",
    "Minify %s resources",
    "Bundle %s modules",
    "Split %s chunks",
    "Lazy load %s components",
    "Preload %s dependencies",
    "Prefetch %s data",
    "Invalidate %s cache",
    "Purge %s records"
  ].freeze

  WORDS = %w[
    authentication authorization caching database email export import logging
    notification pagination reporting search security settings storage sync
    upload validation webhook workflow analytics dashboard metrics monitoring
    backup integration migration scheduling templating versioning filtering
    routing session token encryption hashing compression serialization
    deserialization marshalling unmarshalling encoding decoding parsing
    formatting rendering templating caching queuing messaging streaming
    batching throttling limiting retrying timeout connection pooling
    transaction locking concurrency threading parallelism asynchronous
    synchronous blocking nonblocking callback promise future observable
    subscription publishing consuming producing indexing searching
    sorting filtering grouping aggregating joining merging splitting
    partitioning sharding replication failover recovery snapshot
    checkpoint rollback commit abort isolation consistency durability
    atomicity availability partition tolerance latency throughput
    bandwidth capacity utilization saturation scalability elasticity
    resilience redundancy fault tolerance high availability disaster
    recovery business continuity service level agreement performance
    optimization tuning profiling benchmarking load testing stress
    testing chaos engineering canary deployment blue green deployment
    rolling update feature flag circuit breaker bulkhead retry
    fallback graceful degradation health check readiness liveness
    tracing logging monitoring alerting dashboarding visualization
    reporting auditing compliance governance policy enforcement
    access control identity management single sign on multi factor
    authentication password policy credential rotation secret
    management certificate management key management encryption
    decryption signing verification hashing salting stretching
    input validation output encoding error handling exception
    management resource cleanup memory management garbage collection
    reference counting object pooling connection pooling thread
    configuration deployment provisioning orchestration automation
    infrastructure code continuous integration delivery deployment
    pipeline artifact repository container registry image scanning
    vulnerability assessment penetration testing security audit
    user interface experience design accessibility internationalization
    localization globalization responsive adaptive progressive
    enhancement graceful degradation browser compatibility cross
    platform native hybrid mobile desktop embedded realtime batch
    event driven message queue pub sub request response rest graphql
    grpc websocket server sent events long polling short polling
    slop slosh spill splatter mess sludge muck botch
    webhook callback trigger scheduler cron job background worker
    queue consumer producer broker exchange routing binding dead
    letter retry poison acknowledgment confirmation delivery
    guarantee exactly once at least once at most once idempotency
    deduplication ordering sequencing windowing watermark late
    arrival out of order replay reprocessing backfill migration
    schema evolution backward forward compatibility versioning
    deprecation sunset end of life maintenance support patching
    hotfix release candidate general availability beta alpha
    preview experimental stable latest edge nightly snapshot
    artifact dependency resolution conflict diamond problem
    circular reference lazy eager loading initialization bootstrap
    startup shutdown graceful termination signal handling cleanup
    resource release connection close file handle socket descriptor
    memory leak resource exhaustion denial of service rate limiting
    admission control backpressure flow control congestion avoidance
    slow start exponential backoff jitter randomization retry storm
    thundering herd cache stampede hot key hot partition skew
    imbalance rebalancing redistribution consistent hashing virtual
    node replica placement rack awareness zone awareness region
    awareness multi region multi cloud hybrid cloud edge computing
    fog computing serverless function as a service platform as a
    service infrastructure backend frontend middleware gateway proxy
    reverse proxy load balancer service mesh sidecar ambassador
    adapter facade decorator strategy factory builder singleton
    prototype flyweight composite bridge observer mediator command
    state template method visitor interpreter iterator chain of
    responsibility memento specification repository unit of work
    data mapper active record table data gateway row data gateway
    domain model transaction script service layer application
    controller page controller front controller intercepting filter
    context object value object entity aggregate root bounded context
    ubiquitous language domain driven design event sourcing command
    query responsibility segregation eventual consistency strong
    consistency causal consistency read your writes monotonic reads
    monotonic writes session consistency prefix consistency bounded
    staleness linearizability serializability snapshot isolation
    read committed read uncommitted repeatable read phantom read
    dirty read lost update write skew isolation level pessimistic
    optimistic concurrency control multiversion timestamp ordering
    two phase locking three phase commit saga compensation rollback
    forward recovery backward recovery checkpoint savepoint nested
    transaction distributed transaction coordinator participant
    prepare commit abort timeout recovery log write ahead logging
    redo undo physiological logging logical physical incremental
    differential full backup point in time recovery continuous
    archiving retention policy lifecycle management tiered storage
    hot warm cold archive glacier deep storage object block file
    network attached direct attached storage area network software
    defined storage hyperconverged infrastructure virtual machine
    container pod deployment replica set stateful set daemon set
    job cron job config map secret persistent volume claim storage
    class ingress egress network policy service account role binding
    cluster role namespace resource quota limit range horizontal
    vertical pod autoscaler cluster autoscaler node affinity pod
    affinity anti affinity taint toleration priority preemption
    disruption budget pod security policy network security group
    firewall rule access list route table subnet virtual private
    cloud internet gateway nat gateway vpn direct connect peering
    transit hub spoke mesh topology star ring bus tree hybrid
    redundant resilient fault tolerant self healing auto scaling
    auto provisioning auto configuration auto discovery service
    registration health monitoring performance baseline anomaly
    detection root cause analysis incident response runbook playbook
    automation remediation notification escalation on call rotation
    maintenance window change management release management
    spaghetti yolo hackathon kludge workaround duct-tape band-aid
    bikeshedding yak-shaving rubber-ducking cargo-culting cowboy-coding
    copypasta stackoverflow magic incantation voodoo wizardry sorcery
    gremlins demons dragons unicorns ninjas pirates zombies robots
    apocalypse dumpster-fire trainwreck chaos pandemonium mayhem
    shenanigans tomfoolery mischief hullabaloo brouhaha kerfuffle
    bamboozle flummox discombobulate befuddle perplex mystify
    thingamajig doohickey whatchamacallit gizmo widget gadget
    contraption apparatus doodad thingy whatnot gubbins jiggery-pokery
    hocus-pocus abracadabra mumbo-jumbo gobbledygook rigmarole
    hullabaloo pandemonium bedlam brouhaha ruckus commotion fracas
    hodgepodge mishmash potpourri smorgasbord gallimaufry farrago
    snafu fubar tarfu caterpillar butterfly cocoon metamorphosis
    boondoggle fiasco debacle catastrophe calamity disaster meltdown
    implosion explosion combustion conflagration inferno blaze bonfire
    phoenix resurrection rebirth reincarnation rejuvenation revival
    zombie vampire werewolf ghost poltergeist specter phantom wraith
    gremlin goblin troll ogre monster beast creature critter varmint
    caffeine espresso latte cappuccino mocha frappuccino macchiato
    pizza burrito taco nacho quesadilla enchilada fajita chimichanga
    pretzel bagel croissant muffin scone biscuit waffle pancake crepe
  ].freeze

  def initialize(url:, token:, dry_run: false)
    @url = url.chomp("/")
    @token = token
    @dry_run = dry_run
    @epic_name_field = nil # Will be discovered from API errors
    @httpx = HTTPX
               .plugin(:basic_auth)
               .with(
                 headers:
                   {
                     "Accept" => "application/json",
                     "Content-Type" => "application/json"
                   }
               )
               .bearer_auth(token)
  end

  def run(num_projects:, min_issues:, max_issues:, num_users: 0, min_comments: 0, max_comments: 5)
    puts "=" * 60
    puts "Jira Project Creator".bold.cyan
    puts "=" * 60
    puts "URL: #{@url.yellow}"
    puts "Projects to create: #{num_projects.to_s.green}"
    puts "Issues per project: #{min_issues}-#{max_issues} (random)"
    puts "Users to create: #{num_users.to_s.green}"
    puts "Comments per issue: #{min_comments}-#{max_comments} (random)"
    puts "Mode: #{@dry_run ? 'DRY RUN'.yellow : 'LIVE'.red.bold}"
    puts "=" * 60
    puts

    # Verify connection
    unless @dry_run
      puts "Verifying connection...".cyan
      server_info = get_server_info
      puts "Connected to: #{server_info['serverTitle'].green} (v#{server_info['version']})"
      puts
    end

    # Get current user for project lead
    current_user = @dry_run ? { "name" => "admin" } : get_current_user
    puts "Current user: #{current_user['name'].green}"
    puts

    # Create users if requested
    @users = [current_user]
    if num_users.positive?
      puts "Creating #{num_users} users...".cyan
      created_users = create_users(num_users)
      @users += created_users
      puts "Created #{created_users.length.to_s.green} users"
    else
      # Fetch existing users to use for assignments
      puts "Fetching existing users...".cyan
      existing_users = @dry_run ? sample_users : fetch_users
      @users += existing_users
      puts "Found #{existing_users.length.to_s.green} existing users"
    end
    puts

    # Fetch available statuses
    statuses = @dry_run ? sample_statuses : fetch_statuses
    puts "Available statuses: #{statuses.pluck('name').join(', ').cyan}"
    puts

    # Available project templates
    puts "Available project templates: #{PROJECT_TEMPLATES.length.to_s.cyan}"
    puts

    # Ensure project categories exist
    categories = @dry_run ? PROJECT_CATEGORIES.map { |c| c.merge(id: rand(1..100).to_s) } : ensure_categories_exist
    puts "Available project categories: #{categories.pluck(:name).join(', ').cyan}"
    puts

    # Create projects
    created_projects = []
    total_issues = 0
    used_keys = Set.new
    num_projects.times do |i|
      # Generate unique random key
      project_key = generate_unique_key(used_keys)
      used_keys << project_key
      project_name = generate_project_name

      puts "\n#{"- [#{i + 1}/#{num_projects}]".cyan} Creating project"
      template = PROJECT_TEMPLATES.sample
      category = categories.sample
      # Pick a random user as project lead
      project_lead = @users.sample
      project = create_project(
        key: project_key,
        name: project_name,
        lead: project_lead["name"],
        template:,
        category:,
        used_keys:
      )

      if project
        created_projects << project
        puts "  Created project: #{project['key'].green.bold} (#{project['name'].yellow})"
        puts "  Lead: #{project_lead['name'].magenta}"
        puts "  Template: #{template.cyan}"
        puts "  Category: #{category[:name].magenta}" if category

        # Fetch project-specific issue types (exclude subtasks)
        project_issue_types = @dry_run ? sample_issue_types : fetch_project_issue_types(project["key"])
        project_types = project_issue_types
                          .reject { |t| t["subtask"] }
                          .map { |t| t["name"] }
        puts "  Issue types: #{project_types.join(', ').cyan}"

        # Create random number of issues for this project
        issue_count = rand(min_issues..max_issues)
        total_issues += issue_count
        puts "  Creating #{issue_count.to_s.yellow} issues..."
        create_issues_for_project(
          project_key: project["key"],
          count: issue_count,
          issue_types: project_types,
          statuses:,
          min_comments:,
          max_comments:
        )
      end
    end

    puts "\n#{'=' * 60}"
    puts "Summary".bold.cyan
    puts "=" * 60
    puts "Users available: #{@users.length.to_s.green.bold}"
    puts "Projects created: #{created_projects.length.to_s.green.bold}"
    puts "Total issues created: #{total_issues.to_s.green.bold}"
    puts "=" * 60
  end

  private

  def get_server_info
    get("/rest/api/2/serverInfo")
  end

  def get_current_user
    get("/rest/api/2/myself")
  end

  def fetch_statuses
    get("/rest/api/2/status")
  end

  def fetch_issue_types
    get("/rest/api/2/issuetype")
  end

  def fetch_users(max_results: 200)
    # Search for users - returns active users
    result = get("/rest/api/2/user/search?username=.&maxResults=#{max_results}")
    result.map { |u| { "name" => u["name"], "displayName" => u["displayName"], "emailAddress" => u["emailAddress"] } }
  rescue StandardError => e
    puts "⚠ Warning:".yellow + " Could not fetch users: #{e.message}"
    []
  end

  def create_user(username:, email:, display_name:, password: nil)
    password ||= SecureRandom.hex(12)
    payload = {
      name: username,
      password:,
      emailAddress: email,
      displayName: display_name
    }

    if @dry_run
      puts "[DRY RUN]".yellow.bold + " Would create user: #{username}"
      return { "name" => username, "displayName" => display_name, "emailAddress" => email, "password" => password }
    end

    begin
      result = post("/rest/api/2/user", payload)
      # Store password for later use with basic auth (for comments)
      { "name" => result["name"], "displayName" => result["displayName"], "emailAddress" => result["emailAddress"],
        "password" => password }
    rescue StandardError => e
      puts "⚠ Warning:".yellow + " Could not create user #{username}: #{e.message}"
      nil
    end
  end

  def create_users(count)
    users = []
    used_usernames = Set.new

    count.times do |i|
      first_name = FIRST_NAMES.sample
      last_name = LAST_NAMES.sample

      # Generate unique username
      base_username = "#{first_name.downcase}.#{last_name.downcase}"
      username = base_username
      suffix = 1
      while used_usernames.include?(username)
        username = "#{base_username}#{suffix}"
        suffix += 1
      end
      used_usernames << username

      email = "#{username}@example.com"
      display_name = "#{first_name} #{last_name}"

      user = create_user(username:, email:, display_name:)
      if user
        users << user
        print ".".green if (i + 1) % 10 == 0
      end
    end
    puts " Done!".green.bold if count >= 10
    users
  end

  def sample_users
    [
      { "name" => "john.smith", "displayName" => "John Smith", "emailAddress" => "john.smith@example.com",
        "password" => "password123" },
      { "name" => "jane.doe", "displayName" => "Jane Doe", "emailAddress" => "jane.doe@example.com",
        "password" => "password123" },
      { "name" => "bob.wilson", "displayName" => "Bob Wilson", "emailAddress" => "bob.wilson@example.com",
        "password" => "password123" }
    ]
  end

  def fetch_project_categories
    get("/rest/api/2/projectCategory")
  end

  def create_project_category(name:, description:)
    post("/rest/api/2/projectCategory", { name:, description: })
  end

  def ensure_categories_exist
    existing = fetch_project_categories
    existing_names = existing.pluck("name")

    categories = []
    PROJECT_CATEGORIES.each do |cat|
      if existing_names.include?(cat[:name])
        found = existing.find { |c| c["name"] == cat[:name] }
        categories << { id: found["id"], name: found["name"] }
      else
        begin
          created = create_project_category(name: cat[:name], description: cat[:description])
          categories << { id: created["id"], name: created["name"] }
          puts "  Created category: #{cat[:name].green}"
          puts ""
        rescue StandardError => e
          puts "  ⚠ Could not create category #{cat[:name]}:".yellow + " #{e.message}"
        end
      end
    end

    categories
  rescue StandardError => e
    puts "⚠ Warning:".yellow + " Could not fetch categories: #{e.message}"
    []
  end

  def sample_statuses
    [
      { "id" => "1", "name" => "To Do", "statusCategory" => { "key" => "new" } },
      { "id" => "2", "name" => "In Progress", "statusCategory" => { "key" => "indeterminate" } },
      { "id" => "3", "name" => "Done", "statusCategory" => { "key" => "done" } }
    ]
  end

  def sample_issue_types
    [
      { "id" => "10001", "name" => "Task", "subtask" => false },
      { "id" => "10002", "name" => "Bug", "subtask" => false },
      { "id" => "10003", "name" => "Story", "subtask" => false },
      { "id" => "10005", "name" => "Epic", "subtask" => false },
      { "id" => "10004", "name" => "Sub-task", "subtask" => true }
    ]
  end

  def fetch_project_issue_types(project_key)
    # Get issue types available for this specific project
    result = get("/rest/api/2/project/#{project_key}/statuses")
    result.map { |item| { "id" => item["id"], "name" => item["name"], "subtask" => item["subtask"] || false } }
  rescue StandardError => e
    puts "⚠ Warning:".yellow + " Could not fetch project issue types: #{e.message}"
    # Fallback to global issue types
    fetch_issue_types
  end

  def create_project(key:, name:, lead:, template:, category:, used_keys:)
    if @dry_run
      puts "[DRY RUN]".yellow.bold + " Would create project: #{key} (template: #{template})"
      return { "key" => key, "name" => name, "id" => rand(10_000..99_999).to_s }
    end

    # Check if project already exists, generate new key if so
    current_key = key
    current_name = name
    while fetch_existing_project(current_key)
      puts "  ⟳ Project key #{current_key.yellow} already exists, generating new key..."
      current_key = generate_unique_key(used_keys)
      used_keys << current_key
    end

    # Try to create project, retry with new name if name already exists
    max_retries = 5
    max_retries.times do
      payload = {
        key: current_key,
        name: current_name,
        projectTypeKey: "software",
        projectTemplateKey: template,
        lead:,
        description: "Test project created by jira_projects.rb script at #{Time.now.utc}"
      }
      payload[:categoryId] = category[:id] if category&.dig(:id)

      begin
        result = post("/rest/api/2/project", payload)
        result["key"] = current_key if result
        result["name"] = current_name if result
        return result
      rescue StandardError => e
        if e.message.include?("name already exists")
          current_name = generate_project_name
          puts "  ⟳ Project name already exists, trying: #{current_name.yellow}"
          next
        end
        puts "✗ Error creating project #{current_key}:".red + " #{e.message}"
        return nil
      end
    end

    puts "✗ Error: Failed to create project after #{max_retries} attempts".red
    nil
  end

  def fetch_existing_project(key)
    get("/rest/api/2/project/#{key}")
  rescue StandardError
    nil
  end

  def create_issues_for_project(project_key:, count:, issue_types:, statuses:, min_comments:, max_comments:)
    print "  "
    count.times do |i|
      issue_type = issue_types.sample || "Task"
      summary = generate_summary
      description = generate_description
      priority = PRIORITIES.sample
      epic_name = issue_type == "Epic" ? EPIC_NAMES.sample : nil

      # Pick random reporter and assignee from available users
      reporter = @users.sample
      assignee = @users.sample

      issue = create_issue(
        project_key:,
        issue_type:,
        summary:,
        description:,
        priority:,
        epic_name:,
        reporter: reporter["name"],
        assignee: assignee["name"]
      )

      next unless issue

      # Add random comments
      comment_count = rand(min_comments..max_comments)
      add_comments_to_issue(issue["key"], comment_count) if comment_count.positive?

      # Transition to random status
      target_status = statuses.sample
      if target_status && target_status["name"] != "To Do" && target_status["name"] != "Open"
        transition_issue(issue["key"], target_status)
      end

      print ".".green if (i + 1) % 10 == 0
    end
    puts " Done!".green.bold
  end

  def create_issue(project_key:, issue_type:, summary:, description:, priority:, epic_name: nil, reporter: nil, assignee: nil)
    payload = {
      fields: {
        project: { key: project_key },
        issuetype: { name: issue_type },
        summary:,
        description:,
        priority: { name: priority }
      }
    }

    # Add reporter and assignee if provided
    payload[:fields][:reporter] = { name: reporter } if reporter
    payload[:fields][:assignee] = { name: assignee } if assignee

    # Add epic name field if this is an Epic and we already know the field ID
    if issue_type == "Epic" && epic_name && @epic_name_field
      payload[:fields][@epic_name_field] = epic_name
    end

    if @dry_run
      { "key" => "#{project_key}-#{rand(1..999)}", "id" => rand(10_000..99_999).to_s }
    else
      begin
        post("/rest/api/2/issue", payload)
      rescue StandardError => e
        # Check if error mentions a custom field (likely Epic Name) and extract the field ID
        if issue_type == "Epic" && epic_name
          field_id = extract_custom_field_id(e.message)
          if field_id && field_id != @epic_name_field
            @epic_name_field = field_id
            puts "\n#{'★'.cyan} Discovered Epic Name field: #{field_id.green}, retrying..."
            payload[:fields][field_id] = epic_name
            print "  "
            begin
              return post("/rest/api/2/issue", payload)
            rescue StandardError => retry_error
              puts "\n#{'✗'.red} Error creating Epic after retry: #{retry_error.message}"
              return nil
            end
          end
        end
        puts "\n#{'✗'.red} Error creating issue: #{e.message}"
        nil
      end
    end
  end

  def add_comments_to_issue(issue_key, count)
    return if @dry_run

    count.times do
      comment_body = generate_comment
      # Pick a random user to author the comment
      author = users_with_credentials.sample
      add_comment(issue_key, comment_body, author:)
    end
  rescue StandardError
    # Silently ignore comment errors
  end

  def add_comment(issue_key, body, author: nil)
    # If author has credentials, use basic auth to post as that user
    if author && author["password"]
      post_as_user("/rest/api/2/issue/#{issue_key}/comment", { body: }, username: author["name"], password: author["password"])
    else
      post("/rest/api/2/issue/#{issue_key}/comment", { body: })
    end
  rescue StandardError
    # Silently ignore - comments might fail due to permissions
  end

  def post_as_user(path, payload, username:, password:)
    # Create a new HTTP client with basic auth for this specific user
    user_httpx = HTTPX
                   .plugin(:basic_auth)
                   .with(
                     headers: {
                       "Accept" => "application/json",
                       "Content-Type" => "application/json"
                     }
                   )
                   .basic_auth(username, password)

    response = user_httpx.post("#{@url}#{path}", json: payload)
    handle_response(response)
  end

  def users_with_credentials
    @users.select { |u| u["password"] }
  end

  def generate_comment
    template = COMMENT_TEMPLATES.sample
    word = WORDS.sample
    format(template, word)
  end

  def extract_custom_field_id(error_message)
    # Parse error message like: {"errors" => {"customfield_10105" => "Epic Name is required."}}
    match = error_message.match(/"(customfield_\d+)"/)
    match ? match[1] : nil
  end

  def transition_issue(issue_key, target_status)
    return if @dry_run

    begin
      # Get available transitions
      transitions = get("/rest/api/2/issue/#{issue_key}/transitions")
      available = transitions["transitions"] || []

      # Find transition to target status
      transition = available.find { |t| t.dig("to", "name") == target_status["name"] }

      if transition
        post("/rest/api/2/issue/#{issue_key}/transitions", { transition: { id: transition["id"] } })
      end
    rescue StandardError
      # Silently ignore transition errors - not all statuses may be reachable
    end
  end

  def generate_project_key
    # Generate a random 3-5 letter uppercase key
    length = rand(3..5)
    Array.new(length) { ("A".."Z").to_a.sample }.join
  end

  def generate_unique_key(used_keys, max_attempts: 100)
    max_attempts.times do
      key = generate_project_key
      return key unless used_keys.include?(key)
    end
    # Fallback: add random suffix
    "#{generate_project_key}#{rand(10..99)}"
  end

  def generate_project_name
    "#{PROJECT_ADJECTIVES.sample} #{PROJECT_NOUNS.sample}"
  end

  def generate_summary
    template = SUMMARY_TEMPLATES.sample
    word = WORDS.sample
    format(template, word)
  end

  def generate_description
    paragraphs = Array.new(rand(1..3)) do
      sentences = Array.new(rand(2..5)) do
        words = Array.new(rand(5..15)) { WORDS.sample }
        "#{words.first.capitalize} #{words[1..].join(' ')}."
      end
      sentences.join(" ")
    end
    paragraphs.join("\n\n")
  end

  def get(path)
    response = @httpx.get("#{@url}#{path}")
    handle_response(response)
  end

  def post(path, payload)
    response = @httpx.post("#{@url}#{path}", json: payload)
    handle_response(response)
  end

  def handle_response(response)
    if response.is_a?(HTTPX::ErrorResponse)
      raise "Connection error: #{response.error.message}"
    end

    case response.status
    when 200..299
      return {} if response.body.to_s.empty?

      response.json
    when 400
      error_body =
        begin
          response.json
        rescue StandardError
          response.body.to_s
        end
      raise "Bad request (400): #{error_body}"
    when 401
      raise "Unauthorized (401): Check your JIRA_TOKEN"
    when 403
      raise "Forbidden (403): Insufficient permissions"
    when 404
      raise "Not found (404): #{response.body}"
    else
      raise "API error (#{response.status}): #{response.body}"
    end
  end
end

def load_env
  env_file = File.join(Dir.pwd, ".env")

  if File.exist?(env_file)
    File.readlines(env_file).each do |line|
      line = line.strip
      next if line.empty? || line.start_with?("#")

      key, value = line.split("=", 2)
      next unless key && value

      # Remove quotes if present
      value = value.gsub(/\A["']|["']\z/, "")
      ENV[key] = value unless ENV[key]
    end
  end
end

def main
  options = {
    projects: 1000,
    min_issues: 10,
    max_issues: 100,
    users: 0,
    min_comments: 0,
    max_comments: 5,
    dry_run: false
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"

    opts.on("--projects N", Integer, "Number of projects to create (default: #{options[:projects]})") do |n|
      options[:projects] = n
    end

    opts.on("--min-issues N", Integer, "Minimum issues per project (default: #{options[:min_issues]})") do |n|
      options[:min_issues] = n
    end

    opts.on("--max-issues N", Integer, "Maximum issues per project (default: #{options[:max_issues]})") do |n|
      options[:max_issues] = n
    end

    opts.on("--users N", Integer, "Number of users to create (default: #{options[:users]}, 0 = use existing)") do |n|
      options[:users] = n
    end

    opts.on("--min-comments N", Integer, "Minimum comments per issue (default: #{options[:min_comments]})") do |n|
      options[:min_comments] = n
    end

    opts.on("--max-comments N", Integer, "Maximum comments per issue (default: #{options[:max_comments]})") do |n|
      options[:max_comments] = n
    end

    opts.on("--dry-run", "Show what would be created without making API calls") do
      options[:dry_run] = true
    end

    opts.on("-h", "--help", "Show this help message") do
      puts opts
      puts
      puts "Environment variables (in .env file):"
      puts "  JIRA_URL     Jira Data Center URL (e.g., https://jira.example.com)"
      puts "  JIRA_TOKEN   Personal Access Token for authentication"
      exit
    end
  end.parse!

  # Load environment variables from .env
  load_env

  url = ENV.fetch("JIRA_URL", nil)
  token = ENV.fetch("JIRA_TOKEN", nil)

  if url.blank?
    puts "#{'✗ Error:'.red.bold} JIRA_URL environment variable is required"
    puts "Set it in your .env file or export it: export JIRA_URL=https://jira.example.com"
    exit 1
  end

  if token.blank?
    puts "#{'✗ Error:'.red.bold} JIRA_TOKEN environment variable is required"
    puts "Set it in your .env file or export it: export JIRA_TOKEN=your_token"
    exit 1
  end

  creator = JiraProjectCreator.new(url:, token:, dry_run: options[:dry_run])
  creator.run(
    num_projects: options[:projects],
    min_issues: options[:min_issues],
    max_issues: options[:max_issues],
    num_users: options[:users],
    min_comments: options[:min_comments],
    max_comments: options[:max_comments]
  )
rescue Interrupt
  puts "\n#{'Aborted by user'.yellow}"
  exit 1
rescue StandardError => e
  puts "✗ Error:".red.bold + " #{e.message}"
  puts e.backtrace.first(5).join("\n").red if ENV["DEBUG"]
  exit 1
end

main if __FILE__ == $0

# rubocop:enable Metrics/CollectionLiteralLength, Metrics/PerceivedComplexity, Metrics/AbcSize
