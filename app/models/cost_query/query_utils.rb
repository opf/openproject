module CostQuery::QueryUtils
  include Redmine::I18n
  include Report::QueryUtils

  def map_field(key, value)
    case key.to_s
    when "user_id"                          then value ? user_name(value.to_i) : ''
    when "tweek", "tyear", "tmonth", /_id$/ then value.to_i
    when "week"                             then value.to_i.divmod(100)
    when /_(on|at)$/                        then value ? Time.parse(value) : Time.at(0)
    when /^custom_field/                    then value.to_s
    when "singleton_value"                  then value.to_i
    else super
    end
  end

  def user_name(id)
    # we have no identity map... :(
    cache[:user_name][id] ||= User.find(id).name
  end

  ##
  # Graceful, internationalized quoted string.
  #
  # @see quote_string
  # @param [Object] str String to quote/translate
  # @return [Object] Quoted, translated version
  def quoted_label(ident)
    "'#{quote_string l(ident)}'"
  end

  propagate!
end

