namespace :copyright do
  desc "Update the copyright on the source files"
  task :update do
    short_copyright = File.readlines("doc/COPYRIGHT_short.rdoc").collect do |line|
      "# #{line}"
    end.join("")

    short_copyright_as_rdoc = "#-- copyright\n" + short_copyright + "#++"

    Dir['**/**{.rb,.rake}'].each do |file_name|
      # Skip 3rd party code
      next if file_name.include?("vendor") ||
        file_name.include?("lib/SVG") ||
        file_name.include?("lib/faster_csv") ||
        file_name.include?("lib/redcloth") ||
        file_name.include?("lib/diff")
      next if file_name.include?("lib/tasks/copyright") # skip self
      next if file_name.include?("unified_diff_test") # confict

      file_content = File.read(file_name)
      @copyright_regex = /#-- copyright.*\+\+/m
      if file_content.match(@copyright_regex)
        file_content.gsub!(@copyright_regex, short_copyright_as_rdoc)
      else
        file_content = short_copyright_as_rdoc + "\n\n" + file_content # Prepend
      end
      
      File.open(file_name, "w") do |file|
        file.write file_content
      end
      
    end
    
  end
end
