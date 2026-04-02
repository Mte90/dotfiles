# B2B Data-Dense UX Patterns

Reference models: Stripe Dashboard, Mixpanel, Datadog, Looker, Retool, Airtable, HubSpot

These products present large amounts of data and complex operations to users who need to analyze, monitor, configure, and act. The design challenge is managing complexity without overwhelming — making dense information scannable and actionable.

## Contents

- [Core Philosophy](#core-philosophy)
- [Interaction Patterns](#interaction-patterns)
- [Layout Patterns](#layout-patterns)
- [Data Visualization Principles](#data-visualization-principles)
- [Permissions and Multi-Tenancy](#permissions-and-multi-tenancy)
- [Performance at Scale](#performance-at-scale)

---

## Core Philosophy

**Data is the UI.** In data-dense apps, the content IS the interface. Chrome and controls exist to serve the data, not the other way around. Minimize interface elements that are not data.

**Scanability over readability.** Users are not reading paragraphs. They are scanning numbers, status indicators, and trends. Design for pattern recognition.

**Configure once, monitor always.** B2B users spend time setting up dashboards, alerts, and views — then live in those configurations. Make setup powerful and day-to-day monitoring effortless.

---

## Interaction Patterns

### Filtering Systems

B2B apps live and die by their filtering:

**Filter bar pattern (Stripe / Mixpanel style):**
- Horizontal bar above content with filter chips
- Click chip to open dropdown with options
- Multiple filters combine with AND logic (show OR as explicit option)
- Active filters visually distinct (filled vs outlined chips)
- "Clear all" always visible when any filter is active
- Filter count badge showing how many are active

**Saved views:**
- Let users save filter + sort + column configurations as named views
- Quick switch between views via tabs or dropdown
- Mark one as "default"
- Share views with team members

**Advanced query builder:**
- For complex filtering needs, offer a structured query builder
- Visual: condition rows with field / operator / value dropdowns
- Group conditions with AND/OR
- Allow nesting (groups within groups) for complex queries
- Show human-readable summary: "Status is Active AND Created after Jan 1"

### Data Tables (Advanced)

B2B tables go far beyond basic rendering:

**Column management:**
- Show/hide columns via a column picker
- Drag to reorder columns
- Resize columns by dragging borders
- Pin columns (freeze left/right)
- Save column configuration per view

**Row interactions:**
- Single-click to select / view detail in side panel
- Double-click or Enter to edit inline
- Checkbox column for batch selection
- Shift+click for range selection
- Right-click context menu with row actions

**Cell rendering:**
- Type-aware rendering: dates formatted, numbers aligned right, statuses as badges
- Truncate with tooltip on hover for long values
- Editable cells show edit affordance on hover (pencil icon or subtle border)
- Copy cell value on click (with tiny confirmation animation)

**Aggregation row:**
- Sticky bottom row showing sum, average, count for numeric columns
- Clearly styled as different from data rows

### Dashboard Composition

**Grid-based layouts:**
- Dashboards as configurable grids of widgets
- Drag and drop to rearrange
- Resize widgets by dragging corners
- Standard widget sizes: 1x1 (KPI), 2x1 (chart), 2x2 (table), full-width

**Widget types:**
| Widget | Use for | Design notes |
|--------|---------|-------------|
| **KPI card** | Single metric with trend | Big number, small label, trend arrow/sparkline |
| **Line chart** | Trends over time | Brush to zoom, hover for tooltip, click point for detail |
| **Bar chart** | Comparisons across categories | Horizontal for long labels, vertical for time series |
| **Table widget** | Top N items or recent activity | Compact, 5-10 rows, "View all" link |
| **Donut/pie** | Part of whole (use sparingly) | Max 5 segments, "Other" bucket, never 3D |
| **Heatmap** | Density or correlation | Clear color legend, hover for values |

**Time range selector:**
- Global time range that applies to all widgets
- Presets: Last 24h, 7d, 30d, 90d, YTD, Custom
- Custom range picker with start/end datetime
- Comparison mode: "vs previous period" toggle
- Auto-refresh toggle for real-time dashboards

### Configuration and Settings

B2B products have complex configuration. Organize it:

**Settings architecture:**
```
Settings
├── Profile & Account
├── Team / Organization
│   ├── Members & Roles
│   ├── Billing
│   └── Integrations
├── Product Configuration
│   ├── [Feature-specific settings]
│   └── [Feature-specific settings]
├── Notifications
└── API & Developer
```

- Use sidebar navigation within settings (not tabs — too many sections)
- Save on change (auto-save) with "Saved" indicator, not a global Submit button
- Show what requires admin permissions
- Indicate which settings affect the whole team vs personal

---

## Layout Patterns

### Full-Width Data Layout

```
┌─────────────────────────────────────────────┐
│ Top bar: Logo │ Search │ Notifications │ User│
├──────────┬──────────────────────────────────┤
│ Sidebar  │ Page Header                      │
│ (56px    │ Title │ Time range │ Actions     │
│ icon-only│──────────────────────────────────│
│ or 200px │                                  │
│ expanded)│ Filter bar                       │
│          │──────────────────────────────────│
│          │                                  │
│          │ Main content                     │
│          │ (table, dashboard, detail view)  │
│          │                                  │
└──────────┴──────────────────────────────────┘
```

- Sidebar: collapsible between icon-only (56px) and expanded (200px)
- Main content uses full remaining width — data needs horizontal space
- Filter bar sticky under page header during scroll
- Table headers sticky during scroll

### Master-Detail for Records

When users need to view and edit individual records (customers, events, issues):

```
┌──────────┬────────────────────┬──────────────┐
│ Sidebar  │ Record List        │ Record Detail│
│          │                    │              │
│          │ Search + Filter    │ Tabs:        │
│          │ ──────────────     │ Overview     │
│          │ Record 1           │ Activity     │
│          │ Record 2  ←active  │ Settings     │
│          │ Record 3           │              │
│          │ Record 4           │ [Form fields │
│          │                    │  and data]   │
└──────────┴────────────────────┴──────────────┘
```

---

## Data Visualization Principles

### Chart Design

- **Title every chart** with what it shows, not what it is ("Revenue by Region" not "Bar Chart")
- **Label axes** clearly with units
- **Start Y-axis at zero** for bar charts. Line charts may break this rule if the range is small relative to the values
- **Limit colors**: 5-6 max in a single chart. Use a consistent color palette across the product
- **Interactive**: Hover for tooltips with exact values. Click to drill down when possible.
- **Responsive**: Charts should resize gracefully. At small sizes, reduce labels and show fewer data points.

### Number Formatting

- **Abbreviate large numbers**: 1,234,567 → 1.2M. Show full number on hover.
- **Align numbers right** in tables
- **Use consistent decimal places** within a column
- **Show comparison**: +12% (green) or -5% (red) vs previous period
- **Currency**: Show currency symbol, respect locale formatting
- **Percentages**: 1 decimal place max unless precision matters

### Status and Health Indicators

Consistent status system across the product:

| Status | Color | Shape | Use |
|--------|-------|-------|-----|
| Healthy/Active | Green | Filled dot | Systems running, features enabled |
| Warning | Yellow/Amber | Filled dot | Approaching limits, degraded |
| Error/Critical | Red | Filled dot | Down, failed, requires action |
| Inactive/Paused | Gray | Outlined dot | Disabled, not running |
| Processing | Blue | Animated dot/spinner | In progress, deploying |

Keep the system simple. More than 5 statuses causes confusion.

---

## Permissions and Multi-Tenancy

B2B apps serve teams. Design for this:

- **Show what you cannot do**: Gray out actions the user lacks permission for. Add tooltip: "Requires Admin role." Do not hide them entirely — users need to know the feature exists.
- **Team context**: Make it obvious which team/org the user is operating in. Show it in the top bar.
- **Audit trail**: Log who changed what and when. Show this in record history or activity feeds.
- **Role indicators**: Subtle badges showing "Admin", "Editor", "Viewer" next to team members.

---

## Performance at Scale

B2B products handle large data sets. Plan for it:

- **Virtualized lists and tables**: Render only visible rows. This is non-negotiable for 100+ rows.
- **Server-side pagination, sort, filter**: Do not load 10,000 records and filter in JavaScript.
- **Debounce search**: Wait 200-300ms after typing stops before querying.
- **Cache aggressively**: Dashboard data with a "Last updated: 2 min ago" indicator and manual refresh button.
- **Progressive loading**: Show the page layout immediately, fill in widgets as data arrives. Each widget loads independently.
