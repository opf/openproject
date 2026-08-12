require "yaml"

files = {
  "conventions.yml" => File.read(File.join(__dir__, "cde_conventions.yml")),
  "permissions.seed.yml" => File.read(File.join(__dir__, "../modules/cde/config/cde_permissions.seed.yml")),
}

files.each do |name, body|
  begin
    doc = YAML.safe_load(body, permitted_classes: [Symbol], aliases: false, filename: name)
    puts "#{name}: OK"
  rescue Psych::DuplicateKeyError => e
    # Psych safe_load in Ruby >= 3.1 raises on dup keys by default
    puts "#{name}: DUPLICATE-KEY ERROR: #{e.message}"
    exit 1
  rescue Psych::SyntaxError => e
    puts "#{name}: SYNTAX ERROR: #{e.message}"
    exit 1
  end
end

# Cross-check: capabilities listed in permissions.skill matrix exist in conventions.yml
conv = YAML.safe_load(File.read(File.join(__dir__, "cde_conventions.yml")), permitted_classes: [Symbol], aliases: false)
perm = YAML.safe_load(File.read(File.join(__dir__, "../modules/cde/config/cde_permissions.seed.yml")), permitted_classes: [Symbol], aliases: false)

conv_caps = conv.fetch("permissions").fetch("roles").flat_map { |r, caps| caps.map { |c| c["capability"] } }.uniq.sort
perm_caps = perm.fetch("matrix").keys.sort

if (conv_caps - perm_caps).any?
  puts "MISMATCH: permissions.seed.yml missing capabilities: #{conv_caps - perm_caps}"
  exit 1
end
if (perm_caps - conv_caps).any?
  puts "MISMATCH: conventions.yml missing capabilities: #{perm_caps - conv_caps}"
  exit 1
end

puts "capabilities: OK (#{conv_caps.length} capabilities, consistent across conventions + permissions)"
