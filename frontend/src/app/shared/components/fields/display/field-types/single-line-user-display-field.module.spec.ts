import { SingleLineUserDisplayField } from './single-line-user-display-field.module';
import { PrincipalRendererService } from 'core-app/shared/components/principal/principal-renderer.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { DisplayFieldContext } from 'core-app/shared/components/fields/display/display-field.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';

describe('SingleLineUserDisplayField', () => {
  let field:SingleLineUserDisplayField;
  let element:HTMLElement;
  let renderMultipleCalls:unknown[][];

  const mockI18n = { t: (key:string) => key };

  const mockPrincipalRenderer = {
    renderMultiple: (...args:unknown[]) => renderMultipleCalls.push(args),
  };

  const serviceMap = new Map<unknown, unknown>([
    [I18nService, mockI18n],
    [PrincipalRendererService, mockPrincipalRenderer],
  ]);

  const mockInjector = {
    get: (token:unknown, notFoundValue?:unknown) => serviceMap.get(token) ?? notFoundValue ?? {},
  };

  function render(names:string[]) {
    renderMultipleCalls = [];

    const resource = {
      multiUser: names.map((name) => ({ name })),
    } as unknown as HalResource;

    field = new SingleLineUserDisplayField('multiUser', {
      injector: mockInjector,
      container: 'single-view',
      options: { layout: 'singleline' },
    } as unknown as DisplayFieldContext);

    field.apply(resource, { type: '[]User' } as IFieldSchema);

    element = document.createElement('div');
    field.render(element, names.join(', '));
  }

  it('renders users through the principal renderer in its inline mode', () => {
    render(['Kabiru User II', 'GitLab User']);

    expect(renderMultipleCalls.length).toEqual(1);

    const [container, users, , , , multiLine] = renderMultipleCalls[0];
    expect(container).toBe(element);
    expect((users as { name:string }[]).map((u) => u.name)).toEqual(['Kabiru User II', 'GitLab User']);
    expect(multiLine).toBe(false);
  });

  it('renders the placeholder for an empty value list', () => {
    render([]);

    expect(renderMultipleCalls.length).toEqual(0);
    expect(element.textContent).toEqual('js.placeholders.default');
  });
});
