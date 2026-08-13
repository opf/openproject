import { afterEach, describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { fillRequiredFields, openCreateModal, pickProject, selectOptionNamed } from '../../../helpers/createWorkPackageHelpers';
import { worker } from '../../../mocks/browser';

afterEach(() => worker.resetHandlers());

describe('Create work package - form and editor boundaries', () => {
  it('loads the form once and puts the cursor into the subject', async () => {
    let formRequests = 0;
    const count = ({ request }:{ request:Request }) => {
      if (request.method === 'POST' && request.url.endsWith('/api/v3/work_packages/form')) formRequests += 1;
    };
    worker.events.on('request:start', count);

    try {
      renderEditor();
      await openCreateModal();
      await expect.element(page.getByLabelText('Subject *')).toBeVisible();

      // A modal that mounts twice asks the API twice and loses its autofocus.
      await expect.element(page.getByLabelText('Subject *')).toHaveFocus();
      expect(formRequests).toBe(1);
    } finally {
      worker.events.removeListener('request:start', count);
    }
  });

  it('does not let what is typed into the form reach the document', async () => {
    renderEditor();
    await openCreateModal('Before ');

    await userEvent.fill(page.getByLabelText('Subject *'), 'typed into the modal');

    const editorText = document.querySelector('.bn-editor')?.textContent ?? '';
    expect(editorText).not.toContain('typed into the modal');
    expect(editorText).toContain('Before');
  });

  it('closes on Escape and leaves the document as it was', async () => {
    renderEditor();
    await openCreateModal();

    await userEvent.keyboard('{Escape}');

    await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
    await expect.element(page.getByTestId('block-wp-wrapper')).not.toBeInTheDocument();
  });

  it('lays the suggestions over the form instead of inside its scroll area', async () => {
    renderEditor();
    await openCreateModal();

    await userEvent.click(page.getByLabelText('Project *'));
    await expect.element(page.getByRole('option', { name: 'Demo project' })).toBeVisible();
    const list = page.getByRole('listbox', { name: 'Project' }).element();

    const input = page.getByLabelText('Project *').element();
    expect(getComputedStyle(list).position).toBe('fixed');
    expect(list.getBoundingClientRect().top).toBeGreaterThanOrEqual(input.getBoundingClientRect().bottom);
    expect(Math.round(list.getBoundingClientRect().width))
      .toBe(Math.round(input.getBoundingClientRect().width));
  });

  it('keeps a filled form when the overlay is clicked, and drops an untouched one', async () => {
    renderEditor();
    await openCreateModal();
    await userEvent.fill(page.getByLabelText('Subject *'), 'Worth keeping');

    await userEvent.click(page.getByTestId('create-wp-overlay'), { position: { x: 5, y: 5 } });
    await expect.element(page.getByTestId('create-wp-modal')).toBeVisible();
    await expect.element(page.getByLabelText('Subject *')).toHaveValue('Worth keeping');

    await userEvent.fill(page.getByLabelText('Subject *'), '');
    await userEvent.click(page.getByTestId('create-wp-overlay'), { position: { x: 5, y: 5 } });
    await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
  });

  it('submits on Enter in a text field', async () => {
    renderEditor();
    await openCreateModal();

    await fillRequiredFields('Fix the header alignment');

    await userEvent.fill(page.getByLabelText('Subject *'), 'Fix the header alignment');
    await userEvent.keyboard('{Enter}');

    await expect.element(page.getByTestId('block-card')).toBeVisible();
  });

  it('picks a suggestion with the keyboard, and typing over it unselects', async () => {
    renderEditor();
    await openCreateModal();

    await userEvent.click(page.getByLabelText('Project *'));
    await expect.element(page.getByRole('option', { name: 'Demo project' })).toBeVisible();
    await userEvent.keyboard('{ArrowDown}{ArrowDown}{Enter}');

    await expect.element(page.getByLabelText('Project *')).toHaveValue('Scrum project');
    await expect.element(page.getByLabelText('Type *')).toBeVisible();

    await userEvent.fill(page.getByLabelText('Project *'), 'Demo');

    await expect.element(page.getByLabelText('Type *')).not.toBeInTheDocument();
  });

  it('does not leave text behind that stands for no selection', async () => {
    renderEditor();
    await openCreateModal();

    await userEvent.fill(page.getByLabelText('Project *'), 'nothing matches this');
    await expect.element(page.getByText('No results')).toBeVisible();
    await userEvent.click(page.getByLabelText('Subject *'));

    await expect.element(page.getByLabelText('Project *')).toHaveValue('');
  });

  it('re-asks for the type when the project changes', async () => {
    renderEditor();
    await openCreateModal();

    await userEvent.click(page.getByLabelText('Project *'));
    await userEvent.click(page.getByRole('option', { name: 'Demo project' }));
    await expect.element(page.getByLabelText('Type *')).toBeVisible();
    await selectOptionNamed('Type *', 'Task');
    await expect.element(page.getByLabelText('Supervisor *')).toBeVisible();

    await userEvent.fill(page.getByLabelText('Project *'), 'Scrum');
    await userEvent.click(page.getByRole('option', { name: 'Scrum project' }));

    await expect.element(page.getByLabelText('Type *')).toHaveValue('');
    await expect.element(page.getByLabelText('Supervisor *')).not.toBeInTheDocument();
  });

  it('states that creating work packages is not permitted', async () => {
    worker.use(
      http.post('http://localhost:3000/api/v3/work_packages/form', () =>
        HttpResponse.json({ message: 'You are not authorized to access this resource.' }, { status: 403 })
      )
    );

    renderEditor();
    await openCreateModal();

    await expect.element(page.getByText('You are not allowed to create work packages.')).toBeVisible();
    await expect.element(page.getByTestId('create-wp-submit')).toBeDisabled();
    expect(getComputedStyle(page.getByTestId('create-wp-submit').element()).backgroundColor)
      .toBe('rgb(149, 216, 166)');
  });

  it('reports a form that cannot be loaded', async () => {
    worker.use(
      http.post('http://localhost:3000/api/v3/work_packages/form', () =>
        HttpResponse.json({ message: 'Boom.' }, { status: 500 })
      )
    );

    renderEditor();
    await openCreateModal();

    await expect.element(page.getByText('The work package form could not be loaded: Boom.')).toBeVisible();
  });

  it('points at a whole number field it cannot read, once something is in it', async () => {
    worker.use(
      http.post('http://localhost:3000/api/v3/work_packages/form', async ({ request }) => {
        const body = await request.json() as { _links?:Record<string, { href?:string }> };
        const schema:Record<string, unknown> = {
          _type: 'Schema',
          subject: { type: 'String', name: 'Subject', required: true, hasDefault: false, writable: true },
          project: {
            type: 'Project', name: 'Project', required: true, hasDefault: false, writable: true, location: '_links',
            _links: { allowedValues: { href: '/api/v3/work_packages/available_projects' } },
          },
        };
        if (body._links?.project?.href) {
          schema.type = {
            type: 'Type', name: 'Type', required: true, hasDefault: false, writable: true, location: '_links',
            _links: { allowedValues: [{ href: '/api/v3/types/1', title: 'Task' }] },
          };
        }
        if (body._links?.type?.href) {
          schema.customField9 = {
            type: 'Integer', name: 'Pages', required: true, hasDefault: false, writable: true,
          };
        }
        return HttpResponse.json({
          _type: 'Form',
          _embedded: { payload: { subject: null, _links: {} }, schema, validationErrors: {} },
        });
      })
    );

    renderEditor();
    await openCreateModal();
    await userEvent.fill(page.getByLabelText('Subject *'), 'Fix the header alignment');
    await pickProject();
    await expect.element(page.getByLabelText('Type *')).toBeVisible();
    await selectOptionNamed('Type *', 'Task');

    const pages = page.getByLabelText('Pages *');
    await expect.element(pages).toBeVisible();
    await expect.element(page.getByText('Please enter a number.')).not.toBeInTheDocument();

    await userEvent.fill(pages, '2-4');

    await expect.element(page.getByText('Please enter a number.')).toBeVisible();
    await expect.element(pages).toHaveAttribute('aria-invalid', 'true');
    await expect.element(pages).toHaveAccessibleDescription('Please enter a number.');

    // Put there whole, the way a paste arrives, rather than key by key.
    await userEvent.fill(pages, '12.5');

    await expect.element(pages).toHaveValue('12.5');
    await expect.element(page.getByText('Please enter a whole number, without a decimal separator.')).toBeVisible();

    await userEvent.click(page.getByTestId('create-wp-submit'));
    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
    await expect.element(pages).toHaveFocus();

    await userEvent.fill(pages, '12');

    await expect.element(page.getByText('Please enter a whole number, without a decimal separator.'))
      .not.toBeInTheDocument();
    await expect.element(pages).not.toHaveAttribute('aria-invalid');

    await userEvent.click(page.getByTestId('create-wp-submit'));
    await expect.element(page.getByTestId('block-card')).toBeVisible();
  });

  it('refuses to submit a type whose required field it cannot offer', async () => {
    worker.use(
      http.post('http://localhost:3000/api/v3/work_packages/form', async ({ request }) => {
        const body = await request.json() as { _links?:Record<string, { href?:string }> };
        const schema:Record<string, unknown> = {
          _type: 'Schema',
          subject: { type: 'String', name: 'Subject', required: true, hasDefault: false, writable: true },
          project: {
            type: 'Project', name: 'Project', required: true, hasDefault: false, writable: true, location: '_links',
            _links: { allowedValues: { href: '/api/v3/work_packages/available_projects' } },
          },
        };
        if (body._links?.project?.href) {
          schema.type = {
            type: 'Type', name: 'Type', required: true, hasDefault: false, writable: true, location: '_links',
            _links: { allowedValues: [{ href: '/api/v3/types/1', title: 'Task' }] },
          };
        }
        if (body._links?.type?.href) {
          schema.customField9 = {
            type: '[]CustomOption', name: 'Tags', required: true, hasDefault: false, writable: true, location: '_links',
          };
        }
        return HttpResponse.json({
          _type: 'Form',
          _embedded: { payload: { subject: null, _links: {} }, schema, validationErrors: {} },
        });
      })
    );

    renderEditor();
    await openCreateModal();

    await userEvent.fill(page.getByLabelText('Subject *'), 'Fix the header alignment');
    await userEvent.click(page.getByLabelText('Project *'));
    await userEvent.click(page.getByRole('option', { name: 'Demo project' }));
    await expect.element(page.getByLabelText('Type *')).toBeVisible();
    await selectOptionNamed('Type *', 'Task');

    await expect.element(page.getByText('"Tags" cannot be set here.')).toBeVisible();
    await expect.element(page.getByRole('link', { name: 'Create it in OpenProject' })).toBeVisible();
    await expect.element(page.getByTestId('create-wp-submit')).toBeDisabled();
  });

  it('keeps the panel within the screen and scrolls the form inside it', async () => {
    await page.viewport(390, 420);

    try {
      renderEditor();
      await openCreateModal();
      await fillRequiredFields('Fix the header alignment');

      const overlayBox = page.getByTestId('create-wp-overlay').element().getBoundingClientRect();
      const panel = page.getByTestId('create-wp-modal').element();
      const panelBox = panel.getBoundingClientRect();

      expect(panelBox.top).toBeGreaterThanOrEqual(overlayBox.top);
      expect(panelBox.bottom).toBeLessThanOrEqual(overlayBox.bottom);

      const body = panel.querySelector('form > div')!;
      expect(body.scrollHeight).toBeGreaterThan(body.clientHeight);
      await expect.element(page.getByText('Create new work package').first()).toBeVisible();
      await expect.element(page.getByTestId('create-wp-submit')).toBeVisible();
    } finally {
      await page.viewport(800, 600);
    }
  });

  it('stands in front of the whole page, not of the editor alone', async () => {
    renderEditor();
    await openCreateModal();

    const overlay = page.getByTestId('create-wp-overlay').element();
    expect(overlay.closest('.bn-container')).toBeNull();
    expect(overlay.parentElement?.parentElement).toBe(document.body);
    expect(getComputedStyle(overlay).position).toBe('fixed');
    expect(getComputedStyle(page.getByTestId('create-wp-modal').element()).display).toBe('flex');
  });

  it('takes the editor theme with it and keeps its own shape', async () => {
    renderEditor();
    await expect.element(page.getByRole('textbox')).toBeVisible();
    page.getByRole('textbox').element().closest('[data-color-scheme]')!
      .setAttribute('data-color-scheme', 'dark');

    await openCreateModal();

    await expect.element(page.getByLabelText('Subject *')).toBeVisible();
    const overlay = page.getByTestId('create-wp-overlay').element();
    const panel = page.getByTestId('create-wp-modal').element();

    expect(getComputedStyle(overlay).getPropertyValue('--op-item-hover-bg').trim())
      .toBe('rgba(255, 255, 255, 0.12)');
    expect(getComputedStyle(page.getByTestId('create-wp-submit').element()).backgroundColor)
      .toBe('rgb(35, 134, 54)');
    expect(getComputedStyle(panel).borderTopLeftRadius).toBe('12px');
    expect(getComputedStyle(page.getByTestId('create-wp-submit').element()).borderTopLeftRadius).toBe('6px');
    expect(getComputedStyle(page.getByLabelText('Subject *').element()).borderTopLeftRadius).toBe('6px');
    expect(getComputedStyle(page.getByLabelText('Subject *').element()).borderTopColor).toBe('rgb(61, 68, 77)');
  });

  it('takes the font of the editor with it, rather than one of its own', async () => {
    renderEditor();
    await expect.element(page.getByRole('textbox')).toBeVisible();
    const editorFont = getComputedStyle(page.getByRole('textbox').element()).fontFamily;
    expect(editorFont).toContain('Inter');

    await openCreateModal();

    const overlay = page.getByTestId('create-wp-overlay').element();
    expect(getComputedStyle(overlay).fontFamily).toBe(editorFont);
  });

  it('paints and sizes the buttons as the design does', async () => {
    renderEditor();
    await openCreateModal();
    await expect.element(page.getByLabelText('Subject *')).toBeVisible();

    const submit = page.getByTestId('create-wp-submit').element();
    for (const button of [submit, page.getByRole('button', { name: 'Cancel' }).element()]) {
      const styles = getComputedStyle(button);
      expect(button.getBoundingClientRect().height).toBe(28);
      expect(styles.fontSize).toBe('12px');
      expect(styles.fontWeight).toBe('600');
    }

    expect(getComputedStyle(submit).backgroundColor).toBe('rgb(31, 136, 61)');
    const cancel = getComputedStyle(page.getByRole('button', { name: 'Cancel' }).element());
    expect(cancel.backgroundColor).toBe('rgb(246, 248, 250)');
    expect(cancel.border).toBe('1px solid rgb(209, 217, 224)');
  });

  it('follows the metrics of the design', async () => {
    renderEditor();
    await openCreateModal();
    await expect.element(page.getByLabelText('Subject *')).toBeVisible();

    const panel = page.getByTestId('create-wp-modal').element();
    const [header, body, footer] = [
      panel.firstElementChild!,
      panel.querySelector('form > div')!,
      panel.querySelector('form > div:last-child')!,
    ];
    expect([header, body, footer].map((part) => getComputedStyle(part).padding))
      .toEqual(['8px', '16px', '8px']);

    const label = getComputedStyle(panel.querySelector('label')!);
    expect([label.fontSize, label.fontWeight, label.color]).toEqual(['14px', '600', 'rgb(31, 35, 40)']);

    const subject = page.getByLabelText('Subject *').element();
    const control = getComputedStyle(subject);
    expect([control.fontSize, control.fontWeight, control.color]).toEqual(['14px', '400', 'rgb(31, 35, 40)']);
    const hint = getComputedStyle(subject, '::placeholder');
    expect([hint.fontSize, hint.fontWeight, hint.color]).toEqual(['14px', '400', 'rgb(89, 99, 110)']);

    const project = page.getByLabelText('Project *').element();
    expect(getComputedStyle(project, '::placeholder').opacity).toBe('1');
    await userEvent.click(project);
    expect(getComputedStyle(project, '::placeholder').opacity).toBe('0');
  });

  it('keeps its controls legible under the metrics the host forces on inputs', async () => {
    // What OpenProject applies to every input and select of the page.
    const hostStyles = document.createElement('style');
    hostStyles.textContent = 'input, select { height: 26px; line-height: 100%; }';
    document.head.appendChild(hostStyles);

    try {
      renderEditor();
      await openCreateModal();
      await pickProject();
      await expect.element(page.getByLabelText('Type *')).toBeVisible();

      const select = page.getByLabelText('Type *').element();
      const input = page.getByLabelText('Subject *').element();

      for (const control of [select, input]) {
        const styles = getComputedStyle(control);
        expect(styles.height).not.toBe('26px');
        expect(parseFloat(styles.lineHeight)).toBeGreaterThan(parseFloat(styles.fontSize));
      }
    } finally {
      hostStyles.remove();
    }
  });

  it('gives both pickers the same arrows and shape', async () => {
    renderEditor();
    await openCreateModal();
    await pickProject();
    await expect.element(page.getByLabelText('Type *')).toBeVisible();

    const controls = [page.getByLabelText('Project *').element(), page.getByLabelText('Type *').element()];
    const shapes = controls.map((control) => {
      const arrows = control.parentElement!.querySelectorAll('svg');
      const styles = getComputedStyle(control);
      return {
        arrows: arrows.length,
        color: getComputedStyle(arrows[0]).color,
        paddingRight: styles.paddingRight,
        height: Math.round(control.getBoundingClientRect().height),
      };
    });

    expect(shapes[0]).toEqual(shapes[1]);
    expect(shapes[0]).toMatchObject({ arrows: 2, color: 'rgb(89, 99, 110)' });
  });

  it('holds the page still while the form scrolls, and lets it go again', async () => {
    renderEditor();
    await openCreateModal();
    await expect.element(page.getByLabelText('Subject *')).toBeVisible();

    expect(getComputedStyle(document.body).overflow).toBe('hidden');
    const overlay = page.getByTestId('create-wp-overlay').element();
    expect(getComputedStyle(overlay).overflowY).toBe('auto');

    await userEvent.click(page.getByRole('button', { name: 'Cancel' }));

    await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
    expect(getComputedStyle(document.body).overflow).not.toBe('hidden');
  });

  it('keeps its divider drawn under the reset the host forces onto every rule', async () => {
    // What Primer applies to every "hr" of the page, reduced to what matters here.
    const hostStyles = document.createElement('style');
    hostStyles.textContent = 'hr { height: 0; border: 0; border-bottom: 1px solid #ff0000; margin: 24px 0; }';
    document.head.appendChild(hostStyles);

    try {
      renderEditor();
      await openCreateModal();
      await fillRequiredFields('Fix the header alignment');

      const styles = getComputedStyle(page.getByTestId('create-wp-divider').element());
      expect([styles.borderTopWidth, styles.borderTopStyle]).toEqual(['1px', 'solid']);
      expect(styles.borderTopColor).not.toBe('rgb(255, 0, 0)');
      expect(styles.marginBottom).toBe('16px');
    } finally {
      hostStyles.remove();
    }
  });

  it('keeps the arrow the host application forces onto every select turned off', async () => {
    // The rule OpenProject applies page wide, reduced to what matters here.
    const hostStyles = document.createElement('style');
    hostStyles.textContent = 'select:not(.FormControl-select) { background-image: url("data:image/gif;base64,R0lGODlhAQABAAAAACw=") !important; }';
    document.head.appendChild(hostStyles);

    try {
      renderEditor();
      await openCreateModal();
      await pickProject();
      await expect.element(page.getByLabelText('Type *')).toBeVisible();

      const select = document.querySelector('.op-bn-create-wp select')!;
      expect(getComputedStyle(select).backgroundImage).toBe('none');
    } finally {
      hostStyles.remove();
    }
  });
});
