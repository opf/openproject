# Forces using the classic json gem when parsing.
# This might be beneficial in cases where other parsers, orchestrated by MultiJson misbehave.
# This is e.g. the case with oj which sometimes turns numbers into BigDecimal values.
module API::Utilities::JsonGemParser
  def self.call(object, _)
    ::Grape::Json.load(object, adapter: :json_gem)
  rescue ::Grape::Json::ParseError
    # handle JSON parsing errors via the rescue handlers or provide error message
    raise Grape::Exceptions::InvalidMessageBody, 'application/json'
  end
end
