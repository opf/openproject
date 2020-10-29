# -*- ruby -*-
# frozen_string_literal: true

module PG
	module BinaryDecoder
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
	end
end # module PG
