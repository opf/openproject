directory = File.dirname File.dirname(__FILE__)
project = File.basename directory
namespace :gloc_to_i18n do
  task project do
    chdir(directory) do
      Dir.glob("lang/*.yml") do |file|
        lang = file[5..-5]
        target = "config/locales/#{lang}.yml"
        mkdir_p File.dirname(target)
        File.open(target, "w") do |f| 
          f << ({lang => YAML.load_file(file)}.to_yaml)
        end
      end
    end
  end
end

task :gloc_to_i18n => "gloc_to_i18n:#{project}"