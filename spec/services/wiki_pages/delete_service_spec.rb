# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#++

require "spec_helper"

RSpec.describe WikiPages::DeleteService, type: :model do
  let(:project) { create(:project) }
  let(:user) { create(:user, member_with_permissions: { project => %i[edit_wiki_pages manage_wiki] }) }
  let(:wiki) { create(:wiki, project:) }
  let(:wiki_page) { create(:wiki_page, wiki:) }

  subject(:call) do
    described_class
      .new(user:, model: wiki_page)
      .call(todo:, reassign_to_id:)
  end

  let(:todo) { "nullify" }
  let(:reassign_to_id) { nil }

  context "when nullifying descendants" do
    let!(:child) { create(:wiki_page, wiki:, parent: wiki_page) }

    it "removes the page and retains its child as a root page" do
      expect(call).to be_success
      expect(WikiPage).not_to exist(wiki_page.id)
      expect(child.reload.parent).to be_nil
    end
  end

  context "when destroying descendants" do
    let(:todo) { "destroy" }
    let!(:child) { create(:wiki_page, wiki:, parent: wiki_page) }

    it "removes the page and all descendants" do
      expect(call).to be_success
      expect(WikiPage.where(id: [wiki_page.id, child.id])).to be_empty
    end
  end

  context "when reassigning children" do
    let(:todo) { "reassign" }
    let!(:child) { create(:wiki_page, wiki:, parent: wiki_page) }
    let!(:new_parent) { create(:wiki_page, wiki:) }
    let(:reassign_to_id) { new_parent.id }

    it "moves direct children to the requested parent" do
      expect(call).to be_success
      expect(child.reload.parent).to eq(new_parent)
    end
  end
end
