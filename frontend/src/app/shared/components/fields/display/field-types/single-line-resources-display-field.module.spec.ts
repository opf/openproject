import { SingleLineResourcesDisplayField } from './single-line-resources-display-field.module';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { DisplayFieldContext } from 'core-app/shared/components/fields/display/display-field.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';

describe('SingleLineResourcesDisplayField', () => {
  let field:SingleLineResourcesDisplayField;
  let element:HTMLElement;

  const mockI18n = { t: (key:string) => key };

  const serviceMap = new Map<unknown, unknown>([
    [I18nService, mockI18n],
  ]);

  const mockInjector = {
    get: (token:unknown, notFoundValue?:unknown) => serviceMap.get(token) ?? notFoundValue ?? {},
  };

  function render(values:string[]) {
    const resource = {
      targetVersions: values.map((name) => ({ name })),
    } as unknown as HalResource;

    field = new SingleLineResourcesDisplayField('targetVersions', {
      injector: mockInjector,
      container: 'single-view',
      options: { layout: 'singleline' },
    } as unknown as DisplayFieldContext);

    field.apply(resource, { type: '[]Version' } as IFieldSchema);

    element = document.createElement('div');
    field.render(element, field.valueString);
  }

  it('renders all values comma-separated on one line', () => {
    render(['Sprint 1', 'Master backlog', 'backlog']);

    expect(element.textContent).toEqual('Sprint 1, Master backlog, backlog');
  });

  it('does not abridge to a count badge for more than two values', () => {
    render(['Sprint 1', 'Master backlog', 'backlog', 'Release 1.0.0']);

    expect(element.querySelector('.badge')).toBeNull();
    expect(element.textContent).toContain('Release 1.0.0');
  });

  it('renders a single value plainly', () => {
    render(['Sprint 1']);

    expect(element.textContent).toEqual('Sprint 1');
  });

  it('keeps the full value list as the element title', () => {
    render(['Sprint 1', 'Master backlog']);

    expect(element.getAttribute('title')).toEqual('Sprint 1, Master backlog');
  });
});