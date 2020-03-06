//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
//++

import {async, TestBed} from "@angular/core/testing";
import {BcfApiService} from "core-app/modules/bim/bcf/api/bcf-api.service";
import {BcfResourceCollectionPath, BcfResourcePath} from "core-app/modules/bim/bcf/api/bcf-path-resources";
import {BcfTopicPaths} from "core-app/modules/bim/bcf/api/topics/bcf-topic.paths";

describe('BcfApiService', function () {
  let service:BcfApiService;

  beforeEach(async(() => {
    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      providers: [
        BcfApiService,
      ]
    })
      .compileComponents()
      .then(() => {
        service = TestBed.get(BcfApiService);
      });
  }));

  describe('building the path', () => {
    it('can build projects', () => {
      let subject = service.projects;
      expect(subject.toPath()).toEqual('/api/bcf/2.1/projects');
    });

    it('can build project', () => {
      let subject = service.projects.id('foo');
      expect(subject.toPath()).toEqual('/api/bcf/2.1/projects/foo');
    });

    it('can build topics', () => {
      let subject = service.projects.id('foo').topics;
      expect(subject.toPath()).toEqual('/api/bcf/2.1/projects/foo/topics');
    });

    it('can build topic', () => {
      let subject = service.projects.id('foo').topics.id('bar');
      expect(subject.toPath()).toEqual('/api/bcf/2.1/projects/foo/topics/bar');
    });

    it('can build viewpoints', () => {
      let subject = service.projects.id('foo').topics.id('bar').viewpoints;
      expect(subject.toPath()).toEqual('/api/bcf/2.1/projects/foo/topics/bar/viewpoints');
    });

    it('can build comments', () => {
      let subject = service.projects.id('foo').topics.id('bar').comments;
      expect(subject.toPath()).toEqual('/api/bcf/2.1/projects/foo/topics/bar/comments');
    });
  });

  describe('#parse', () => {
    it('can parse projects', () => {
      let href = '/api/bcf/2.1/projects';
      let subject:any = service.parse(href);
      expect(subject).toBeInstanceOf(BcfResourceCollectionPath);
      expect(subject.segment).toEqual('projects');
      expect(subject.toPath()).toEqual(href);
    });

    it('can parse single project', () => {
      let href = '/api/bcf/2.1/projects/foo';
      let subject:any = service.parse(href);
      expect(subject).toBeInstanceOf(BcfResourcePath);
      expect(subject.id).toEqual('foo');
      expect(subject.toPath()).toEqual(href);
    });

    it('can parse topics in projects', () => {
      let href = '/api/bcf/2.1/projects/foo/topics';
      let subject:any = service.parse(href);
      expect(subject).toBeInstanceOf(BcfResourceCollectionPath);
      expect(subject.segment).toEqual('topics');
      expect(subject.toPath()).toEqual(href);
    });

    it('can parse single topic in projects', () => {
      let href = '/api/bcf/2.1/projects/foo/topics/0efc0da-b4d5-4933-bcb6-e01513ee2bcc';
      let subject:any = service.parse(href);
      expect(subject).toBeInstanceOf(BcfTopicPaths);
      expect(subject.comments).toBeDefined();
      expect(subject.viewpoints).toBeDefined();
      expect(subject.id).toEqual('0efc0da-b4d5-4933-bcb6-e01513ee2bcc');
      expect(subject.toPath()).toEqual(href);
    });

    it('can parse viewpoints in topic', () => {
      let href = '/api/bcf/2.1/projects/foo/topics/0efc0da-b4d5-4933-bcb6-e01513ee2bcc/viewpoints';
      let subject:any = service.parse(href);
      expect(subject).toBeInstanceOf(BcfResourceCollectionPath);
      expect(subject.segment).toEqual('viewpoints');
      expect(subject.toPath()).toEqual(href);
    });

    it('can parse single viewpoint in topic', () => {
      let href = '/api/bcf/2.1/projects/demo-bcf-management-project/topics/00efc0da-b4d5-4933-bcb6-e01513ee2bcc/viewpoints/dfca6c25-832f-6a94-53ca-48d510b6bad9';
      let subject:any = service.parse(href);
      expect(subject).toBeInstanceOf(BcfResourcePath);
      expect(subject.id).toEqual('dfca6c25-832f-6a94-53ca-48d510b6bad9');
      expect(subject.toPath()).toEqual(href);
    });

  });
});
