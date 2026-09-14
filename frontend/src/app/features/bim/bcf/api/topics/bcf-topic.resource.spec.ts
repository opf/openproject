//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { TypedJSON } from 'typedjson';
import { BcfTopicResource } from 'core-app/features/bim/bcf/api/topics/bcf-topic.resource';
import moment from 'moment';

export const topic_object = {
  guid: '00efc0da-b4d5-4933-bcb6-e01513ee2bcc',
  topic_type: 'Clash',
  topic_status: 'New',
  priority: 'Normal',
  reference_links: ['/api/v3/work_packages/52'],
  title: 'Clash between wall and facade',
  index: null,
  labels: [],
  creation_date: '2020-02-25T15:09:15.000Z',
  creation_author: 'admin@example.net',
  modified_date: '2020-02-25T15:09:15.000Z',
  modified_author: null,
  assigned_to: '',
  stage: null,
  description: 'Clash between wall and facade',
  due_date: '2020-05-16',
  authorization: {
    topic_actions: ['update', 'updateRelatedTopics', 'updateFiles', 'createViewpoint'],
    topic_status: ['New', 'In progress', 'Resolved', 'Closed'],
  },
};

describe('BcfTopicResource', () => {
  it('can parse from the API returned JSON', () => {
    const serializer = new TypedJSON(BcfTopicResource);
    const subject = serializer.parse(topic_object)!;

    expect(subject).toBeInstanceOf(BcfTopicResource);
    ['guid', 'topic_type', 'topic_status', 'priority', 'reference_links', 'title',
      'index', 'labels', 'creation_author', 'modified_author', 'assigned_to', 'stage',
      'description'].forEach((item) =>

      expect((subject as any)[item]).toEqual((topic_object as any)[item]));

    // Expect dates
    expect(subject.creation_date).toEqual(moment(topic_object.creation_date));
    expect(subject.modified_date).toEqual(moment(topic_object.modified_date));
    expect(subject.due_date.format('YYYY-MM-DD')).toEqual(topic_object.due_date);

    expect(serializer.toPlainJson(subject)).toEqual(topic_object);
  });
});
