#!/usr/bin/env ruby

require 'fileutils'

Dir.glob('**/*.md').each do |source_file|
  folder = File.dirname(source_file)
  filename = File.basename(source_file, '.md')

  next if filename == 'README'

  target_folder = File.join(folder, filename)
  target = File.join(target_folder, 'README.md')
  
  FileUtils.mkdir_p target_folder
  FileUtils.mv source_file, target
end

FileUtils.mkdir_p('unused-images')
Dir.glob('**/*.{png,jpg,gif}').each do |image_file|
  image_filename = File.basename(image_file)
  contained = `rg -l '#{image_filename}'`.lines.map(&:chomp)

  if contained.empty?
    FileUtils.mv image_file, 'unused-images'
  elsif contained.length > 1
    warn "Skipping #{image_file} as used in more than one: #{contained.join(", ")}"
  else
    target_folder = File.dirname contained.first
    target_file = File.join(target_folder, image_filename)

    if image_file == target_file
      puts "Image is already at #{target_file}"
    else
      FileUtils.mv image_file, target_folder
    end
  end
end
