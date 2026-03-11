import { useEffect, useState } from "react";

import type { VendorType } from "../types/graph";

export interface FilterState {
  searchTerm: string;
  vendor: VendorType;
  showOB: boolean;
  showFB: boolean;
  showFC: boolean;
  showDB: boolean;
  showExternal: boolean;
  showTask: boolean;
  showMainProgram: boolean;
  showRoutine: boolean;
  showAOI: boolean;
  showTag: boolean;
}

interface FilterPanelProps {
  onFilterChange: (filters: FilterState) => void;
}

export default function FilterPanel({ onFilterChange }: FilterPanelProps) {
  const [filters, setFilters] = useState<FilterState>({
    searchTerm: "",
    vendor: "auto",
    showOB: true,
    showFB: true,
    showFC: true,
    showDB: true,
    showExternal: true,
    showTask: true,
    showMainProgram: true,
    showRoutine: true,
    showAOI: true,
    showTag: true,
  });

  useEffect(() => {
    onFilterChange(filters);
  }, [filters, onFilterChange]);

  const toggleFilter = (key: keyof Omit<FilterState, "searchTerm" | "vendor">) => {
    setFilters((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  const isRockwell = filters.vendor === "rockwell";

  return (
    <div className="tm-panel">
      <h3 className="tm-title">Filtros do Mapa</h3>
      <p className="tm-subtitle">Puchta PLC Insight | Refine por vendor, nome e tipo de rotina.</p>

      <select
        className="tm-field"
        value={filters.vendor}
        onChange={(e) => setFilters((prev) => ({ ...prev, vendor: e.target.value as VendorType }))}
      >
        <option value="auto">Vendor automatico</option>
        <option value="siemens">Siemens</option>
        <option value="rockwell">Rockwell</option>
      </select>

      <input
        type="text"
        placeholder="Buscar elemento..."
        className="tm-field"
        value={filters.searchTerm}
        onChange={(e) => setFilters((prev) => ({ ...prev, searchTerm: e.target.value }))}
      />

      <div className="tm-row">
        {isRockwell ? (
          <>
            <label className="tm-chip">
              <input type="checkbox" checked={filters.showTask} onChange={() => toggleFilter("showTask")} />
              <span>Task</span>
            </label>
            <label className="tm-chip">
              <input type="checkbox" checked={filters.showMainProgram} onChange={() => toggleFilter("showMainProgram")} />
              <span>MainProgram</span>
            </label>
            <label className="tm-chip">
              <input type="checkbox" checked={filters.showRoutine} onChange={() => toggleFilter("showRoutine")} />
              <span>Routine</span>
            </label>
            <label className="tm-chip">
              <input type="checkbox" checked={filters.showAOI} onChange={() => toggleFilter("showAOI")} />
              <span>AOI</span>
            </label>
            <label className="tm-chip">
              <input type="checkbox" checked={filters.showTag} onChange={() => toggleFilter("showTag")} />
              <span>Tags/Data</span>
            </label>
          </>
        ) : (
          <>
            <label className="tm-chip">
              <input type="checkbox" checked={filters.showOB} onChange={() => toggleFilter("showOB")} />
              <span>OB</span>
            </label>
            <label className="tm-chip">
              <input type="checkbox" checked={filters.showFB} onChange={() => toggleFilter("showFB")} />
              <span>FB</span>
            </label>
            <label className="tm-chip">
              <input type="checkbox" checked={filters.showFC} onChange={() => toggleFilter("showFC")} />
              <span>FC</span>
            </label>
            <label className="tm-chip">
              <input type="checkbox" checked={filters.showDB} onChange={() => toggleFilter("showDB")} />
              <span>DB</span>
            </label>
          </>
        )}
        <label className="tm-chip">
          <input type="checkbox" checked={filters.showExternal} onChange={() => toggleFilter("showExternal")} />
          <span>Externos</span>
        </label>
      </div>
    </div>
  );
}
