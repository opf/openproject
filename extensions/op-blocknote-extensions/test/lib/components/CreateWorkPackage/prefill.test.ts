import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { prefillFor, projectPrefill, selectionToRemember } from '../../../../lib/components/CreateWorkPackage/prefill';
import {
  forgetLastSelection,
  lastSelection,
  rememberSelection,
} from '../../../../lib/components/CreateWorkPackage/lastSelection';
import type { FormField } from '../../../../lib/components/CreateWorkPackage/formSchema';
import { initOpenProjectApi } from '../../../../lib/services/openProjectApi';
import { initEditorContext } from '../../../../lib/services/editorContext';

const typeField:FormField = {
  key: 'type',
  label: 'Type',
  kind: 'select',
  required: true,
  isLink: true,
  allowedValues: [
    { href: '/api/v3/types/1', label: 'Task' },
    { href: '/api/v3/types/2', label: 'Bug' },
  ],
};

const assigneeField:FormField = {
  key: 'assignee',
  label: 'Assignee',
  kind: 'typeahead',
  required: false,
  isLink: true,
  allowedValuesHref: '/api/v3/projects/1/available_assignees',
};

const projectField:FormField = {
  key: 'project',
  label: 'Project',
  kind: 'typeahead',
  required: true,
  isLink: true,
  allowedValuesHref: '/api/v3/work_packages/available_projects',
};

const fields = [typeField, assigneeField];

const elifSelection = { href: '/api/v3/users/5', label: 'Elif Yildiz' };

function assigneesResponse(...people:{ id:number; name:string }[]):Response {
  return {
    ok: true,
    json: async () => ({
      _embedded: {
        elements: people.map(({ id, name }) => ({ id, name, _links: { self: { href: `/api/v3/users/${id}` } } })),
      },
    }),
  } as Partial<Response> as Response;
}

function projectsResponse(...projects:{ id:number; name:string }[]):Response {
  return {
    ok: true,
    json: async () => ({
      _embedded: {
        elements: projects.map(({ id, name }) => ({ id, name, _links: { self: { href: `/api/v3/projects/${id}` } } })),
      },
    }),
  } as Partial<Response> as Response;
}

describe('create work package prefill', () => {
  beforeEach(() => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    initEditorContext({});
    forgetLastSelection();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('prefillFor', () => {
    it('takes the type the API defaults to when nothing was created yet', async () => {
      const prefill = await prefillFor(fields, { _links: { type: { href: '/api/v3/types/2' } } });

      expect(prefill.values).toEqual({ type: '/api/v3/types/2' });
      expect(prefill.labels).toEqual({ type: 'Bug' });
    });

    it('takes the first type on offer when the API defaults to none', async () => {
      const prefill = await prefillFor(fields, {});

      expect(prefill.values.type).toBe('/api/v3/types/1');
    });

    it('prefers the type of the last creation over the default', async () => {
      rememberSelection({ type: { href: '/api/v3/types/2', label: 'Bug' } });

      const prefill = await prefillFor(fields, { _links: { type: { href: '/api/v3/types/1' } } });

      expect(prefill.values.type).toBe('/api/v3/types/2');
    });

    it('falls back to the default for a type the project does not offer', async () => {
      rememberSelection({ type: { href: '/api/v3/types/9', label: 'Milestone' } });

      const prefill = await prefillFor(fields, { _links: { type: { href: '/api/v3/types/2' } } });

      expect(prefill.values.type).toBe('/api/v3/types/2');
    });

    it('asks for no value the last creation left behind', async () => {
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(assigneesResponse());

      const prefill = await prefillFor(fields, {});

      expect(prefill.values.assignee).toBeUndefined();
      expect(fetchSpy).not.toHaveBeenCalled();
    });

    it('prefills a remembered assignee the project still offers, by their current name', async () => {
      rememberSelection({ assignee: { ...elifSelection, label: 'Elif Y.' } });
      const fetchSpy = vi.spyOn(global, 'fetch')
        .mockResolvedValue(assigneesResponse({ id: 5, name: 'Elif Yildiz' }));

      const prefill = await prefillFor(fields, {});

      expect(prefill.values.assignee).toBe('/api/v3/users/5');
      expect(prefill.labels.assignee).toBe('Elif Yildiz');
      expect(fetchSpy.mock.calls[0][0]).toContain('available_assignees');
    });

    it('leaves the assignee empty when the project cannot assign them', async () => {
      rememberSelection({ assignee: elifSelection });
      vi.spyOn(global, 'fetch').mockResolvedValue(assigneesResponse({ id: 6, name: 'Bianca Fuchs' }));

      const prefill = await prefillFor(fields, {});

      expect(prefill.values.assignee).toBeUndefined();
    });

    it('leaves the assignee empty when the check cannot be made', async () => {
      rememberSelection({ assignee: elifSelection });
      vi.spyOn(global, 'fetch').mockRejectedValue(new Error('Boom.'));
      vi.spyOn(console, 'error').mockImplementation(() => {});

      const prefill = await prefillFor(fields, {});

      expect(prefill.values.assignee).toBeUndefined();
    });

    it('prefills nothing the form does not ask for', async () => {
      rememberSelection({ type: { href: '/api/v3/types/2', label: 'Bug' }, assignee: elifSelection });

      const prefill = await prefillFor([], {});

      expect(prefill.values).toEqual({});
    });
  });

  describe('projectPrefill', () => {
    it('opens on the project the editor is rendered in, by its current name', async () => {
      initEditorContext({ projectId: 2 });
      const fetchSpy = vi.spyOn(global, 'fetch')
        .mockResolvedValue(projectsResponse({ id: 2, name: 'Scrum project' }));

      const prefill = await projectPrefill(projectField);

      expect(prefill.values).toEqual({ project: '/api/v3/projects/2' });
      expect(prefill.labels).toEqual({ project: 'Scrum project' });
      expect(String(fetchSpy.mock.calls[0][0])).toContain('%22id%22');
    });

    it('is outranked by the project of the last creation', async () => {
      initEditorContext({ projectId: 2 });
      rememberSelection({ project: { href: '/api/v3/projects/1', label: 'Demo project' } });
      vi.spyOn(global, 'fetch').mockResolvedValue(projectsResponse({ id: 1, name: 'Demo project' }));

      const prefill = await projectPrefill(projectField);

      expect(prefill.values.project).toBe('/api/v3/projects/1');
    });

    it('stands in with the project it is rendered in when the remembered one is gone', async () => {
      initEditorContext({ projectId: 2 });
      rememberSelection({ project: { href: '/api/v3/projects/1', label: 'Demo project' } });
      vi.spyOn(global, 'fetch')
        .mockResolvedValueOnce(projectsResponse())
        .mockResolvedValueOnce(projectsResponse({ id: 2, name: 'Scrum project' }));

      const prefill = await projectPrefill(projectField);

      expect(prefill.values.project).toBe('/api/v3/projects/2');
    });

    it('leaves the project empty where work packages cannot be created in it', async () => {
      initEditorContext({ projectId: 9 });
      vi.spyOn(global, 'fetch').mockResolvedValue(projectsResponse());

      const prefill = await projectPrefill(projectField);

      expect(prefill.values.project).toBeUndefined();
    });

    it('leaves the project empty when the look-up fails', async () => {
      initEditorContext({ projectId: 2 });
      vi.spyOn(global, 'fetch').mockRejectedValue(new Error('Boom.'));
      vi.spyOn(console, 'error').mockImplementation(() => {});

      const prefill = await projectPrefill(projectField);

      expect(prefill.values.project).toBeUndefined();
    });

    it('takes the project of the last creation where the application says none', async () => {
      rememberSelection({ project: { href: '/api/v3/projects/1', label: 'Demo p.' } });
      vi.spyOn(global, 'fetch').mockResolvedValue(projectsResponse({ id: 1, name: 'Demo project' }));

      const prefill = await projectPrefill(projectField);

      expect(prefill.values).toEqual({ project: '/api/v3/projects/1' });
      expect(prefill.labels).toEqual({ project: 'Demo project' });
    });

    it('leaves a remembered project that is no longer on offer empty', async () => {
      rememberSelection({ project: { href: '/api/v3/projects/1', label: 'Demo project' } });
      vi.spyOn(global, 'fetch').mockResolvedValue(projectsResponse());

      const prefill = await projectPrefill(projectField);

      expect(prefill.values.project).toBeUndefined();
    });

    it('leaves the project empty where the answer is not the project it asked for', async () => {
      initEditorContext({ projectId: 2 });
      vi.spyOn(global, 'fetch').mockResolvedValue(projectsResponse({ id: 1, name: 'Demo project' }));

      const prefill = await projectPrefill(projectField);

      expect(prefill.values.project).toBeUndefined();
    });

    it('leaves the project empty where nothing was created yet', async () => {
      const prefill = await projectPrefill(projectField);

      expect(prefill.values).toEqual({});
    });

    it('picks the project it is rendered in from a list the schema brings along', async () => {
      initEditorContext({ projectId: 2 });
      const fetchSpy = vi.spyOn(global, 'fetch');
      const listed:FormField = {
        ...projectField,
        kind: 'select',
        allowedValues: [
          { href: '/api/v3/projects/1', label: 'Demo project' },
          { href: '/api/v3/projects/2', label: 'Scrum project' },
        ],
      };

      const prefill = await projectPrefill(listed);

      expect(prefill.values.project).toBe('/api/v3/projects/2');
      expect(fetchSpy).not.toHaveBeenCalled();
    });

    it('prefills nothing where the form does not ask for a project', async () => {
      initEditorContext({ projectId: 2 });

      const prefill = await projectPrefill(undefined);

      expect(prefill.values).toEqual({});
    });
  });

  describe('selectionToRemember', () => {
    it('remembers a selection by what it reads as', () => {
      const selection = selectionToRemember(
        [projectField, ...fields],
        {
          subject: 'Fix the header',
          project: '/api/v3/projects/1',
          type: '/api/v3/types/2',
          assignee: '/api/v3/users/5',
        },
        { project: 'Demo project', assignee: 'Elif Yildiz' }
      );

      expect(selection).toEqual({
        project: { href: '/api/v3/projects/1', label: 'Demo project' },
        type: { href: '/api/v3/types/2', label: 'Bug' },
        assignee: elifSelection,
      });
    });

    it('remembers nothing of a value it cannot name', () => {
      const selection = selectionToRemember(fields, { assignee: '/api/v3/users/5' }, {});

      expect(selection.assignee).toBeUndefined();
    });

    it('remembers nothing of an attribute the creation left empty', () => {
      const selection = selectionToRemember(fields, { type: '/api/v3/types/1', assignee: '' }, {});

      expect(selection).toEqual({ type: { href: '/api/v3/types/1', label: 'Task' } });
    });

    it('replaces what an earlier creation left behind', () => {
      rememberSelection({ type: { href: '/api/v3/types/2', label: 'Bug' }, assignee: elifSelection });

      rememberSelection(selectionToRemember(fields, { type: '/api/v3/types/1' }, {}));

      expect(lastSelection()).toEqual({ type: { href: '/api/v3/types/1', label: 'Task' } });
    });
  });
});
