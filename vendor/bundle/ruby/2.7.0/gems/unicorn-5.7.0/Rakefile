# optional rake-compiler support in case somebody needs to cross compile
begin
  mk = "ext/unicorn_http/Makefile"
  if File.readable?(mk)
    warn "run 'gmake -C ext/unicorn_http clean' and\n" \
         "remove #{mk} before using rake-compiler"
  elsif ENV['VERSION']
    unless File.readable?("ext/unicorn_http/unicorn_http.c")
      abort "run 'gmake ragel' or 'make ragel' to generate the Ragel source"
    end
    spec = Gem::Specification.load('unicorn.gemspec')
    require 'rake/extensiontask'
    Rake::ExtensionTask.new('unicorn_http', spec)
  end
rescue LoadError
end
