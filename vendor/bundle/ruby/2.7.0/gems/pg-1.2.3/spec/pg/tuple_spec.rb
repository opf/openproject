# -*- rspec -*-
# encoding: utf-8

require_relative '../helpers'
require 'pg'
require 'objspace'

describe PG::Tuple do
	let!(:typemap) { PG::BasicTypeMapForResults.new(@conn) }
	let!(:result2x2) { @conn.exec( "VALUES(1, 'a'), (2, 'b')" ) }
	let!(:result2x2sym) { @conn.exec( "VALUES(1, 'a'), (2, 'b')" ).field_names_as(:symbol) }
	let!(:result2x3cast) do
		@conn.exec( "SELECT * FROM (VALUES(1, TRUE, '3'), (2, FALSE, '4')) AS m (a, b, b)" )
			.map_types!(typemap)
	end
	let!(:result2x3symcast) do
		@conn.exec( "SELECT * FROM (VALUES(1, TRUE, '3'), (2, FALSE, '4')) AS m (a, b, b)" )
			.map_types!(typemap)
			.field_names_as(:symbol)
	end
	let!(:tuple0) { result2x2.tuple(0) }
	let!(:tuple0sym) { result2x2sym.tuple(0) }
	let!(:tuple1) { result2x2.tuple(1) }
	let!(:tuple1sym) { result2x2sym.tuple(1) }
	let!(:tuple2) { result2x3cast.tuple(0) }
	let!(:tuple2sym) { result2x3symcast.tuple(0) }
	let!(:tuple3) { str = Marshal.dump(result2x3cast.tuple(1)); Marshal.load(str) }
	let!(:tuple_empty) { PG::Tuple.new }

	describe "[]" do
		it "returns nil for invalid keys" do
			expect( tuple0["x"] ).to be_nil
			expect( tuple0[0.5] ).to be_nil
			expect( tuple0[2] ).to be_nil
			expect( tuple0[-3] ).to be_nil
			expect( tuple2[-4] ).to be_nil
			expect{ tuple_empty[0] }.to raise_error(TypeError)
		end

		it "supports array like access" do
			expect( tuple0[0] ).to eq( "1" )
			expect( tuple0[1] ).to eq( "a" )
			expect( tuple1[0] ).to eq( "2" )
			expect( tuple1[1] ).to eq( "b" )
			expect( tuple2[0] ).to eq( 1 )
			expect( tuple2[1] ).to eq( true )
			expect( tuple2[2] ).to eq( "3" )
			expect( tuple3[0] ).to eq( 2 )
			expect( tuple3[1] ).to eq( false )
			expect( tuple3[2] ).to eq( "4" )
		end

		it "supports negative indices" do
			expect( tuple0[-2] ).to eq( "1" )
			expect( tuple0[-1] ).to eq( "a" )
			expect( tuple2[-3] ).to eq( 1 )
			expect( tuple2[-2] ).to eq( true )
			expect( tuple2[-1] ).to eq( "3" )
		end

		it "supports hash like access" do
			expect( tuple0["column1"] ).to eq( "1" )
			expect( tuple0["column2"] ).to eq( "a" )
			expect( tuple2["a"] ).to eq( 1 )
			expect( tuple2["b"] ).to eq( "3" )
			expect( tuple0[:b] ).to be_nil
			expect( tuple0["x"] ).to be_nil
		end

		it "supports hash like access with symbols" do
			expect( tuple0sym[:column1] ).to eq( "1" )
			expect( tuple0sym[:column2] ).to eq( "a" )
			expect( tuple2sym[:a] ).to eq( 1 )
			expect( tuple2sym[:b] ).to eq( "3" )
			expect( tuple2sym["b"] ).to be_nil
			expect( tuple0sym[:x] ).to be_nil
		end

		it "casts lazy and caches result" do
			a = []
			deco = Class.new(PG::SimpleDecoder) do
				define_method(:decode) do |*args|
					a << args
					args.last
				end
			end.new

			result2x2.map_types!(PG::TypeMapByColumn.new([deco, deco]))
			t = result2x2.tuple(1)

			# cast and cache at first call to [0]
			a.clear
			expect( t[0] ).to eq( 0 )
			expect( a ).to eq([["2", 1, 0]])

			# use cache at second call to [0]
			a.clear
			expect( t[0] ).to eq( 0 )
			expect( a ).to eq([])

			# cast and cache at first call to [1]
			a.clear
			expect( t[1] ).to eq( 1 )
			expect( a ).to eq([["b", 1, 1]])
		end
	end

	describe "fetch" do
		it "raises proper errors for invalid keys" do
			expect{ tuple0.fetch("x") }.to raise_error(KeyError)
			expect{ tuple0.fetch(0.5) }.to raise_error(KeyError)
			expect{ tuple0.fetch(2) }.to raise_error(IndexError)
			expect{ tuple0.fetch(-3) }.to raise_error(IndexError)
			expect{ tuple0.fetch(-3) }.to raise_error(IndexError)
			expect{ tuple2.fetch(-4) }.to raise_error(IndexError)
			expect{ tuple_empty[0] }.to raise_error(TypeError)
		end

		it "supports array like access" do
			expect( tuple0.fetch(0) ).to eq( "1" )
			expect( tuple0.fetch(1) ).to eq( "a" )
			expect( tuple2.fetch(0) ).to eq( 1 )
			expect( tuple2.fetch(1) ).to eq( true )
			expect( tuple2.fetch(2) ).to eq( "3" )
		end

		it "supports default value for indices" do
			expect( tuple0.fetch(2, 42) ).to eq( 42 )
			expect( tuple0.fetch(2){43} ).to eq( 43 )
		end

		it "supports negative indices" do
			expect( tuple0.fetch(-2) ).to eq( "1" )
			expect( tuple0.fetch(-1) ).to eq( "a" )
			expect( tuple2.fetch(-3) ).to eq( 1 )
			expect( tuple2.fetch(-2) ).to eq( true )
			expect( tuple2.fetch(-1) ).to eq( "3" )
		end

		it "supports hash like access" do
			expect( tuple0.fetch("column1") ).to eq( "1" )
			expect( tuple0.fetch("column2") ).to eq( "a" )
			expect( tuple2.fetch("a") ).to eq( 1 )
			expect( tuple2.fetch("b") ).to eq( "3" )
		end

		it "supports default value for name keys" do
			expect( tuple0.fetch("x", "defa") ).to eq("defa")
			expect( tuple0.fetch("x"){"defa"} ).to eq("defa")
		end
	end

	describe "each" do
		it "can be used as an enumerator" do
			expect( tuple0.each ).to be_kind_of(Enumerator)
			expect( tuple0.each.to_a ).to eq( [["column1", "1"], ["column2", "a"]] )
			expect( tuple1.each.to_a ).to eq( [["column1", "2"], ["column2", "b"]] )
			expect( tuple2.each.to_a ).to eq( [["a", 1], ["b", true], ["b", "3"]] )
			expect( tuple3.each.to_a ).to eq( [["a", 2], ["b", false], ["b", "4"]] )
			expect{ tuple_empty.each }.to raise_error(TypeError)
		end

		it "can be used as an enumerator with symbols" do
			expect( tuple0sym.each ).to be_kind_of(Enumerator)
			expect( tuple0sym.each.to_a ).to eq( [[:column1, "1"], [:column2, "a"]] )
			expect( tuple2sym.each.to_a ).to eq( [[:a, 1], [:b, true], [:b, "3"]] )
		end

		it "can be used with block" do
			a = []
			tuple0.each do |*v|
				a << v
			end
			expect( a ).to eq( [["column1", "1"], ["column2", "a"]] )
		end
	end

	describe "each_value" do
		it "can be used as an enumerator" do
			expect( tuple0.each_value ).to be_kind_of(Enumerator)
			expect( tuple0.each_value.to_a ).to eq( ["1", "a"] )
			expect( tuple1.each_value.to_a ).to eq( ["2", "b"] )
			expect( tuple2.each_value.to_a ).to eq( [1, true, "3"] )
			expect( tuple3.each_value.to_a ).to eq( [2, false, "4"] )
			expect{ tuple_empty.each_value }.to raise_error(TypeError)
		end

		it "can be used with block" do
			a = []
			tuple0.each_value do |v|
				a << v
			end
			expect( a ).to eq( ["1", "a"] )
		end
	end

	it "responds to values" do
		expect( tuple0.values ).to eq( ["1", "a"] )
		expect( tuple3.values ).to eq( [2, false, "4"] )
		expect{ tuple_empty.values }.to raise_error(TypeError)
	end

	it "responds to key?" do
		expect( tuple1.key?("column1") ).to eq( true )
		expect( tuple1.key?(:column1) ).to eq( false )
		expect( tuple1.key?("other") ).to eq( false )
		expect( tuple1.has_key?("column1") ).to eq( true )
		expect( tuple1.has_key?("other") ).to eq( false )
	end

	it "responds to key? as symbol" do
		expect( tuple1sym.key?(:column1) ).to eq( true )
		expect( tuple1sym.key?("column1") ).to eq( false )
		expect( tuple1sym.key?(:other) ).to eq( false )
		expect( tuple1sym.has_key?(:column1) ).to eq( true )
		expect( tuple1sym.has_key?(:other) ).to eq( false )
	end

	it "responds to keys" do
		expect( tuple0.keys ).to eq( ["column1", "column2"] )
		expect( tuple2.keys ).to eq( ["a", "b", "b"] )
	end

	it "responds to keys as symbol" do
		expect( tuple0sym.keys ).to eq( [:column1, :column2] )
		expect( tuple2sym.keys ).to eq( [:a, :b, :b] )
	end

	describe "each_key" do
		it "can be used as an enumerator" do
			expect( tuple0.each_key ).to be_kind_of(Enumerator)
			expect( tuple0.each_key.to_a ).to eq( ["column1", "column2"] )
			expect( tuple2.each_key.to_a ).to eq( ["a", "b", "b"] )
		end

		it "can be used with block" do
			a = []
			tuple0.each_key do |v|
				a << v
			end
			expect( a ).to eq( ["column1", "column2"] )
		end
	end

	it "responds to length" do
		expect( tuple0.length ).to eq( 2 )
		expect( tuple0.size ).to eq( 2 )
		expect( tuple2.size ).to eq( 3 )
	end

	it "responds to index" do
		expect( tuple0.index("column1") ).to eq( 0 )
		expect( tuple0.index(:column1) ).to eq( nil )
		expect( tuple0.index("column2") ).to eq( 1 )
		expect( tuple0.index("x") ).to eq( nil )
		expect( tuple2.index("a") ).to eq( 0 )
		expect( tuple2.index("b") ).to eq( 2 )
	end

	it "responds to index with symbol" do
		expect( tuple0sym.index(:column1) ).to eq( 0 )
		expect( tuple0sym.index("column1") ).to eq( nil )
		expect( tuple0sym.index(:column2) ).to eq( 1 )
		expect( tuple0sym.index(:x) ).to eq( nil )
		expect( tuple2sym.index(:a) ).to eq( 0 )
		expect( tuple2sym.index(:b) ).to eq( 2 )
	end

	it "can be used as Enumerable" do
		expect( tuple0.to_a ).to eq( [["column1", "1"], ["column2", "a"]] )
		expect( tuple1.to_a ).to eq( [["column1", "2"], ["column2", "b"]] )
		expect( tuple2.to_a ).to eq( [["a", 1], ["b", true], ["b", "3"]] )
		expect( tuple3.to_a ).to eq( [["a", 2], ["b", false], ["b", "4"]] )
	end

	it "can be marshaled" do
		[tuple0, tuple1, tuple2, tuple3, tuple0sym, tuple2sym].each do |t1|
			str = Marshal.dump(t1)
			t2 = Marshal.load(str)

			expect( t2 ).to be_kind_of(t1.class)
			expect( t2 ).not_to equal(t1)
			expect( t2.to_a ).to eq(t1.to_a)
		end
	end

	it "passes instance variables when marshaled" do
		t1 = tuple0
		t1.instance_variable_set("@a", 4711)
		str = Marshal.dump(t1)
		t2 = Marshal.load(str)

		expect( t2.instance_variable_get("@a") ).to eq( 4711 )
	end

	it "can't be marshaled when empty" do
		expect{ Marshal.dump(tuple_empty) }.to raise_error(TypeError)
	end

	it "should give account about memory usage" do
		expect( ObjectSpace.memsize_of(tuple0) ).to be > 40
		expect( ObjectSpace.memsize_of(tuple_empty) ).to be > 0
	end

	it "should override #inspect" do
		expect( tuple1.inspect ).to eq('#<PG::Tuple column1: "2", column2: "b">')
		expect( tuple2.inspect ).to eq('#<PG::Tuple a: 1, b: true, b: "3">')
		expect( tuple2sym.inspect ).to eq('#<PG::Tuple a: 1, b: true, b: "3">')
		expect{ tuple_empty.inspect }.to raise_error(TypeError)
	end

	context "with cleared result" do
		it "should raise an error when non-materialized fields are used" do
			r = result2x2
			t = r.tuple(0)
			t[0] # materialize first field only
			r.clear

			# second column should fail
			expect{ t[1] }.to raise_error(PG::Error)
			expect{ t.fetch(1) }.to raise_error(PG::Error)
			expect{ t.fetch("column2") }.to raise_error(PG::Error)

			# first column should succeed
			expect( t[0] ).to eq( "1" )
			expect( t.fetch(0) ).to eq( "1" )
			expect( t.fetch("column1") ).to eq( "1" )

			# should fail due to the second column
			expect{ t.values }.to raise_error(PG::Error)
		end
	end
end
