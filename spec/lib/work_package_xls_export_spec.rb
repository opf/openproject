require 'spec_helper'
require 'spreadsheet'

describe "WorkPackageXlsExport" do
  let(:project) { FactoryBot.create :project }

  let(:parent) { FactoryBot.create :work_package, project: project, subject: 'Parent' }
  let(:child_1) do
    FactoryBot.create :work_package, parent: parent, project: project, subject: 'Child 1'
  end
  let(:child_2) do
    FactoryBot.create :work_package, parent: parent, project: project, subject: 'Child 2'
  end

  let(:single) { FactoryBot.create :work_package, project: project, subject: 'Single' }
  let(:followed) { FactoryBot.create :work_package, project: project, subject: 'Followed' }

  let(:child_2_child) do
    FactoryBot.create :work_package, parent: child_2, project: project, subject: "Child 2's child"
  end

  let(:relation) do
    child_2.new_relation.tap do |r|
      r.to = followed
      r.relation_type = 'follows'
      r.delay = 0
      r.description = 'description foobar'
      r.save
    end
  end

  let(:work_packages) do
    work_packages = [parent, child_1, child_2, single, followed]
    child_2_child

    work_packages
  end

  let(:current_user) { FactoryBot.create :admin } # may export relations

  let(:query) do
    query = FactoryBot.build(:query, user: current_user, project: project)

    query.filters.clear
    query.sort_criteria = [['id', 'asc']]
    query
  end

  let(:sheet) do
    login_as(current_user)
    work_packages
    relation
    work_packages.each(&:reload) # to init .leaves and relations
    load_sheet export
  end

  let(:export) do
    OpenProject::XlsExport::WorkPackageXlsExport.new(
      query,
      show_relations: true
    )
  end

  def load_sheet(export)
    f = Tempfile.new 'result.xls'
    begin
      f.binmode
      f.write export.list.content
    ensure
      f.close
    end

    sheet = Spreadsheet.open(f.path).worksheets.first
    f.unlink

    sheet
  end

  # expected row and column indices

  PARENT = 2
  CHILD_1 = 4
  CHILD_2 = 5
  SINGLE = 8
  FOLLOWED = 9
  RELATION = 7
  RELATION_DESCRIPTION = 9
  RELATED_SUBJECT = 12

  it 'produces the correct result' do
    expect(query.columns.map(&:name)).to eq [:id, :subject, :type, :status, :assigned_to]

    # the first header row devides the sheet into work packages and relation columns
    expect(sheet.rows.first.take(7)).to eq ['Work packages', nil, nil, nil, nil, nil, 'Relations']

    # the second header row includes the column names for work packages and relations
    expect(sheet.rows[1])
      .to eq [
        nil, 'ID', 'Subject', 'Type', 'Status', 'Assignee',
        nil, 'Relation type', 'Delay', 'Description', 'ID', 'Type', 'Subject',
        nil
      ]

    # duplicates rows for each relation
    c2id = child_2.id
    expect(sheet.column(1).drop(2))
      .to eq [parent.id, parent.id, child_1.id, c2id, c2id, c2id, single.id, followed.id, child_2_child.id]

    # marks Parent as parent of Child 1 and 2
    expect(sheet.row(PARENT)[RELATION]).to eq 'parent of'
    expect(sheet.row(PARENT)[RELATED_SUBJECT]).to eq 'Child 1'

    expect(sheet.row(PARENT + 1)[RELATION]).to eq 'parent of'
    expect(sheet.row(PARENT + 1)[RELATED_SUBJECT]).to eq 'Child 2'

    # shows Child 1 as child of Parent
    expect(sheet.row(CHILD_1)[RELATION]).to eq 'child of'
    expect(sheet.row(CHILD_1)[RELATED_SUBJECT]).to eq 'Parent'

    # shows Child 2 as child of Parent
    expect(sheet.row(CHILD_2)[RELATION]).to eq 'child of'
    expect(sheet.row(CHILD_2)[RELATED_SUBJECT]).to eq 'Parent'

    # shows Child 2 as parent of Child 2's child
    expect(sheet.row(CHILD_2 + 1)[RELATION]).to eq 'parent of'
    expect(sheet.row(CHILD_2 + 1)[RELATED_SUBJECT]).to eq "Child 2's child"

    # shows Child 2 as following Followed
    expect(sheet.row(CHILD_2 + 2)[RELATION]).to eq 'follows'
    expect(sheet.row(CHILD_2 + 2)[RELATED_SUBJECT]).to eq 'Followed'

    # shows no relation information for Single
    expect(sheet.row(SINGLE).drop(6).compact).to eq []

    # shows Followed as preceding Child 2'
    expect(sheet.row(FOLLOWED)[RELATION]).to eq 'precedes'
    expect(sheet.row(FOLLOWED)[RELATION_DESCRIPTION]).to eq 'description foobar'
    expect(sheet.row(FOLLOWED)[RELATED_SUBJECT]).to eq 'Child 2'

    # exports the correct data (examples)
    expect(sheet.row(PARENT))
      .to eq [
        nil, parent.id, parent.subject, parent.type.name, parent.status.name, parent.assigned_to,
        nil, 'parent of', nil, nil, child_1.id, child_1.type.name, child_1.subject
      ] # delay nil as this is a parent-child relation not represented by an actual Relation record

    expect(sheet.row(SINGLE))
      .to eq [
        nil, single.id, single.subject, single.type.name, single.status.name, single.assigned_to
      ]

    expect(sheet.row(FOLLOWED))
      .to eq [
        nil, followed.id, followed.subject, followed.type.name, followed.status.name,
          followed.assigned_to,
        nil, 'precedes', 0, relation.description, child_2.id, child_2.type.name, child_2.subject
      ]
  end

  context 'with someone who may not see related work packages' do
    let(:current_user) { FactoryBot.create :user }

    it 'exports no information without visibility' do
      expect(sheet.rows.length).to eq(2)
      expect(sheet.column(1).drop(2)).to be_empty
    end
  end
end
