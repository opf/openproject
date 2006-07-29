# Copyright (c) 2005-2006 David Barri

module GLoc

  private

  CONFIG= {} unless const_defined?(:CONFIG)
  unless CONFIG.frozen?
    CONFIG[:default_language] ||= :en
    CONFIG[:default_param_name] ||= 'lang'
    CONFIG[:default_cookie_name] ||= 'lang'
    CONFIG[:raise_string_not_found_errors]= true unless CONFIG.has_key?(:raise_string_not_found_errors)
    CONFIG[:verbose] ||= false
  end
  
end
