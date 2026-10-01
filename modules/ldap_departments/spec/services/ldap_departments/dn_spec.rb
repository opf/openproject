# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe LdapDepartments::Dn do
  describe ".normalize" do
    it "lower-cases attributes and values" do
      expect(described_class.normalize("OU=Frontend,DC=Example,DC=com"))
        .to eq("ou=frontend,dc=example,dc=com")
    end

    it "ignores insignificant whitespace around RDNs" do
      expect(described_class.normalize("OU = Frontend , OU=IT , DC=x"))
        .to eq("ou=frontend,ou=it,dc=x")
    end

    it "is idempotent (its own output normalizes to itself)" do
      normalized = described_class.normalize("CN=Doe\\, John,OU=Sales,DC=x")

      expect(described_class.normalize(normalized)).to eq(normalized)
    end

    it "produces a key a child DN can match with end_with? for subtree scoping" do
      base = described_class.normalize("DC=Example,DC=com")
      child = described_class.normalize("ou=Frontend,ou=IT,dc=example,dc=com")

      expect(child).to end_with(base)
    end

    # The hand-rolled splitter only treated a raw "," as an RDN boundary, so these three encodings of
    # the same name (escaped comma, quoted value, hex escape) used to normalize differently.
    context "with a value containing a comma" do
      let(:backslash_escaped) { "CN=Doe\\, John,OU=Sales,DC=x" }
      let(:quoted) { 'CN="Doe, John",OU=Sales,DC=x' }
      let(:hex_escaped) { "CN=Doe\\2C John,OU=Sales,DC=x" }

      it "treats the escaped comma as part of the value, not an RDN boundary" do
        expect(described_class.normalize(backslash_escaped)).to eq("cn=doe\\, john,ou=sales,dc=x")
      end

      it "normalizes the backslash, quoted and hex encodings to the same value" do
        expect([backslash_escaped, quoted, hex_escaped].map { |dn| described_class.normalize(dn) }.uniq)
          .to contain_exactly("cn=doe\\, john,ou=sales,dc=x")
      end
    end

    it "returns an empty string for a blank DN" do
      expect(described_class.normalize("")).to eq("")
      expect(described_class.normalize(nil)).to eq("")
    end

    it "returns an empty string for a malformed DN rather than raising" do
      expect(described_class.normalize("=,,broken")).to eq("")
    end
  end

  describe ".parent" do
    it "returns the container DN in canonical form" do
      expect(described_class.parent("CN=John Doe,OU=Frontend,OU=IT,DC=x"))
        .to eq("ou=frontend,ou=it,dc=x")
    end

    it "returns nil for a single-component DN" do
      expect(described_class.parent("dc=x")).to be_nil
    end

    it "returns nil for a blank DN" do
      expect(described_class.parent("")).to be_nil
    end

    it "drops only the first RDN even when its value contains an escaped comma" do
      expect(described_class.parent('CN="Doe, John",OU=Sales,DC=x'))
        .to eq("ou=sales,dc=x")
    end

    it "treats a multi-valued RDN as a single component" do
      expect(described_class.parent("CN=John+UID=jdoe,OU=Frontend,DC=x"))
        .to eq("ou=frontend,dc=x")
    end
  end

  describe ".depth" do
    it "counts the number of RDNs" do
      expect(described_class.depth("ou=Frontend,ou=IT,dc=example,dc=com")).to eq(4)
    end

    it "counts a multi-valued RDN as one" do
      expect(described_class.depth("CN=John+UID=jdoe,OU=Frontend,DC=x")).to eq(3)
    end

    it "is not fooled by an escaped comma inside a value" do
      expect(described_class.depth("CN=Doe\\, John,OU=Sales,DC=x")).to eq(3)
    end

    it "returns 0 for a blank DN" do
      expect(described_class.depth("")).to eq(0)
    end
  end
end
