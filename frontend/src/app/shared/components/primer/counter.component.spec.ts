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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ComponentFixture, TestBed } from '@angular/core/testing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PrimerCounterComponent } from './counter.component';

describe('PrimerCounterComponent', () => {
  const I18nStub = {
    locale: 'en',
    t(key:string) {
      return {
        'js.label_infinity': 'Infinity',
        'js.label_not_available': 'Not available',
      }[key] ?? key;
    },
  };

  let fixture:ComponentFixture<PrimerCounterComponent>;
  let span:HTMLSpanElement;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [PrimerCounterComponent],
      providers: [
        { provide: I18nService, useValue: I18nStub },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(PrimerCounterComponent);
    span = fixture.elementRef.nativeElement.querySelector('span.Counter') as HTMLSpanElement;
  });

  function render(inputs:Record<string, unknown>):void {
    Object.entries(inputs).forEach(([key, value]) => fixture.componentRef.setInput(key, value));
    fixture.detectChanges();
  }

  it('renders a plain count', () => {
    render({ count: 12 });

    expect(span.textContent).toEqual('12');
    expect(span.getAttribute('title')).toEqual('12');
  });

  it('delimits large numbers', () => {
    render({ count: 1234, limit: null });

    expect(span.textContent).toEqual('1,234');
  });

  it('applies the limit with a trailing plus', () => {
    render({ count: 6000, limit: 5000 });

    expect(span.textContent).toEqual('5,000+');
    expect(span.getAttribute('title')).toEqual('5,000+');
  });

  it('renders nothing and a fallback title for a null count', () => {
    render({ count: null });

    expect(span.textContent).toEqual('');
    expect(span.getAttribute('title')).toEqual('Not available');
  });

  it('renders nothing and a fallback title for an undefined count', () => {
    render({ count: undefined });

    expect(span.textContent).toEqual('');
    expect(span.getAttribute('title')).toEqual('Not available');
  });

  it('renders nothing and a fallback title for a NaN count', () => {
    render({ count: NaN });

    expect(span.textContent).toEqual('');
    expect(span.getAttribute('title')).toEqual('Not available');
  });

  it('renders the infinity symbol', () => {
    render({ count: Infinity });

    expect(span.textContent).toEqual('∞');
    expect(span.getAttribute('title')).toEqual('Infinity');
  });

  it('applies the scheme modifier class', () => {
    render({ count: 1, scheme: 'secondary' });

    expect(span.classList).toContain('Counter--secondary');
    expect(span.classList).not.toContain('Counter--primary');
  });

  it('hides a zero count when hideIfZero is set', () => {
    render({ count: 0, 'hide-if-zero': true });

    expect(span.hidden).toBe(true);
  });

  it('does not hide a zero count by default', () => {
    render({ count: 0 });

    expect(span.hidden).toBe(false);
    expect(span.textContent).toEqual('0');
  });
});
