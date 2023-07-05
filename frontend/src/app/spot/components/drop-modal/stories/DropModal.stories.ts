import type { Meta, StoryObj } from '@storybook/angular';
import { moduleMetadata } from '@storybook/angular';

import { I18nService } from '../../../../core/i18n/i18n.service';
import { I18nServiceStub } from '../../../../../stories/i18n.service.stub';

import { OpSpotModule } from '../../../spot.module';
import SpotDropAlignmentOption from '../../../drop-alignment-options';

import { SpotDropModalComponent } from '../drop-modal.component';

const meta:Meta = {
  title: 'Patterns/DropModal',
  component: SpotDropModalComponent,
  decorators: [
    moduleMetadata({
      imports: [
        OpSpotModule,
      ],
      providers: [
        {
          provide: I18nService,
          useFactory: () => I18nServiceStub,
        },
      ],
    }),
  ],
};

export default meta;
type Story = StoryObj;

export const Default:Story = {
  render: (args) => ({
    props: {
      ...args,
      dropModalOpen: false,
      alignment: SpotDropAlignmentOption.BottomCenter,
    },
    template: `
      <spot-drop-modal-portal></spot-drop-modal-portal>

      <spot-drop-modal
        [opened]="dropModalOpen"
        (closed)="dropModalOpen = false"
        [alignment]="alignment"
      >
        <button
          aria-haspopup="true"
          type="button"
          slot="trigger"
          (click)="dropModalOpen = !dropModalOpen"
          class="button"
        >
          Open drop-modal
        </button>

        <ng-container slot="body">
          <div class="spot-container">
            <ul class="spot-list">
              <li class="spot-list--item">
                <button type="button" class="spot-list--item-action">Random Option 1</button>
              </li>
              <li class="spot-list--item">
                <button type="button" class="spot-list--item-action">Random Option 2</button>
              </li>
              <li class="spot-list--item">
                <button type="button" class="spot-list--item-action">Random Option 3</button>
              </li>
              <li class="spot-list--item">
                <button type="button" class="spot-list--item-action">Random Option 4</button>
              </li>
            </ul>

            <div class="spot-action-bar">
              <div class="spot-action-bar--right">
                <button
                  class="spot-button"
                  type="button"
                >
                  Some action
                </button>
              </div>
            </div>
          </div>
        </ng-container>
      </spot-drop-modal>
   `,
  }),
};
