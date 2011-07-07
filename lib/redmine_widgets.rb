Dir.entries(path = File.join(File.dirname(__FILE__), 'redmine_widget')).each do |f|
  require File.join(path, f[0..-4]) if /.rb$/.match f
end
