# frozen_string_literal: true
INLINE_SCRIPT_REGEX = /(<script(\s*(?!src)([\w\-])+=([\"\'])[^\"\']+\4)*\s*>)(.*?)<\/script>/mx unless defined? INLINE_SCRIPT_REGEX
INLINE_STYLE_REGEX = /(<style[^>]*>)(.*?)<\/style>/mx unless defined? INLINE_STYLE_REGEX
INLINE_HASH_SCRIPT_HELPER_REGEX = /<%=\s?hashed_javascript_tag(.*?)\s+do\s?%>(.*?)<%\s*end\s*%>/mx unless defined? INLINE_HASH_SCRIPT_HELPER_REGEX
INLINE_HASH_STYLE_HELPER_REGEX = /<%=\s?hashed_style_tag(.*?)\s+do\s?%>(.*?)<%\s*end\s*%>/mx unless defined? INLINE_HASH_STYLE_HELPER_REGEX

namespace :secure_headers do
  include SecureHeaders::HashHelper

  def is_erb?(filename)
    filename =~ /\.erb\Z/
  end

  def is_mustache?(filename)
    filename =~ /\.mustache\Z/
  end

  def dynamic_content?(filename, inline_script)
    (is_mustache?(filename) && inline_script =~ /\{\{.*\}\}/) ||
      (is_erb?(filename) && inline_script =~ /<%.*%>/)
  end

  def find_inline_content(filename, regex, hashes)
    file = File.read(filename)
    file.scan(regex) do # TODO don't use gsub
      inline_script = Regexp.last_match.captures.last
      if dynamic_content?(filename, inline_script)
        puts "Looks like there's some dynamic content inside of a tag :-/"
        puts "That pretty much means the hash value will never match."
        puts "Code: " + inline_script
        puts "=" * 20
      end

      hashes << hash_source(inline_script)
    end
  end

  def generate_inline_script_hashes(filename)
    hashes = []

    [INLINE_SCRIPT_REGEX, INLINE_HASH_SCRIPT_HELPER_REGEX].each do |regex|
      find_inline_content(filename, regex, hashes)
    end

    hashes
  end

  def generate_inline_style_hashes(filename)
    hashes = []

    [INLINE_STYLE_REGEX, INLINE_HASH_STYLE_HELPER_REGEX].each do |regex|
      find_inline_content(filename, regex, hashes)
    end

    hashes
  end

  desc "Generate #{SecureHeaders::Configuration::HASH_CONFIG_FILE}"
  task :generate_hashes do |t, args|
    script_hashes = {
      "scripts" => {},
      "styles" => {}
    }

    Dir.glob("app/{views,templates}/**/*.{erb,mustache}") do |filename|
      hashes = generate_inline_script_hashes(filename)
      if hashes.any?
        script_hashes["scripts"][filename] = hashes
      end

      hashes = generate_inline_style_hashes(filename)
      if hashes.any?
        script_hashes["styles"][filename] = hashes
      end
    end

    File.open(SecureHeaders::Configuration::HASH_CONFIG_FILE, "w") do |file|
      file.write(script_hashes.to_yaml)
    end

    puts "Script hashes from " + script_hashes.keys.size.to_s + " files added to #{SecureHeaders::Configuration::HASH_CONFIG_FILE}"
  end
end
