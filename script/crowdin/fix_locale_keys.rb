require 'fileutils'

def js_translation?(translation_file_path)
  filename = File.basename translation_file_path.to_s
  filename.match? /\Ajs-.+\z/
end

Dir.glob('**/config/locales/crowdin/*.yml').each do |crowdin_file|
  # Get the line that contains the first language key
  language_key = nil
  filename = File.basename(crowdin_file)

  File.readlines(crowdin_file).each do |line|
    if line.match(/^\s*(\S{2,}):\s*$/)
      language_key = $1
      break
    end
  end

  # Read the language code from the YML index
  if language_key.nil? || language_key.length > 5
    raise "Failed to detect language from #{crowdin_file}"
  end

  # Remove any escaped language names
  language_key.delete!('"')

  # the files should be named like their translation-key
  new_filename = "#{js_translation?(filename) ? 'js-' : ''}#{language_key}.yml"
  directory = File.dirname(crowdin_file)
  new_filepath = File.join(directory, new_filename)

  next if crowdin_file == new_filepath

  puts "Renaming #{crowdin_file} to #{new_filepath}"
  FileUtils.mv crowdin_file,
               new_filepath,
               force: true,
               verbose: true
end
