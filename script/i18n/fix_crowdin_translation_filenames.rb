require 'fileutils'

Dir.glob('**/config/locales/crowdin/*.yml').each do |crowdin_file|
  # Get the line that contains the first language key
  language_key = nil
  filename = File.basename(crowdin_file)

  # Skip the empty in-context translations
  next if filename.include?('lol.')

  File.readlines(crowdin_file).each do |line|
    if line.match(/^\s*(\S{2,}):\s*$/)
      language_key = $1
      break
    end
  end

  # Read the language code from the YML index
  if language_key.nil?
    raise "Failed to detect language from #{crowdin_file}"
  end

  # Remove any escaped language names
  language_key.delete!('"')

  # the files should be named like their translation-key
  new_filename =
    case filename
    when /\Ajs-.+\z/
      "js-#{language_key}.yml"
    when /.+\.seeders\.yml\z/
      "#{language_key}.seeders.yml"
    else
      "#{language_key}.yml"
    end

  directory = File.dirname(crowdin_file)
  new_filepath = File.join(directory, new_filename)

  next if crowdin_file == new_filepath

  puts "Renaming #{crowdin_file} to #{new_filepath}"
  FileUtils.mv crowdin_file,
               new_filepath,
               force: true,
               verbose: true
end
