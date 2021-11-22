import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UIRouterModule } from '@uirouter/angular';
import { DynamicModule } from 'ng-dynamic-component';
import { FullCalendarModule } from '@fullcalendar/angular';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { OpenprojectPrincipalRenderingModule } from 'core-app/shared/components/principal/principal-rendering.module';
import { OpenprojectWorkPackagesModule } from 'core-app/features/work-packages/openproject-work-packages.module';
import { TEAM_PLANNER_ROUTES } from 'core-app/features/team-planner/team-planner/team-planner.routes';
import { TeamPlannerComponent } from 'core-app/features/team-planner/team-planner/planner/team-planner.component';
import { TeamPlannerPageComponent } from 'core-app/features/team-planner/team-planner/page/team-planner-page.component';
import { OPSharedModule } from 'core-app/shared/shared.module';

@NgModule({
  declarations: [
    TeamPlannerComponent,
    TeamPlannerPageComponent,
  ],
  imports: [
    OPSharedModule,
    // Routes for /backlogs
    UIRouterModule.forChild({
      states: TEAM_PLANNER_ROUTES,
    }),
    DynamicModule,
    CommonModule,
    IconModule,
    OpenprojectPrincipalRenderingModule,
    OpenprojectWorkPackagesModule,
    FullCalendarModule,
  ],
})
export class TeamPlannerModule {}
