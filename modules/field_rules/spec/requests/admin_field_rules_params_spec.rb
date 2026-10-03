# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admin field rule parameter handling" do # rubocop:disable RSpec/DescribeClass
  shared_let(:admin) { create(:admin) }
  shared_let(:user) { create(:user) }
  shared_let(:rule_set) { create(:field_rule_set, name: "Params rules") }
  shared_let(:scheme) { create(:field_rule_scheme, name: "Params scheme") }

  it "forbids non administrators on every admin route" do
    login_as(user)
    [[:get, "/admin/field_rule_sets"], [:get, "/admin/field_rule_schemes"],
     [:post, "/admin/field_rule_sets/#{rule_set.id}/deactivate"],
     [:patch, "/admin/field_rule_schemes/#{scheme.id}"]].each do |verb, path|
      send(verb, path)
      expect(response).to have_http_status(:forbidden), "#{verb} #{path}"
    end
    expect(rule_set.reload).to be_active
  end

  context "as administrator" do
    before { login_as(admin) }

    it "answers 400 instead of 500 for scalar top level params" do
      patch "/admin/field_rule_sets/#{rule_set.id}", params: { rule_set: "x" }
      expect(response).to have_http_status(:bad_request)

      patch "/admin/field_rule_schemes/#{scheme.id}", params: { scheme: "x" }
      expect(response).to have_http_status(:bad_request)
    end

    it "ignores unexpected nested values" do
      patch "/admin/field_rule_sets/#{rule_set.id}",
            params: { rule_set: { name: "Params rules", rules: { priority: { hidden: "1", default_value: { a: "b" } },
                                                                 description: "scalar", category: ["x"] } } }
      expect(response).to have_http_status(:see_other)
      expect(rule_set.reload.rules.map(&:field_key)).to eq %w[priority]
      expect(rule_set.rule_for("priority").default_value).to be_nil
    end

    it "ignores non numeric and oversized scheme ids" do
      patch "/admin/field_rule_schemes/#{scheme.id}",
            params: { scheme: { name: "Params scheme", types: { "1" => { a: 1 }, "99999999999999999999" => "1", "x" => "1" } } }
      expect(response).to have_http_status(:see_other)
      expect(scheme.reload.items).to be_empty
    end
  end
end
