#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe OpenProject::Storage do
  before do
    allow(Setting).to receive(:enabled_scm).and_return(enabled_scms)
    allow(OpenProject::Configuration).to receive(:[]).and_call_original
    allow(OpenProject::Configuration).to receive(:[]).with("scm").and_return(config)
  end

  context "with no SCM configuration" do
    let(:config) { {} }
    let(:enabled_scms) { [] }

    describe "#known_storage_paths" do
      subject { OpenProject::Storage.known_storage_paths }

      it "contains attachments path" do
        expect(subject.length).to eq 1
        expect(subject[:attachments])
          .to eq(label: I18n.t("attributes.attachments"),
                 path: OpenProject::Configuration.attachments_storage_path.to_s)
      end
    end

    describe "#mount_information" do
      subject { OpenProject::Storage.mount_information }

      include_context "with tmpdir"

      before do
        allow(OpenProject::Storage).to receive(:known_storage_paths)
          .and_return(foobar: { path: tmpdir, label: "this is foobar" })
      end

      it "contains one fs entry" do
        expect(File.exist?(tmpdir)).to be true
        expect(subject.length).to eq 1

        entry = subject.values.first
        expect(entry[:labels]).to eq(["this is foobar"])
        expect(entry[:data]).not_to be_nil
        expect(entry[:data][:free]).to be_a(Integer)
      end
    end
  end

  context "with SCM configuration" do
    include_context "with tmpdir"

    let(:config) do
      {
        git: { manages: File.join(tmpdir, "git") }
      }
    end
    let(:enabled_scms) { %w[git] }
    let(:returned_fs_info) { [{ id: 1, free: 1234 }] }

    before do
      # Mock filesystem info as we do not know there /tmp is mounted here.
      allow(OpenProject::Storage).to receive(:read_fs_info).and_return(*returned_fs_info)
    end

    describe "#known_storage_paths" do
      subject { OpenProject::Storage.known_storage_paths }

      it "contains both paths" do
        expect(subject.length).to eq 2

        labels = subject.values.pluck(:label)
        expect(labels)
          .to contain_exactly(I18n.t(:label_managed_repositories_vendor, vendor: "Git"), I18n.t("attributes.attachments"))
      end
    end

    describe "#mount_information" do
      subject { OpenProject::Storage.mount_information }

      it "contains one entry" do
        expect(subject.length).to eq(1)

        entry = subject.values.first
        expect(entry[:labels])
          .to contain_exactly(I18n.t(:label_managed_repositories_vendor, vendor: "Git"), I18n.t("attributes.attachments"))
      end

      context "with multiple filesystem ids" do
        let(:returned_fs_info) { [{ id: 1, free: 1234 }, { id: 2, free: 15 }] }

        it "contains two entries" do
          expect(subject.length).to eq(2)
          expect(subject)
            .to eq(1 => { labels: [I18n.t(:label_managed_repositories_vendor, vendor: "Git")],
                          data: returned_fs_info[0] },
                   2 => { labels: [I18n.t("attributes.attachments")],
                          data: returned_fs_info[1] })
        end
      end
    end
  end
end
