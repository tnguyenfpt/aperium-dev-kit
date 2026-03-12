# Prompt: New React Component

## Purpose
Create a React component with strict TypeScript, hooks-only patterns, and a co-located Vitest test file following Aperium frontend conventions.

## Context
See AGENTS.md for project conventions and forbidden patterns.
All components must be functional (no class components), use strict TypeScript with no `any` types, and follow one-component-per-file with co-located tests. State management uses Zustand for client state and TanStack Query for server state. No `localStorage` usage.

Specs live in `specs/APER-123/` and are committed to git alongside code.

## Prompt
```
Create a React component following Aperium frontend conventions.

Requirements:
- Component name: {COMPONENT_NAME}
- Props interface: {PROPS}
- Purpose: {PURPOSE}
- Functional component with hooks only (no class components)
- Strict TypeScript — no `any` types, use `unknown` with type narrowing
- Use Zustand for local/shared client state if needed
- Use TanStack Query for any server data fetching
- One component per file with a co-located test file
- Test file uses Vitest with React Testing Library
- No `localStorage`, no class components, no `any` types

Follow the TypeScript/React conventions in AGENTS.md.
Return the component file and its test file.
```

## Expected Output
- A functional component file with a typed props interface
- Hooks for state and side effects (no lifecycle methods)
- Zustand store integration where client state is shared
- TanStack Query hooks for server data fetching
- Strict TypeScript with explicit return types and no `any`
- A co-located `.test.tsx` file with meaningful test cases using Vitest and React Testing Library

## Example

**Filled-in prompt:**
> Component name: **AnalyticsWidget**
> Props: `{ dashboardId: string; refreshInterval?: number }`
> Purpose: Display a summary card of key analytics metrics for a given dashboard, auto-refreshing on an interval.

**Snippet of expected output:**

```tsx
// components/AnalyticsWidget/AnalyticsWidget.tsx
import { useQuery } from "@tanstack/react-query";
import { useDashboardStore } from "../../stores/dashboardStore";
import { fetchDashboardMetrics } from "../../api/dashboards";
import type { DashboardMetrics } from "../../types/dashboards";

interface AnalyticsWidgetProps {
  dashboardId: string;
  refreshInterval?: number;
}

const DEFAULT_REFRESH_MS = 30_000;

export function AnalyticsWidget({
  dashboardId,
  refreshInterval = DEFAULT_REFRESH_MS,
}: AnalyticsWidgetProps): React.ReactElement {
  const selectedRange = useDashboardStore((state) => state.dateRange);

  const { data, isLoading, isError } = useQuery<DashboardMetrics>({
    queryKey: ["dashboard-metrics", dashboardId, selectedRange],
    queryFn: () => fetchDashboardMetrics(dashboardId, selectedRange),
    refetchInterval: refreshInterval,
  });

  if (isLoading) {
    return <div role="status" aria-label="Loading metrics">Loading...</div>;
  }

  if (isError || !data) {
    return <div role="alert">Failed to load analytics data.</div>;
  }

  return (
    <section aria-labelledby={`widget-title-${dashboardId}`}>
      <h3 id={`widget-title-${dashboardId}`}>Analytics Summary</h3>
      <dl>
        <dt>Active Users</dt>
        <dd>{data.activeUsers}</dd>
        <dt>Avg Response Time</dt>
        <dd>{data.avgResponseMs} ms</dd>
        <dt>Error Rate</dt>
        <dd>{data.errorRate.toFixed(2)}%</dd>
      </dl>
    </section>
  );
}
```

```tsx
// components/AnalyticsWidget/AnalyticsWidget.test.tsx
import { describe, it, expect, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { AnalyticsWidget } from "./AnalyticsWidget";

vi.mock("../../api/dashboards", () => ({
  fetchDashboardMetrics: vi.fn().mockResolvedValue({
    activeUsers: 142,
    avgResponseMs: 230,
    errorRate: 0.45,
  }),
}));

function renderWithProviders(ui: React.ReactElement): void {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>);
}

describe("AnalyticsWidget", () => {
  it("renders metrics after loading", async () => {
    renderWithProviders(<AnalyticsWidget dashboardId="dash-001" />);
    expect(await screen.findByText("142")).toBeInTheDocument();
    expect(screen.getByText("230 ms")).toBeInTheDocument();
  });

  it("shows loading state initially", () => {
    renderWithProviders(<AnalyticsWidget dashboardId="dash-001" />);
    expect(screen.getByRole("status")).toBeInTheDocument();
  });
});
```
