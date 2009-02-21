namespace :locales do
  desc 'Updates language files based on en.yml content (only works for new top level keys).'
  task :update do
    dir = ENV['DIR'] || './config/locales'
    
    en_strings = YAML.load(File.read(File.join(dir,'en.yml')))['en']
    
    files = Dir.glob(File.join(dir,'fr.{yaml,yml}'))
    files.each do |file|
      puts "Updating file #{file}"
      file_strings = YAML.load(File.read(file))
      file_strings = file_strings[file_strings.keys.first]
    
      missing_keys = en_strings.keys - file_strings.keys
      next if missing_keys.empty?
      
      puts "==> Missing #{missing_keys.size} keys (#{missing_keys.join(', ')})"
      lang = File.open(file, 'a')
      
      missing_keys.each do |key|
        {key => en_strings[key]}.to_yaml.each_line do |line|
          next if line =~ /^---/ || line.empty?
          puts "  #{line}"
          lang << "  #{line}"
        end
      end
      
      lang.close
    end
  end
end
