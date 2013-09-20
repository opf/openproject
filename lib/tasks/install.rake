require 'fileutils'

namespace :redmine do
  namespace :backlogs do

    desc "Install default label definitions"
    task :default_labels => :environment do
      FileUtils.cp(TaskboardCard::PageLayout::LABELS_FILE_NAME + '.default',
                   TaskboardCard::PageLayout::LABELS_FILE_NAME)
    end

    desc "Install current label definitions git.gnome.org"
    task :current_labels => :environment do
      TaskboardCard::PageLayout.fetch_labels
    end

    desc "Install and configure Redmine Backlogs"
    task :install => :environment do |t|
      ENV["RAILS_ENV"] ||= "development"

      ['prawn'].each do |gem|
        begin
          require gem
        rescue LoadError
          raise "You are missing the '#{gem}' gem"
        end
      end

      # Necessary because adding key-value pairs one by one doesn't seem to work
      settings = Setting.plugin_openproject_backlogs
      settings["points_burn_direction"] ||= 'down'
      settings["wiki_template"]         ||= ''

      puts
      puts "====================================================="
      puts "             Redmine Backlogs Installer"
      puts "====================================================="
      puts "Installing to the #{ENV['RAILS_ENV']} environment."

      unless ['no', 'false'].include? "#{ENV['labels']}".downcase
        Rake::Task['redmine:backlogs:current_labels'].invoke
      end

      settings["card_spec"] ||= Cards::TaskboardCards::LABELS.keys[0] unless Cards::TaskboardCards::LABELS.size == 0

      types = Type.find(:all)

      if Story.types.length == 0
        puts "Configuring story and task types..."
        invalid = true
        while invalid
          puts "-----------------------------------------------------"
          puts "Which types do you want to use for your stories?"
          types.each_with_index { |t, i| puts "  #{ i + 1 }. #{ t.name }" }
          print "Separate values with a space (e.g. 1 3): "
          STDOUT.flush
          selection = (STDIN.gets.chomp!).split(/\D+/)

          # Check that all values correspond to an items in the list
          invalid = false
          invalid_value = nil
          type_names = []
          selection.each do |s|
            if s.to_i > types.length
              invalid = true
              invalid_value = s
              break
            else
              type_names << types[s.to_i-1].name
            end
          end

          if invalid
            puts "Oooops! You entered an invalid value (#{invalid_value}). Please try again."
          else
            print "You selected the following types: #{type_names.join(', ')}. Is this correct? (y/n) "
            STDOUT.flush
            invalid = !(STDIN.gets.chomp!).match("y")
          end
        end

        settings["story_types"] = selection.map{ |s| types[s.to_i-1].id }
      end


      if !Task.type
        # Check if there is at least one type available
        puts "-----------------------------------------------------"
        if settings["story_types"].length < types.length
          invalid = true
          while invalid
            # If there's at least one, ask the user to pick one
            puts "Which type do you want to use for your tasks?"
            available_types = types.select{|t| !settings["story_types"].include? t.id}
            j = 0
            available_types.each_with_index { |t, i| puts "  #{ j = i + 1 }. #{ t.name }" }

            print "Choose one from above: "
            STDOUT.flush
            selection = (STDIN.gets.chomp!).split(/\D+/)

            if selection.length > 0 and selection.first.to_i <= available_types.length
              # If the user picked one, use that
              print "You selected #{available_types[selection.first.to_i-1].name}. Is this correct? (y/n) "
              STDOUT.flush
              if (STDIN.gets.chomp!).match("y")
                settings["task_type"] = available_types[selection.first.to_i-1].id
                invalid = false
              end
            else
              puts "Oooops! That's not a valid selection. Please try again."
            end
          end
        else
          # If there's none, ask to create one
          puts "You don't have any types available for use with tasks."
          puts "Please create a new type via the Redmine admin interface,"
          puts "then re-run this installer. Press any key to continue."
          STDOUT.flush
          STDIN.gets
        end
      end

      # Necessary because adding key-value pairs one by one doesn't seem to work
      Setting.plugin_openproject_backlogs = settings

      puts "Story and task types are now set."

      puts "Migrating the database..."
      STDOUT.flush
      system('rake db:migrate_plugins --trace > backlogs_install.log')
      if $?==0
        puts "done!"
        puts "Installation complete. Please restart Redmine."
        puts "Thank you for trying out Redmine Backlogs!"
      else
        puts "ERROR!"
        puts "*******************************************************"
        puts " Whoa! An error occurred during database migration."
        puts " Please see backlogs_install.log for more info."
        puts "*******************************************************"
      end
    end
  end
end
