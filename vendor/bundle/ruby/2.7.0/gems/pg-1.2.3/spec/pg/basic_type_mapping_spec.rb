# -*- rspec -*-
# encoding: utf-8

require_relative '../helpers'

require 'pg'
require 'time'

def restore_type(types)
	[0, 1].each do |format|
		[types].flatten.each do |type|
			PG::BasicTypeRegistry.alias_type(format, "restore_#{type}", type)
		end
	end
	yield
ensure
	[0, 1].each do |format|
		[types].flatten.each do |type|
			PG::BasicTypeRegistry.alias_type(format, type, "restore_#{type}")
		end
	end
end

describe 'Basic type mapping' do

	describe PG::BasicTypeMapForQueries do
		let!(:basic_type_mapping) do
			PG::BasicTypeMapForQueries.new @conn
		end

		#
		# Encoding Examples
		#

		it "should do basic param encoding" do
			res = @conn.exec_params( "SELECT $1::int8, $2::float, $3, $4::TEXT",
				[1, 2.1, true, "b"], nil, basic_type_mapping )

			expect( res.values ).to eq( [
					[ "1", "2.1", "t", "b" ],
			] )

			expect( result_typenames(res) ).to eq( ['bigint', 'double precision', 'boolean', 'text'] )
		end

		it "should do basic Time encoding" do
			res = @conn.exec_params( "SELECT $1 AT TIME ZONE '-02'",
				[Time.new(2019, 12, 8, 20, 38, 12.123, "-01:00")], nil, basic_type_mapping )

			expect( res.values ).to eq( [[ "2019-12-08 23:38:12.123" ]] )
		end

		it "should do basic param encoding of various float values" do
			res = @conn.exec_params( "SELECT $1::float, $2::float, $3::float, $4::float, $5::float, $6::float, $7::float, $8::float, $9::float, $10::float, $11::float, $12::float",
				[0, 7, 9, 0.1, 0.9, -0.11, 10.11,
			   9876543210987654321e-400,
			   9876543210987654321e400,
			   -1.234567890123456789e-280,
			   -1.234567890123456789e280,
			   9876543210987654321e280
			  ], nil, basic_type_mapping )

			expect( res.values[0][0, 9] ).to eq(
					[ "0", "7", "9", "0.1", "0.9", "-0.11", "10.11", "0", "Infinity" ]
			)

			expect( res.values[0][9]  ).to match( /^-1\.2345678901234\d*e\-280$/ )
			expect( res.values[0][10] ).to match( /^-1\.2345678901234\d*e\+280$/ )
			expect( res.values[0][11] ).to match(  /^9\.8765432109876\d*e\+298$/ )

			expect( result_typenames(res) ).to eq( ['double precision'] * 12 )
		end

		it "should do default array-as-array param encoding" do
			expect( basic_type_mapping.encode_array_as).to eq(:array)
			res = @conn.exec_params( "SELECT $1,$2,$3,$4,$5,$6", [
					[1, 2, 3], # Integer -> bigint[]
					[[1, 2], [3, nil]], # Integer two dimensions -> bigint[]
					[1.11, 2.21], # Float -> double precision[]
					['/,"'.gsub("/", "\\"), nil, 'abcäöü'], # String -> text[]
					[BigDecimal("123.45")], # BigDecimal -> numeric[]
					[IPAddr.new('1234::5678')], # IPAddr -> inet[]
				], nil, basic_type_mapping )

			expect( res.values ).to eq( [[
					'{1,2,3}',
					'{{1,2},{3,NULL}}',
					'{1.11,2.21}',
					'{"//,/"",NULL,abcäöü}'.gsub("/", "\\"),
					'{123.45}',
					'{1234::5678}',
			]] )

			expect( result_typenames(res) ).to eq( ['bigint[]', 'bigint[]', 'double precision[]', 'text[]', 'numeric[]', 'inet[]'] )
		end

		it "should do default array-as-array param encoding with Time objects" do
			res = @conn.exec_params( "SELECT $1", [
					[Time.new(2019, 12, 8, 20, 38, 12.123, "-01:00")], # Time -> timestamptz[]
				], nil, basic_type_mapping )

			expect( res.values[0][0] ).to match( /\{\"2019-12-08 \d\d:38:12.123[+-]\d\d\"\}/ )
			expect( result_typenames(res) ).to eq( ['timestamp with time zone[]'] )
		end

		it "should do array-as-json encoding" do
			basic_type_mapping.encode_array_as = :json
			expect( basic_type_mapping.encode_array_as).to eq(:json)

			res = @conn.exec_params( "SELECT $1::JSON, $2::JSON", [
					[1, {a: 5}, true, ["a", 2], [3.4, nil]],
					['/,"'.gsub("/", "\\"), nil, 'abcäöü'],
				], nil, basic_type_mapping )

			expect( res.values ).to eq( [[
					'[1,{"a":5},true,["a",2],[3.4,null]]',
					'["//,/"",null,"abcäöü"]'.gsub("/", "\\"),
			]] )

			expect( result_typenames(res) ).to eq( ['json', 'json'] )
		end

		it "should do hash-as-json encoding" do
			res = @conn.exec_params( "SELECT $1::JSON, $2::JSON", [
					{a: 5, b: ["a", 2], c: nil},
					{qu: '/,"'.gsub("/", "\\"), ni: nil, uml: 'abcäöü'},
				], nil, basic_type_mapping )

			expect( res.values ).to eq( [[
					'{"a":5,"b":["a",2],"c":null}',
					'{"qu":"//,/"","ni":null,"uml":"abcäöü"}'.gsub("/", "\\"),
			]] )

			expect( result_typenames(res) ).to eq( ['json', 'json'] )
		end

		describe "Record encoding" do
			before :all do
				@conn.exec("CREATE TYPE test_record1 AS (i int, d float, t text)")
				@conn.exec("CREATE TYPE test_record2 AS (i int, r test_record1)")
			end

			after :all do
				@conn.exec("DROP TYPE IF EXISTS test_record2 CASCADE")
				@conn.exec("DROP TYPE IF EXISTS test_record1 CASCADE")
			end

			it "should do array-as-record encoding" do
				basic_type_mapping.encode_array_as = :record
				expect( basic_type_mapping.encode_array_as).to eq(:record)

				res = @conn.exec_params( "SELECT $1::test_record1, $2::test_record2, $3::text", [
						[5, 3.4, "txt"],
				    [1, [2, 4.5, "bcd"]],
				    [4, 5, 6],
					], nil, basic_type_mapping )

				expect( res.values ).to eq( [[
						'(5,3.4,txt)',
				    '(1,"(2,4.5,bcd)")',
						'("4","5","6")',
				]] )

				expect( result_typenames(res) ).to eq( ['test_record1', 'test_record2', 'text'] )
			end
		end

		it "should do bigdecimal param encoding" do
			large = ('123456790'*10) << '.' << ('012345679')
			res = @conn.exec_params( "SELECT $1::numeric,$2::numeric",
				[BigDecimal('1'), BigDecimal(large)], nil, basic_type_mapping )

			expect( res.values ).to eq( [
					[ "1.0", large ],
			] )

			expect( result_typenames(res) ).to eq( ['numeric', 'numeric'] )
		end

		it "should do IPAddr param encoding" do
			res = @conn.exec_params( "SELECT $1::inet,$2::inet,$3::cidr,$4::cidr",
				['1.2.3.4', IPAddr.new('1234::5678'), '1.2.3.4', IPAddr.new('1234:5678::/32')], nil, basic_type_mapping )

			expect( res.values ).to eq( [
					[ '1.2.3.4', '1234::5678', '1.2.3.4/32', '1234:5678::/32'],
			] )

			expect( result_typenames(res) ).to eq( ['inet', 'inet', 'cidr', 'cidr'] )
		end

		it "should do array of string encoding on unknown classes" do
			iv = Class.new do
				def to_s
					"abc"
				end
			end.new
			res = @conn.exec_params( "SELECT $1", [
					[iv, iv], # Unknown -> text[]
				], nil, basic_type_mapping )

			expect( res.values ).to eq( [[
					'{abc,abc}',
			]] )

			expect( result_typenames(res) ).to eq( ['text[]'] )
		end

	end



	describe PG::BasicTypeMapForResults do
		let!(:basic_type_mapping) do
			PG::BasicTypeMapForResults.new @conn
		end

		#
		# Decoding Examples
		#

		it "should do OID based type conversions" do
			res = @conn.exec( "SELECT 1, 'a', 2.0::FLOAT, TRUE, '2013-06-30'::DATE, generate_series(4,5)" )
			expect( res.map_types!(basic_type_mapping).values ).to eq( [
					[ 1, 'a', 2.0, true, Date.new(2013,6,30), 4 ],
					[ 1, 'a', 2.0, true, Date.new(2013,6,30), 5 ],
			] )
		end

		#
		# Decoding Examples text+binary format converters
		#

		describe "connection wide type mapping" do
			before :each do
				@conn.type_map_for_results = basic_type_mapping
			end

			after :each do
				@conn.type_map_for_results = PG::TypeMapAllStrings.new
			end

			it "should do boolean type conversions" do
				[1, 0].each do |format|
					res = @conn.exec_params( "SELECT true::BOOLEAN, false::BOOLEAN, NULL::BOOLEAN", [], format )
					expect( res.values ).to eq( [[true, false, nil]] )
				end
			end

			it "should do binary type conversions" do
				[1, 0].each do |format|
					res = @conn.exec_params( "SELECT E'\\\\000\\\\377'::BYTEA", [], format )
					expect( res.values ).to eq( [[["00ff"].pack("H*")]] )
					expect( res.values[0][0].encoding ).to eq( Encoding::ASCII_8BIT ) if Object.const_defined? :Encoding
				end
			end

			it "should do integer type conversions" do
				[1, 0].each do |format|
					res = @conn.exec_params( "SELECT -8999::INT2, -899999999::INT4, -8999999999999999999::INT8", [], format )
					expect( res.values ).to eq( [[-8999, -899999999, -8999999999999999999]] )
				end
			end

			it "should do string type conversions" do
				@conn.internal_encoding = 'utf-8' if Object.const_defined? :Encoding
				[1, 0].each do |format|
					res = @conn.exec_params( "SELECT 'abcäöü'::TEXT", [], format )
					expect( res.values ).to eq( [['abcäöü']] )
					expect( res.values[0][0].encoding ).to eq( Encoding::UTF_8 ) if Object.const_defined? :Encoding
				end
			end

			it "should do float type conversions" do
				[1, 0].each do |format|
					res = @conn.exec_params( "SELECT -8.999e3::FLOAT4,
														8.999e10::FLOAT4,
														-8999999999e-99::FLOAT8,
														NULL::FLOAT4,
														'NaN'::FLOAT4,
														'Infinity'::FLOAT4,
														'-Infinity'::FLOAT4
													", [], format )
					expect( res.getvalue(0,0) ).to be_within(1e-2).of(-8.999e3)
					expect( res.getvalue(0,1) ).to be_within(1e5).of(8.999e10)
					expect( res.getvalue(0,2) ).to be_within(1e-109).of(-8999999999e-99)
					expect( res.getvalue(0,3) ).to be_nil
					expect( res.getvalue(0,4) ).to be_nan
					expect( res.getvalue(0,5) ).to eq( Float::INFINITY )
					expect( res.getvalue(0,6) ).to eq( -Float::INFINITY )
				end
			end

			it "should do text datetime without time zone type conversions" do
				# for backward compat text timestamps without time zone are treated as local times
				res = @conn.exec_params( "SELECT CAST('2013-12-31 23:58:59+02' AS TIMESTAMP WITHOUT TIME ZONE),
																	CAST('1913-12-31 23:58:59.1231-03' AS TIMESTAMP WITHOUT TIME ZONE),
																	CAST('4714-11-24 23:58:59.1231-03 BC' AS TIMESTAMP WITHOUT TIME ZONE),
																	CAST('294276-12-31 23:58:59.1231-03' AS TIMESTAMP WITHOUT TIME ZONE),
																	CAST('infinity' AS TIMESTAMP WITHOUT TIME ZONE),
																	CAST('-infinity' AS TIMESTAMP WITHOUT TIME ZONE)", [], 0 )
				expect( res.getvalue(0,0) ).to eq( Time.new(2013, 12, 31, 23, 58, 59) )
				expect( res.getvalue(0,1).iso8601(3) ).to eq( Time.new(1913, 12, 31, 23, 58, 59.1231).iso8601(3) )
				expect( res.getvalue(0,2).iso8601(3) ).to eq( Time.new(-4713, 11, 24, 23, 58, 59.1231).iso8601(3) )
				expect( res.getvalue(0,3).iso8601(3) ).to eq( Time.new(294276, 12, 31, 23, 58, 59.1231).iso8601(3) )
				expect( res.getvalue(0,4) ).to eq( 'infinity' )
				expect( res.getvalue(0,5) ).to eq( '-infinity' )
			end

			[1, 0].each do |format|
				it "should convert format #{format} timestamps per TimestampUtc" do
					restore_type("timestamp") do
						PG::BasicTypeRegistry.register_type 0, 'timestamp', nil, PG::TextDecoder::TimestampUtc
						@conn.type_map_for_results = PG::BasicTypeMapForResults.new(@conn)
						res = @conn.exec_params( "SELECT CAST('2013-07-31 23:58:59+02' AS TIMESTAMP WITHOUT TIME ZONE),
																			CAST('1913-12-31 23:58:59.1231-03' AS TIMESTAMP WITHOUT TIME ZONE),
																			CAST('4714-11-24 23:58:59.1231-03 BC' AS TIMESTAMP WITHOUT TIME ZONE),
																			CAST('294276-12-31 23:58:59.1231-03' AS TIMESTAMP WITHOUT TIME ZONE),
																			CAST('infinity' AS TIMESTAMP WITHOUT TIME ZONE),
																			CAST('-infinity' AS TIMESTAMP WITHOUT TIME ZONE)", [], format )
						expect( res.getvalue(0,0).iso8601(3) ).to eq( Time.utc(2013, 7, 31, 23, 58, 59).iso8601(3) )
						expect( res.getvalue(0,1).iso8601(3) ).to eq( Time.utc(1913, 12, 31, 23, 58, 59.1231).iso8601(3) )
						expect( res.getvalue(0,2).iso8601(3) ).to eq( Time.utc(-4713, 11, 24, 23, 58, 59.1231).iso8601(3) )
						expect( res.getvalue(0,3).iso8601(3) ).to eq( Time.utc(294276, 12, 31, 23, 58, 59.1231).iso8601(3) )
						expect( res.getvalue(0,4) ).to eq( 'infinity' )
						expect( res.getvalue(0,5) ).to eq( '-infinity' )
					end
				end
			end

			[1, 0].each do |format|
				it "should convert format #{format} timestamps per TimestampUtcToLocal" do
					restore_type("timestamp") do
						PG::BasicTypeRegistry.register_type 0, 'timestamp', nil, PG::TextDecoder::TimestampUtcToLocal
						PG::BasicTypeRegistry.register_type 1, 'timestamp', nil, PG::BinaryDecoder::TimestampUtcToLocal
						@conn.type_map_for_results = PG::BasicTypeMapForResults.new(@conn)
						res = @conn.exec_params( "SELECT CAST('2013-07-31 23:58:59+02' AS TIMESTAMP WITHOUT TIME ZONE),
																			CAST('1913-12-31 23:58:59.1231-03' AS TIMESTAMP WITHOUT TIME ZONE),
																			CAST('4714-11-24 23:58:59.1231-03 BC' AS TIMESTAMP WITHOUT TIME ZONE),
																			CAST('294276-12-31 23:58:59.1231-03' AS TIMESTAMP WITHOUT TIME ZONE),
																			CAST('infinity' AS TIMESTAMP WITHOUT TIME ZONE),
																			CAST('-infinity' AS TIMESTAMP WITHOUT TIME ZONE)", [], format )
						expect( res.getvalue(0,0).iso8601(3) ).to eq( Time.utc(2013, 7, 31, 23, 58, 59).getlocal.iso8601(3) )
						expect( res.getvalue(0,1).iso8601(3) ).to eq( Time.utc(1913, 12, 31, 23, 58, 59.1231).getlocal.iso8601(3) )
						expect( res.getvalue(0,2).iso8601(3) ).to eq( Time.utc(-4713, 11, 24, 23, 58, 59.1231).getlocal.iso8601(3) )
						expect( res.getvalue(0,3).iso8601(3) ).to eq( Time.utc(294276, 12, 31, 23, 58, 59.1231).getlocal.iso8601(3) )
						expect( res.getvalue(0,4) ).to eq( 'infinity' )
						expect( res.getvalue(0,5) ).to eq( '-infinity' )
					end
				end
			end

			[1, 0].each do |format|
				it "should convert format #{format} timestamps per TimestampLocal" do
					restore_type("timestamp") do
						PG::BasicTypeRegistry.register_type 0, 'timestamp', nil, PG::TextDecoder::TimestampLocal
						PG::BasicTypeRegistry.register_type 1, 'timestamp', nil, PG::BinaryDecoder::TimestampLocal
						@conn.type_map_for_results = PG::BasicTypeMapForResults.new(@conn)
						res = @conn.exec_params( "SELECT CAST('2013-07-31 23:58:59' AS TIMESTAMP WITHOUT TIME ZONE),
																			CAST('1913-12-31 23:58:59.1231' AS TIMESTAMP WITHOUT TIME ZONE),
																			CAST('4714-11-24 23:58:59.1231-03 BC' AS TIMESTAMP WITHOUT TIME ZONE),
																			CAST('294276-12-31 23:58:59.1231+03' AS TIMESTAMP WITHOUT TIME ZONE),
																			CAST('infinity' AS TIMESTAMP WITHOUT TIME ZONE),
																			CAST('-infinity' AS TIMESTAMP WITHOUT TIME ZONE)", [], format )
						expect( res.getvalue(0,0).iso8601(3) ).to eq( Time.new(2013, 7, 31, 23, 58, 59).iso8601(3) )
						expect( res.getvalue(0,1).iso8601(3) ).to eq( Time.new(1913, 12, 31, 23, 58, 59.1231).iso8601(3) )
						expect( res.getvalue(0,2).iso8601(3) ).to eq( Time.new(-4713, 11, 24, 23, 58, 59.1231).iso8601(3) )
						expect( res.getvalue(0,3).iso8601(3) ).to eq( Time.new(294276, 12, 31, 23, 58, 59.1231).iso8601(3) )
						expect( res.getvalue(0,4) ).to eq( 'infinity' )
						expect( res.getvalue(0,5) ).to eq( '-infinity' )
					end
				end
			end

			[0, 1].each do |format|
				it "should convert format #{format} timestamps with time zone" do
					res = @conn.exec_params( "SELECT CAST('2013-12-31 23:58:59+02' AS TIMESTAMP WITH TIME ZONE),
																		CAST('1913-12-31 23:58:59.1231-03' AS TIMESTAMP WITH TIME ZONE),
																		CAST('4714-11-24 23:58:59.1231-03 BC' AS TIMESTAMP WITH TIME ZONE),
																		CAST('294276-12-31 23:58:59.1231+03' AS TIMESTAMP WITH TIME ZONE),
																		CAST('infinity' AS TIMESTAMP WITH TIME ZONE),
																		CAST('-infinity' AS TIMESTAMP WITH TIME ZONE)", [], format )
					expect( res.getvalue(0,0) ).to be_within(1e-3).of( Time.new(2013, 12, 31, 23, 58, 59, "+02:00").getlocal )
					expect( res.getvalue(0,1) ).to be_within(1e-3).of( Time.new(1913, 12, 31, 23, 58, 59.1231, "-03:00").getlocal )
					expect( res.getvalue(0,2) ).to be_within(1e-3).of( Time.new(-4713, 11, 24, 23, 58, 59.1231, "-03:00").getlocal )
					expect( res.getvalue(0,3) ).to be_within(1e-3).of( Time.new(294276, 12, 31, 23, 58, 59.1231, "+03:00").getlocal )
					expect( res.getvalue(0,4) ).to eq( 'infinity' )
					expect( res.getvalue(0,5) ).to eq( '-infinity' )
				end
			end

			it "should do date type conversions" do
				[0].each do |format|
					res = @conn.exec_params( "SELECT CAST('2113-12-31' AS DATE),
																		CAST('1913-12-31' AS DATE),
																		CAST('infinity' AS DATE),
																		CAST('-infinity' AS DATE)", [], format )
					expect( res.getvalue(0,0) ).to eq( Date.new(2113, 12, 31) )
					expect( res.getvalue(0,1) ).to eq( Date.new(1913, 12, 31) )
					expect( res.getvalue(0,2) ).to eq( 'infinity' )
					expect( res.getvalue(0,3) ).to eq( '-infinity' )
				end
			end

			it "should do numeric type conversions" do
				[0].each do |format|
					small = '123456790123.12'
					large = ('123456790'*10) << '.' << ('012345679')
					numerics = [
						'1',
						'1.0',
						'1.2',
						small,
						large,
					]
					sql_numerics = numerics.map { |v| "CAST(#{v} AS numeric)" }
					res = @conn.exec_params( "SELECT #{sql_numerics.join(',')}", [], format )
					expect( res.getvalue(0,0) ).to eq( BigDecimal('1') )
					expect( res.getvalue(0,1) ).to eq( BigDecimal('1') )
					expect( res.getvalue(0,2) ).to eq( BigDecimal('1.2') )
					expect( res.getvalue(0,3) ).to eq( BigDecimal(small) )
					expect( res.getvalue(0,4) ).to eq( BigDecimal(large) )
				end
			end

			it "should do JSON conversions", :postgresql_94 do
				[0].each do |format|
					['JSON', 'JSONB'].each do |type|
						res = @conn.exec_params( "SELECT CAST('123' AS #{type}),
																			CAST('12.3' AS #{type}),
																			CAST('true' AS #{type}),
																			CAST('false' AS #{type}),
																			CAST('null' AS #{type}),
																			CAST('[1, \"a\", null]' AS #{type}),
																			CAST('{\"b\" : [2,3]}' AS #{type})", [], format )
						expect( res.getvalue(0,0) ).to eq( 123 )
						expect( res.getvalue(0,1) ).to be_within(0.1).of( 12.3 )
						expect( res.getvalue(0,2) ).to eq( true )
						expect( res.getvalue(0,3) ).to eq( false )
						expect( res.getvalue(0,4) ).to eq( nil )
						expect( res.getvalue(0,5) ).to eq( [1, "a", nil] )
						expect( res.getvalue(0,6) ).to eq( {"b" => [2, 3]} )
					end
				end
			end

			it "should do array type conversions" do
				[0].each do |format|
					res = @conn.exec_params( "SELECT CAST('{1,2,3}' AS INT2[]), CAST('{{1,2},{3,4}}' AS INT2[][]),
															CAST('{1,2,3}' AS INT4[]),
															CAST('{1,2,3}' AS INT8[]),
															CAST('{1,2,3}' AS TEXT[]),
															CAST('{1,2,3}' AS VARCHAR[]),
															CAST('{1,2,3}' AS FLOAT4[]),
															CAST('{1,2,3}' AS FLOAT8[])
														", [], format )
					expect( res.getvalue(0,0) ).to eq( [1,2,3] )
					expect( res.getvalue(0,1) ).to eq( [[1,2],[3,4]] )
					expect( res.getvalue(0,2) ).to eq( [1,2,3] )
					expect( res.getvalue(0,3) ).to eq( [1,2,3] )
					expect( res.getvalue(0,4) ).to eq( ['1','2','3'] )
					expect( res.getvalue(0,5) ).to eq( ['1','2','3'] )
					expect( res.getvalue(0,6) ).to eq( [1.0,2.0,3.0] )
					expect( res.getvalue(0,7) ).to eq( [1.0,2.0,3.0] )
				end
			end

			it "should do inet type conversions" do
				[0].each do |format|
					vals = [
						'1.2.3.4',
						'0.0.0.0/0',
						'1.0.0.0/8',
						'1.2.0.0/16',
						'1.2.3.0/24',
						'1.2.3.4/24',
						'1.2.3.4/32',
						'1.2.3.128/25',
						'1234:3456:5678:789a:9abc:bced:edf0:f012',
						'::/0',
						'1234:3456::/32',
						'1234:3456:5678:789a::/64',
						'1234:3456:5678:789a:9abc:bced::/96',
						'1234:3456:5678:789a:9abc:bced:edf0:f012/128',
						'1234:3456:5678:789a:9abc:bced:edf0:f012/0',
						'1234:3456:5678:789a:9abc:bced:edf0:f012/32',
						'1234:3456:5678:789a:9abc:bced:edf0:f012/64',
						'1234:3456:5678:789a:9abc:bced:edf0:f012/96',
					]
					sql_vals = vals.map{|v| "CAST('#{v}' AS inet)"}
					res = @conn.exec_params(("SELECT " + sql_vals.join(', ')), [], format )
					vals.each_with_index do |v, i|
						expect( res.getvalue(0,i) ).to eq( IPAddr.new(v) )
					end
				end
			end

			it "should do cidr type conversions" do
				[0].each do |format|
					vals = [
						'0.0.0.0/0',
						'1.0.0.0/8',
						'1.2.0.0/16',
						'1.2.3.0/24',
						'1.2.3.4/32',
						'1.2.3.128/25',
						'::/0',
						'1234:3456::/32',
						'1234:3456:5678:789a::/64',
						'1234:3456:5678:789a:9abc:bced::/96',
						'1234:3456:5678:789a:9abc:bced:edf0:f012/128',
					]
					sql_vals = vals.map { |v| "CAST('#{v}' AS cidr)" }
					res = @conn.exec_params(("SELECT " + sql_vals.join(', ')), [], format )
					vals.each_with_index do |v, i|
						val = res.getvalue(0,i)
						ip, prefix = v.split('/', 2)
						expect( val.to_s ).to eq( ip )
						if val.respond_to?(:prefix)
							val_prefix = val.prefix
						else
							default_prefix = (val.family == Socket::AF_INET ? 32 : 128)
							range = val.to_range
							val_prefix	= default_prefix - Math.log(((range.end.to_i - range.begin.to_i) + 1), 2).to_i
						end
						if v.include?('/')
							expect( val_prefix ).to eq( prefix.to_i )
						elsif v.include?('.')
							expect( val_prefix ).to eq( 32 )
						else
							expect( val_prefix ).to eq( 128 )
						end
					end
				end
			end
		end

		context "with usage of result oids for copy decoder selection" do
			it "can type cast #copy_data output with explicit decoder" do
				@conn.exec( "CREATE TEMP TABLE copytable (t TEXT, i INT, ai INT[])" )
				@conn.exec( "INSERT INTO copytable VALUES ('a', 123, '{5,4,3}'), ('b', 234, '{2,3}')" )

				# Retrieve table OIDs per empty result.
				res = @conn.exec( "SELECT * FROM copytable LIMIT 0" )
				tm = basic_type_mapping.build_column_map( res )
				row_decoder = PG::TextDecoder::CopyRow.new type_map: tm

				rows = []
				@conn.copy_data( "COPY copytable TO STDOUT", row_decoder ) do |res|
					while row=@conn.get_copy_data
						rows << row
					end
				end
				expect( rows ).to eq( [['a', 123, [5,4,3]], ['b', 234, [2,3]]] )
			end
		end
	end


	describe PG::BasicTypeMapBasedOnResult do
		let!(:basic_type_mapping) do
			PG::BasicTypeMapBasedOnResult.new @conn
		end

		context "with usage of result oids for bind params encoder selection" do
			it "can type cast query params" do
				@conn.exec( "CREATE TEMP TABLE copytable (t TEXT, i INT, ai INT[])" )

				# Retrieve table OIDs per empty result.
				res = @conn.exec( "SELECT * FROM copytable LIMIT 0" )
				tm = basic_type_mapping.build_column_map( res )

				@conn.exec_params( "INSERT INTO copytable VALUES ($1, $2, $3)", ['a', 123, [5,4,3]], 0, tm )
				@conn.exec_params( "INSERT INTO copytable VALUES ($1, $2, $3)", ['b', 234, [2,3]], 0, tm )
				res = @conn.exec( "SELECT * FROM copytable" )
				expect( res.values ).to eq( [['a', '123', '{5,4,3}'], ['b', '234', '{2,3}']] )
			end

			it "can do JSON conversions", :postgresql_94 do
				['JSON', 'JSONB'].each do |type|
					sql = "SELECT CAST('123' AS #{type}),
						CAST('12.3' AS #{type}),
						CAST('true' AS #{type}),
						CAST('false' AS #{type}),
						CAST('null' AS #{type}),
						CAST('[1, \"a\", null]' AS #{type}),
						CAST('{\"b\" : [2,3]}' AS #{type})"

					tm = basic_type_mapping.build_column_map( @conn.exec( sql ) )
					expect( tm.coders.map(&:name) ).to eq( [type.downcase] * 7 )

					res = @conn.exec_params( "SELECT $1, $2, $3, $4, $5, $6, $7",
						[ 123,
							12.3,
							true,
							false,
							nil,
							[1, "a", nil],
							{"b" => [2, 3]},
						], 0, tm )

					expect( res.getvalue(0,0) ).to eq( "123" )
					expect( res.getvalue(0,1) ).to eq( "12.3" )
					expect( res.getvalue(0,2) ).to eq( "true" )
					expect( res.getvalue(0,3) ).to eq( "false" )
					expect( res.getvalue(0,4) ).to eq( nil )
					expect( res.getvalue(0,5).gsub(" ","") ).to eq( "[1,\"a\",null]" )
					expect( res.getvalue(0,6).gsub(" ","") ).to eq( "{\"b\":[2,3]}" )
				end
			end
		end

		context "with usage of result oids for copy encoder selection" do
			it "can type cast #copy_data input with explicit encoder" do
				@conn.exec( "CREATE TEMP TABLE copytable (t TEXT, i INT, ai INT[])" )

				# Retrieve table OIDs per empty result set.
				res = @conn.exec( "SELECT * FROM copytable LIMIT 0" )
				tm = basic_type_mapping.build_column_map( res )
				row_encoder = PG::TextEncoder::CopyRow.new type_map: tm

				@conn.copy_data( "COPY copytable FROM STDIN", row_encoder ) do |res|
					@conn.put_copy_data ['a', 123, [5,4,3]]
					@conn.put_copy_data ['b', 234, [2,3]]
				end
				res = @conn.exec( "SELECT * FROM copytable" )
				expect( res.values ).to eq( [['a', '123', '{5,4,3}'], ['b', '234', '{2,3}']] )
			end
		end
	end
end
