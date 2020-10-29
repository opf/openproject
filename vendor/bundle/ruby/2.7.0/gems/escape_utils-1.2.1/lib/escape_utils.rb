require 'escape_utils/escape_utils'
require 'escape_utils/version' unless defined? EscapeUtils::VERSION

module EscapeUtils
  extend self

  # turn on/off the escaping of the '/' character during HTML escaping
  # Escaping '/' is recommended by the OWASP - http://www.owasp.org/index.php/XSS_(Cross_Site_Scripting)_Prevention_Cheat_Sheet#RULE_.231_-_HTML_Escape_Before_Inserting_Untrusted_Data_into_HTML_Element_Content
  # This is because quotes around HTML attributes are optional in most/all modern browsers at the time of writing (10/15/2010)
  def self.html_secure
    @html_secure
  end
  self.html_secure = true

  # Default String class to return from HTML escaping
  def self.html_safe_string_class
    @html_safe_string_class
  end
  self.html_safe_string_class = String

  autoload :HtmlSafety, 'escape_utils/html_safety'
end