namespace :gloc do
  desc 'Sorts the keys in the lang ymls'
  task :sort do
    dir = ENV['DIR'] || '{.,vendor/plugins/*}/lang'
    puts "Processing directory #{dir}"
    files = Dir.glob(File.join(dir,'*.{yaml,yml}'))
    puts 'No files found.' if files.empty?
    files.each {|file|
      puts "Sorting file: #{file}"
      header = []
      content = IO.readlines(file)
      content.each {|line| line.gsub!(/[\s\r\n\t]+$/,'')}
      content.delete_if {|line| line==''}
      tmp= []
      content.each {|x| tmp << x unless tmp.include?(x)}
      content= tmp
      header << content.shift if !content.empty? && content[0] =~ /^file_charset:/
      content.sort!
      filebak = "#{file}.bak"
      File.rename file, filebak
      File.open(file, 'w') {|fout| fout << header.join("\n") << content.join("\n") << "\n"}
      File.delete filebak
      # Report duplicates
      count= {}
      content.map {|x| x.gsub(/:.+$/, '') }.each {|x| count[x] ||= 0; count[x] += 1}
      count.delete_if {|k,v|v==1}
      puts count.keys.sort.map{|x|"  WARNING: Duplicate key '#{x}' (#{count[x]} occurances)"}.join("\n") unless count.empty?
    }
  end
end