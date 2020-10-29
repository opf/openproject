# -*- ruby -*-
# frozen_string_literal: true

require 'date'
require 'json'

module PG
	module TextDecoder
		class Date < SimpleDecoder
			def decode(string, tuple=nil, field=nil)
				if string =~ /\A(\d{4})-(\d\d)-(\d\d)\z/
					::Date.new $1.to_i, $2.to_i, $3.to_i
				else
					string
				end
			end
		end

		class JSON < SimpleDecoder
			def decode(string, tuple=nil, field=nil)
				::JSON.parse(string, quirks_mode: true)
			end
		end

		# Convenience classes for timezone options
		class TimestampUtc < Timestamp
			def initialize(params={})
				super(params.merge(flags: PG::Coder::TIMESTAMP_DB_UTC | PG::Coder::TIMESTAMP_APP_UTC))
			end
		end
		class TimestampUtcToLocal < Timestamp
			def initialize(params={})
				super(params.merge(flags: PG::Coder::TIMESTAMP_DB_UTC | PG::Coder::TIMESTAMP_APP_LOCAL))
			end
		end
		class TimestampLocal < Timestamp
			def initialize(params={})
				super(params.merge(flags: PG::Coder::TIMESTAMP_DB_LOCAL | PG::Coder::TIMESTAMP_APP_LOCAL))
			end
		end

		# For backward compatibility:
		TimestampWithoutTimeZone = TimestampLocal
		TimestampWithTimeZone = Timestamp
	end
end # module PG
