namespace :code do
  desc "Fix line endings of all source files"
  task :fix_line_endings do
    unless `which fromdos`.present?
      raise "fromdos command not found"
    end
    
    Dir['**/**{.rb,.html.erb,.rhtml,.rjs,.rsb,.plain.erb,.rxml,.yml,.rake,.eml}'].each do |file_name|
      next if file_name.include?("vendor")
      system("fromdos #{file_name}")
    end
    
  end
end
