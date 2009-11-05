directory = File.dirname File.dirname(__FILE__)
project = File.basename directory
namespace :gloc_to_i18n do
  task project do
    chdir(directory) do
      Dir.glob("lang/*.yml") do |file|
        lang = file[5..-5]
        target = "config/locales/#{lang}.yml"
        locales = YAML.load_file(target) if File.exist? target
        locales ||= {}
        (locales[lang] ||= {}).merge! YAML.load_file(target)
        mkdir_p File.dirname(target)
        File.open(target, "w") { |f| f << locales.to_yaml }
        File.open(file, "w") { |f| f << locales[lang].to_yaml }
      end
    end
  end
end

task :gloc_to_i18n => "gloc_to_i18n:#{project}"