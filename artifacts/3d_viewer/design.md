# Slice 2: 3D Viewer Enhancement - Design Document

## Mode: Deliberation
**Status:** Architecture & Research
**Priority:** 2 (Depends on IFC Upload)
**Dependencies:** Slice 1 (IFC Upload) - requires optimized XKT files and metadata

---

## Current State Analysis

### Existing Capabilities (Community Edition)
- **Library**: xeokit-bim-viewer v2.7.1
- **Features**:
  - Load/display XKT models
  - Basic camera controls (orbit, pan, zoom)
  - Orthogonal/perspective projection
  - Component selection, coloring, visibility
  - BCF viewpoint save/load
  - Navigation cube
  - Model tree explorer
  - Inspector panel (element properties)
  - Basic measurements (configurable)

### Current Architecture
```
IFCViewerComponent
    ↓
IFCViewerService (extends ViewerBridgeService)
    ↓
xeokit BIMViewer instance
    ├─→ Canvas (3D rendering)
    ├─→ Navigation Cube
    ├─→ Toolbar (camera, inspect, select)
    ├─→ TreeView (model hierarchy)
    └─→ Inspector (properties)
```

**Key Files:**
- `/frontend/src/app/features/bim/ifc_models/ifc-viewer/ifc-viewer.service.ts`
- `/frontend/src/app/features/bim/ifc_models/ifc-viewer/ifc-viewer.component.ts`
- `/frontend/src/app/features/bim/ifc_models/xeokit/xeokit-server.ts`

### Limitations to Address
1. **No section cuts/clipping planes** beyond basic BCF clipping
2. **Limited measurement tools** (no area, volume, angle measurements)
3. **No advanced navigation** (first-person walk mode, predefined views)
4. **No visual effects** (shadows, ambient occlusion, realistic rendering)
5. **No annotation tools** (markup, dimensioning on model)
6. **Limited performance** for very large models (>100k objects)
7. **No model animations** or time-based visualization
8. **No comparison overlays** (planned vs actual, version diffs)

---

## Enterprise Enhancement Goals

### 1. Advanced Section Cuts & Clipping
- **6-Plane Clipping Box**: Interactive box with draggable handles
- **Custom Section Planes**: User-defined cut planes with rotation
- **Section Views**: Saved section configurations (e.g., "Floor 1 Plan")
- **Edge Highlighting**: Show cut edges in contrasting color
- **Section Fills**: Solid color fills for cut surfaces

### 2. Comprehensive Measurement Suite
- **Distance**: Point-to-point, multi-segment
- **Area**: Surface area, floor area (horizontal projection)
- **Volume**: Bounding box volume, mesh volume
- **Angle**: Angle between surfaces/edges
- **Elevation**: Height from reference level
- **Persistent Measurements**: Save/load measurement sets
- **Export Measurements**: CSV/PDF reports

### 3. Enhanced Navigation
- **Walk Mode**: First-person navigation with collision detection
- **Fly Mode**: Free-form aerial navigation
- **Predefined Views**: Standard views (North, South, Top, Isometric)
- **Saved Camera Positions**: Named bookmarks
- **Guided Tours**: Animated camera paths
- **Minimap**: 2D plan view with current camera indicator

### 4. Visual Quality Enhancements
- **Realistic Rendering**:
  - Shadow mapping
  - Ambient occlusion (SSAO)
  - Physically-based materials (PBR)
  - Environment lighting (HDR skybox)
- **Edge Rendering**: Silhouette edges, crease edges
- **Transparency Effects**: Order-independent transparency
- **Highlighting Modes**: Glow, outline, X-ray

### 5. Annotation & Markup
- **3D Labels**: Text annotations anchored to elements
- **Dimensioning**: Automatic dimension lines
- **Sketches**: Freehand drawing on model
- **Symbols**: Standard BIM symbols (revision cloud, danger, etc.)
- **Redlining**: Markup layers linked to BCF issues

### 6. Performance Optimization
- **Progressive Loading**: LOD-based streaming
- **Instancing**: Optimize repeated elements (windows, doors)
- **Occlusion Culling**: Don't render hidden geometry
- **Spatial Indexing**: BVH/Octree for fast picking
- **Web Workers**: Offload parsing to background threads

### 7. Comparison & Analysis Overlays
- **Version Comparison**: Highlight additions/deletions/modifications
- **Planned vs Actual**: Color-code progress
- **Heatmaps**: Progress, issues, costs by element
- **Clash Highlighting**: Visualize detected clashes

---

## Proposed Architecture

### Layer 1: Enhanced Viewer Service

```typescript
// Enhanced: ifc-viewer.service.ts
export class IFCViewerService extends ViewerBridgeService {
  private sectionManager: SectionManager;
  private measurementManager: MeasurementManager;
  private navigationManager: NavigationManager;
  private annotationManager: AnnotationManager;
  private renderingManager: RenderingManager;

  initializeViewer(element: HTMLElement): void {
    this.viewer = new BIMViewer({
      canvasElement: element,
      enableSAO: true, // Screen-space ambient occlusion
      enableEdges: true,
      enablePBR: true, // Physically-based rendering
      dtxEnabled: true, // Distance transparency
    });

    this.sectionManager = new SectionManager(this.viewer);
    this.measurementManager = new MeasurementManager(this.viewer);
    this.navigationManager = new NavigationManager(this.viewer);
    this.annotationManager = new AnnotationManager(this.viewer);
    this.renderingManager = new RenderingManager(this.viewer);
  }

  // Advanced navigation
  setNavigationMode(mode: 'orbit' | 'walk' | 'fly' | 'plan'): void {
    this.navigationManager.setMode(mode);
  }

  createSavedView(name: string): SavedView {
    return this.navigationManager.saveView(name);
  }

  // Section management
  createSectionBox(): SectionBox {
    return this.sectionManager.createBox();
  }

  createSectionPlane(origin: Vec3, normal: Vec3): SectionPlane {
    return this.sectionManager.createPlane(origin, normal);
  }

  // Measurement tools
  startMeasurement(type: MeasurementType): void {
    this.measurementManager.startMeasurement(type);
  }

  exportMeasurements(): MeasurementReport {
    return this.measurementManager.exportReport();
  }

  // Annotation
  createAnnotation(position: Vec3, text: string): Annotation {
    return this.annotationManager.create(position, text);
  }

  // Rendering quality
  setRenderingQuality(quality: 'low' | 'medium' | 'high' | 'ultra'): void {
    this.renderingManager.setQuality(quality);
  }

  enableShadows(enabled: boolean): void {
    this.renderingManager.setShadows(enabled);
  }
}
```

### Layer 2: Section Management

```typescript
// New: section-manager.ts
export class SectionManager {
  private viewer: BIMViewer;
  private sectionBoxes: Map<string, SectionBox> = new Map();
  private sectionPlanes: Map<string, SectionPlane> = new Map();

  createBox(): SectionBox {
    const id = generateUUID();
    const box = new SectionBox(this.viewer.scene, {
      id,
      visible: true,
      gizmoVisible: true, // Show draggable handles
    });

    // Add interaction handlers
    box.on('updated', () => this.saveSectionState());

    this.sectionBoxes.set(id, box);
    return box;
  }

  createPlane(origin: Vec3, normal: Vec3): SectionPlane {
    const id = generateUUID();
    const plane = new SectionPlane(this.viewer.scene, {
      id,
      pos: origin,
      dir: normal,
    });

    // Create interactive gizmo for rotation/translation
    const gizmo = new SectionPlaneGizmo(this.viewer.scene, plane);

    this.sectionPlanes.set(id, plane);
    return plane;
  }

  saveSectionConfiguration(name: string): SectionConfig {
    return {
      name,
      boxes: Array.from(this.sectionBoxes.values()).map(box => ({
        id: box.id,
        min: box.min,
        max: box.max,
      })),
      planes: Array.from(this.sectionPlanes.values()).map(plane => ({
        id: plane.id,
        pos: plane.pos,
        dir: plane.dir,
      })),
    };
  }

  loadSectionConfiguration(config: SectionConfig): void {
    // Restore saved section cuts
  }
}
```

### Layer 3: Measurement Management

```typescript
// New: measurement-manager.ts
export type MeasurementType = 'distance' | 'area' | 'volume' | 'angle' | 'elevation';

export interface Measurement {
  id: string;
  type: MeasurementType;
  value: number;
  unit: string;
  points: Vec3[];
  label: string;
  visible: boolean;
}

export class MeasurementManager {
  private viewer: BIMViewer;
  private measurements: Map<string, Measurement> = new Map();
  private currentPlugin: MeasurementPlugin | null = null;

  startMeasurement(type: MeasurementType): void {
    // Deactivate current tool
    this.currentPlugin?.deactivate();

    switch (type) {
      case 'distance':
        this.currentPlugin = new DistanceMeasurementPlugin(this.viewer);
        break;
      case 'area':
        this.currentPlugin = new AreaMeasurementPlugin(this.viewer);
        break;
      case 'volume':
        this.currentPlugin = new VolumeMeasurementPlugin(this.viewer);
        break;
      case 'angle':
        this.currentPlugin = new AngleMeasurementPlugin(this.viewer);
        break;
      case 'elevation':
        this.currentPlugin = new ElevationMeasurementPlugin(this.viewer);
        break;
    }

    this.currentPlugin.on('complete', (measurement: Measurement) => {
      this.measurements.set(measurement.id, measurement);
      this.saveMeasurement(measurement);
    });

    this.currentPlugin.activate();
  }

  exportReport(): MeasurementReport {
    return {
      measurements: Array.from(this.measurements.values()),
      timestamp: new Date(),
      modelId: this.viewer.modelId,
      format: 'csv' // or 'pdf'
    };
  }

  private saveMeasurement(measurement: Measurement): void {
    // Save to backend via API
    this.apiService.post(`/api/bim/v1/measurements`, { measurement });
  }
}
```

### Layer 4: Navigation Management

```typescript
// New: navigation-manager.ts
export class NavigationManager {
  private viewer: BIMViewer;
  private mode: NavigationMode = 'orbit';
  private savedViews: Map<string, SavedView> = new Map();

  setMode(mode: 'orbit' | 'walk' | 'fly' | 'plan'): void {
    this.mode = mode;

    switch (mode) {
      case 'orbit':
        this.viewer.cameraControl.navMode = 'orbit';
        this.viewer.cameraControl.followPointer = false;
        break;

      case 'walk':
        this.viewer.cameraControl.navMode = 'firstPerson';
        this.viewer.cameraControl.followPointer = true;
        this.enableCollisionDetection(true);
        break;

      case 'fly':
        this.viewer.cameraControl.navMode = 'planView';
        this.viewer.cameraControl.followPointer = true;
        this.enableCollisionDetection(false);
        break;

      case 'plan':
        this.viewer.cameraControl.navMode = 'planView';
        this.setPlanView();
        break;
    }
  }

  saveView(name: string): SavedView {
    const camera = this.viewer.camera;
    const view: SavedView = {
      name,
      eye: camera.eye.slice(),
      look: camera.look.slice(),
      up: camera.up.slice(),
      projection: camera.projection,
    };

    this.savedViews.set(name, view);
    this.saveViewToBackend(view);
    return view;
  }

  restoreView(name: string): void {
    const view = this.savedViews.get(name);
    if (!view) return;

    this.viewer.camera.eye = view.eye;
    this.viewer.camera.look = view.look;
    this.viewer.camera.up = view.up;
    this.viewer.camera.projection = view.projection;
  }

  setPredefinedView(view: 'north' | 'south' | 'east' | 'west' | 'top' | 'bottom' | 'isometric'): void {
    const aabb = this.viewer.scene.aabb;
    const center = [
      (aabb[0] + aabb[3]) / 2,
      (aabb[1] + aabb[4]) / 2,
      (aabb[2] + aabb[5]) / 2,
    ];

    const distance = Math.max(
      aabb[3] - aabb[0],
      aabb[4] - aabb[1],
      aabb[5] - aabb[2]
    ) * 1.5;

    const viewConfigs = {
      north: { eye: [center[0], center[1] - distance, center[2]], up: [0, 0, 1] },
      south: { eye: [center[0], center[1] + distance, center[2]], up: [0, 0, 1] },
      east: { eye: [center[0] + distance, center[1], center[2]], up: [0, 0, 1] },
      west: { eye: [center[0] - distance, center[1], center[2]], up: [0, 0, 1] },
      top: { eye: [center[0], center[1], center[2] + distance], up: [0, 1, 0] },
      bottom: { eye: [center[0], center[1], center[2] - distance], up: [0, -1, 0] },
      isometric: {
        eye: [center[0] + distance, center[1] - distance, center[2] + distance],
        up: [0, 0, 1]
      },
    };

    const config = viewConfigs[view];
    this.viewer.camera.eye = config.eye;
    this.viewer.camera.look = center;
    this.viewer.camera.up = config.up;
  }

  private enableCollisionDetection(enabled: boolean): void {
    // Implement basic collision detection for walk mode
    if (enabled) {
      // Use xeokit's built-in or implement custom collision
    }
  }
}
```

### Layer 5: Rendering Quality Management

```typescript
// New: rendering-manager.ts
export class RenderingManager {
  private viewer: BIMViewer;
  private sao: SAOOcclusionRenderer;
  private shadowRenderer: ShadowRenderer | null = null;

  constructor(viewer: BIMViewer) {
    this.viewer = viewer;
    this.sao = new SAOOcclusionRenderer(viewer.scene);
  }

  setQuality(quality: 'low' | 'medium' | 'high' | 'ultra'): void {
    const configs = {
      low: {
        sao: false,
        edges: false,
        pbr: false,
        shadows: false,
        antialias: false,
      },
      medium: {
        sao: true,
        saoScale: 0.5,
        edges: true,
        pbr: false,
        shadows: false,
        antialias: true,
      },
      high: {
        sao: true,
        saoScale: 1.0,
        edges: true,
        pbr: true,
        shadows: true,
        shadowQuality: 'medium',
        antialias: true,
      },
      ultra: {
        sao: true,
        saoScale: 1.5,
        saoNumSamples: 32,
        edges: true,
        pbr: true,
        shadows: true,
        shadowQuality: 'high',
        shadowMapSize: 2048,
        antialias: true,
      },
    };

    const config = configs[quality];
    this.applySAO(config.sao, config.saoScale, config.saoNumSamples);
    this.applyEdges(config.edges);
    this.applyPBR(config.pbr);
    this.applyShadows(config.shadows, config.shadowQuality, config.shadowMapSize);
  }

  setShadows(enabled: boolean): void {
    if (enabled && !this.shadowRenderer) {
      this.shadowRenderer = new ShadowRenderer(this.viewer.scene, {
        lightPos: [100, 100, 100],
        shadowMapSize: 2048,
      });
    } else if (!enabled && this.shadowRenderer) {
      this.shadowRenderer.destroy();
      this.shadowRenderer = null;
    }
  }

  private applySAO(enabled: boolean, scale?: number, numSamples?: number): void {
    if (!enabled) {
      this.sao.enabled = false;
      return;
    }

    this.sao.enabled = true;
    if (scale) this.sao.scale = scale;
    if (numSamples) this.sao.numSamples = numSamples;
  }

  private applyEdges(enabled: boolean): void {
    this.viewer.scene.edgeMaterial.edges = enabled;
  }

  private applyPBR(enabled: boolean): void {
    this.viewer.scene.pbrEnabled = enabled;
  }

  private applyShadows(enabled: boolean, quality?: string, mapSize?: number): void {
    this.setShadows(enabled);
    if (enabled && this.shadowRenderer) {
      if (quality === 'high') {
        this.shadowRenderer.shadowMapSize = mapSize || 2048;
      } else {
        this.shadowRenderer.shadowMapSize = 1024;
      }
    }
  }
}
```

### Layer 6: Database Schema

```sql
-- Saved views
CREATE TABLE bim_saved_views (
  id BIGSERIAL PRIMARY KEY,
  ifc_model_id BIGINT NOT NULL REFERENCES ifc_models(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  name VARCHAR(255) NOT NULL,
  camera_eye JSONB NOT NULL, -- [x, y, z]
  camera_look JSONB NOT NULL,
  camera_up JSONB NOT NULL,
  projection VARCHAR(20), -- 'perspective' or 'orthogonal'
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Section configurations
CREATE TABLE bim_section_configs (
  id BIGSERIAL PRIMARY KEY,
  ifc_model_id BIGINT NOT NULL REFERENCES ifc_models(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  name VARCHAR(255) NOT NULL,
  section_boxes JSONB DEFAULT '[]'::jsonb,
  section_planes JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Measurements
CREATE TABLE bim_measurements (
  id BIGSERIAL PRIMARY KEY,
  ifc_model_id BIGINT NOT NULL REFERENCES ifc_models(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  measurement_type VARCHAR(50) NOT NULL, -- 'distance', 'area', 'volume', etc.
  value DECIMAL(15, 4) NOT NULL,
  unit VARCHAR(20) NOT NULL,
  points JSONB NOT NULL, -- Array of [x, y, z] points
  label VARCHAR(255),
  visible BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Annotations
CREATE TABLE bim_annotations (
  id BIGSERIAL PRIMARY KEY,
  ifc_model_id BIGINT NOT NULL REFERENCES ifc_models(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  annotation_type VARCHAR(50) NOT NULL, -- 'label', 'dimension', 'sketch', 'symbol'
  position JSONB NOT NULL, -- [x, y, z]
  content TEXT,
  style JSONB, -- Colors, font, etc.
  visible BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_saved_views_model ON bim_saved_views(ifc_model_id);
CREATE INDEX idx_section_configs_model ON bim_section_configs(ifc_model_id);
CREATE INDEX idx_measurements_model ON bim_measurements(ifc_model_id);
CREATE INDEX idx_annotations_model ON bim_annotations(ifc_model_id);
```

### Layer 7: API Endpoints

```ruby
# New API endpoints
module API::Bim::V1
  # Saved Views
  POST   /api/bim/v1/ifc_models/:id/saved_views
  GET    /api/bim/v1/ifc_models/:id/saved_views
  GET    /api/bim/v1/saved_views/:id
  PUT    /api/bim/v1/saved_views/:id
  DELETE /api/bim/v1/saved_views/:id

  # Section Configurations
  POST   /api/bim/v1/ifc_models/:id/section_configs
  GET    /api/bim/v1/ifc_models/:id/section_configs
  DELETE /api/bim/v1/section_configs/:id

  # Measurements
  POST   /api/bim/v1/ifc_models/:id/measurements
  GET    /api/bim/v1/ifc_models/:id/measurements
  DELETE /api/bim/v1/measurements/:id
  GET    /api/bim/v1/ifc_models/:id/measurements/export # CSV/PDF

  # Annotations
  POST   /api/bim/v1/ifc_models/:id/annotations
  GET    /api/bim/v1/ifc_models/:id/annotations
  PUT    /api/bim/v1/annotations/:id
  DELETE /api/bim/v1/annotations/:id
end
```

---

## Technology Stack

### Frontend Dependencies

**Existing:**
- `@xeokit/xeokit-bim-viewer: 2.7.1`

**New/Upgraded:**
- `@xeokit/xeokit-sdk: ^2.5.0` - Core SDK for advanced features
- Consider forking xeokit for custom enhancements

**Custom Plugins (TypeScript):**
- `AreaMeasurementPlugin`
- `VolumeMeasurementPlugin`
- `AngleMeasurementPlugin`
- `ElevationMeasurementPlugin`
- `SectionPlaneGizmo`
- `AnnotationRenderer`
- `ShadowRenderer` (if not in xeokit)

### Backend Dependencies
- No new Ruby gems required
- Use existing Rails API infrastructure

---

## API Contracts

### POST /api/bim/v1/ifc_models/:id/saved_views
**Request:**
```json
{
  "name": "Floor 1 Overview",
  "camera_eye": [10.5, 20.3, 15.8],
  "camera_look": [0, 0, 0],
  "camera_up": [0, 0, 1],
  "projection": "perspective"
}
```

**Response:**
```json
{
  "id": 123,
  "name": "Floor 1 Overview",
  "camera_eye": [10.5, 20.3, 15.8],
  "camera_look": [0, 0, 0],
  "camera_up": [0, 0, 1],
  "projection": "perspective",
  "created_at": "2025-11-07T10:00:00Z",
  "_links": {
    "self": "/api/bim/v1/saved_views/123",
    "model": "/api/bim/v1/ifc_models/456"
  }
}
```

### POST /api/bim/v1/ifc_models/:id/measurements
**Request:**
```json
{
  "measurement_type": "distance",
  "value": 12.5,
  "unit": "m",
  "points": [[0, 0, 0], [10, 5, 0]],
  "label": "Column spacing"
}
```

---

## Testing Strategy

### Unit Tests
```typescript
// section-manager.spec.ts
describe('SectionManager', () => {
  it('creates section box with default properties', () => {
    const box = sectionManager.createBox();
    expect(box.visible).toBe(true);
    expect(box.gizmoVisible).toBe(true);
  });

  it('saves section configuration', () => {
    sectionManager.createBox();
    const config = sectionManager.saveSectionConfiguration('Floor 1 Plan');
    expect(config.name).toBe('Floor 1 Plan');
    expect(config.boxes).toHaveLength(1);
  });
});

// measurement-manager.spec.ts
describe('MeasurementManager', () => {
  it('starts distance measurement', () => {
    measurementManager.startMeasurement('distance');
    expect(measurementManager.currentPlugin).toBeInstanceOf(DistanceMeasurementPlugin);
  });

  it('exports measurement report', () => {
    const report = measurementManager.exportReport();
    expect(report.measurements).toBeInstanceOf(Array);
    expect(report.format).toBe('csv');
  });
});
```

### E2E Tests
```ruby
# spec/features/bim/viewer_enhancements_spec.rb
RSpec.describe 'Enhanced 3D Viewer', :js do
  it 'creates and saves custom section cut' do
    visit bim_project_ifc_viewer_path(project, ifc_model)

    click_button 'Section Tools'
    click_button 'Create Section Box'

    # Interact with section box handles
    find('.section-box-handle').drag_to(find('.viewer-canvas'))

    click_button 'Save Section'
    fill_in 'Name', with: 'Floor 1 Plan'
    click_button 'Save'

    expect(page).to have_content('Section saved successfully')

    # Reload and verify section persists
    visit current_path
    select 'Floor 1 Plan', from: 'Saved Sections'
    expect(page).to have_selector('.section-box.active')
  end

  it 'measures distance between elements', :js do
    visit bim_project_ifc_viewer_path(project, ifc_model)

    click_button 'Measurements'
    click_button 'Distance'

    # Click two points in viewer
    find('.viewer-canvas').click(x: 100, y: 100)
    find('.viewer-canvas').click(x: 300, y: 100)

    expect(page).to have_content('12.5 m')

    click_button 'Save Measurement'
    expect(page).to have_selector('.measurement-label', text: '12.5 m')
  end

  it 'switches navigation modes' do
    visit bim_project_ifc_viewer_path(project, ifc_model)

    click_button 'Navigation'
    click_button 'Walk Mode'

    expect(page).to have_selector('.navigation-mode.walk.active')
    # Test WASD controls (may require custom test driver)
  end
end
```

---

## Demo Deliverables

### Minimal Viable Demo
1. **Section Cut Tool**: Create interactive section box with draggable handles
2. **Measurement Suite**: Distance, area, angle measurements with labels
3. **Saved Views**: Create and restore named camera positions
4. **Navigation Modes**: Switch between orbit, walk, fly modes
5. **Rendering Quality**: Toggle shadows, AO, edge rendering

### Demo Scenario
```
User loads "Building_A.ifc" in viewer
    ↓
Enables "High Quality" rendering
  → Shadows appear, edges highlighted
    ↓
Creates section box to view Floor 1
  → Drags handles to adjust cut
  → Saves as "Floor 1 Plan"
    ↓
Measures column spacing
  → Clicks two columns: "5.5 m"
  → Saves measurement
    ↓
Switches to Walk Mode
  → Navigates through building first-person
    ↓
Saves current camera position as "Lobby Entrance"
    ↓
Exports measurement report to CSV
```

---

## Dependencies & Risks

### Upstream Dependencies
- **Slice 1 (IFC Upload)**: Requires optimized XKT files with metadata

### Downstream Dependencies
- **Slice 4 (Clash Detection)**: Uses section cuts and element selection
- **Slice 6 (Model Comparison)**: Uses rendering overlays
- **Slice 7 (Collaboration)**: Integrates annotations with BCF comments

### Technical Risks

1. **xeokit Limitations**: May need to fork/extend xeokit for advanced features
   - **Mitigation**: Contribute upstream or maintain fork

2. **Performance**: Shadows/AO may impact frame rate on large models
   - **Mitigation**: Quality presets, progressive enhancement

3. **Browser Compatibility**: WebGL 2.0 required for advanced rendering
   - **Mitigation**: Graceful degradation to WebGL 1.0

4. **Touch Devices**: Measurement tools may be difficult on tablets
   - **Mitigation**: Touch-optimized UI, larger hit targets

### Licensing Risks
- xeokit-sdk: GPL 3.0 + Commercial dual license
- For Community Edition: GPL 3.0 is compatible ✅
- No licensing conflicts

---

## Success Criteria

### Functional Requirements
- ✅ Section box with 6-plane clipping and interactive handles
- ✅ Distance, area, angle, elevation measurements
- ✅ Saved camera positions and predefined views
- ✅ Walk/fly navigation modes
- ✅ Rendering quality presets (shadows, AO, edges)
- ✅ Persistent measurements and annotations
- ✅ Export measurements to CSV

### Non-Functional Requirements
- ✅ Maintain >30 FPS on models with 50k objects (medium quality)
- ✅ Section cuts update in real-time (<100ms latency)
- ✅ Measurements accurate to ±1mm
- ✅ Saved views restore in <1 second

### Quality Gates
- ✅ >85% unit test coverage for viewer managers
- ✅ E2E tests for all measurement types
- ✅ Cross-browser testing (Chrome, Firefox, Edge)
- ✅ Accessibility: Keyboard navigation for all tools

---

## Implementation Phases

### Phase 1: Section Management (Week 1)
- SectionManager service
- Section box with interactive gizmos
- Section plane creation
- Save/load configurations

### Phase 2: Measurement Suite (Week 2)
- MeasurementManager service
- Distance, area, angle, elevation plugins
- Persistent measurement storage
- CSV export

### Phase 3: Navigation & Views (Week 3)
- NavigationManager service
- Walk/fly modes with collision
- Saved views and predefined views
- Camera animation paths (optional)

### Phase 4: Rendering Quality (Week 4)
- RenderingManager service
- Shadow mapping
- Ambient occlusion
- Quality presets
- Performance profiling

---

## Next Actions

1. **Validate Dependencies:**
   - ✅ Slice 1 (IFC Upload) complete
   - ✅ XKT files and metadata available

2. **Switch to Action Mode** after:
   - Confirming xeokit capabilities
   - Testing section box prototype
   - Validating measurement accuracy

3. **Action Mode Tasks:**
   - Implement SectionManager (TDD)
   - Implement MeasurementManager (TDD)
   - Build UI components for tools
   - Create demo scenario

---

**Deliberation Complete** ✅
**Ready for Action Mode** (after Slice 1 complete)
**Estimated LOC:** ~2,500 (TypeScript: 2,200, Ruby: 300)
**Estimated Duration:** 4 weeks
**Risk Level:** Medium (requires xeokit expertise)
