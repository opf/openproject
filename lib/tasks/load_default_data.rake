desc 'Load Redmine default configuration data. Language is chosen interactively or by setting REDMINE_LANG environment variable.'

namespace :redmine do
  task :load_default_data => :environment do
    include Redmine::I18n
    set_language_if_valid('en')
    
    envlang = ENV['REDMINE_LANG']
    if !envlang || !set_language_if_valid(envlang)
      puts
      while true
        print "Select language: "
        print valid_languages.collect(&:to_s).sort.join(", ")
        print " [#{current_language}] "
        STDOUT.flush
        lang = STDIN.gets.chomp!
        break if lang.empty?
        break if set_language_if_valid(lang)
        puts "Unknown language!"
      end
      STDOUT.flush
      puts "===================================="
    end
    
    begin
      Redmine::DefaultData::Loader.load(current_language)
      puts "Default configuration data loaded."
    rescue Redmine::DefaultData::DataAlreadyLoaded => error
      puts error
    rescue => error
      puts "Error: " + error
      puts "Default configuration data was not loaded."
    end
  end
end
