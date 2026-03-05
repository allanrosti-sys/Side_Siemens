import { useEffect, useState } from "react";

export interface FilterState {
  searchTerm: string;
  showOB: boolean;
  showFB: boolean;
  showFC: boolean;
  showDB: boolean;
  showExternal: boolean;
}

interface FilterPanelProps {
  onFilterChange: (filters: FilterState) => void;
}

export default function FilterPanel({ onFilterChange }: FilterPanelProps) {
  const [filters, setFilters] = useState<FilterState>({
    searchTerm: "",
    showOB: true,
    showFB: true,
    showFC: true,
    showDB: true,
    showExternal: true,
  });

  useEffect(() => {
    onFilterChange(filters);
  }, [filters, onFilterChange]);

  const toggleFilter = (key: keyof Omit<FilterState, "searchTerm">) => {
    setFilters((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  return (
    <div className="tm-panel">
      <h3 className="tm-title">Filtros do Mapa</h3>
      <p className="tm-subtitle">Refine por nome e tipo de bloco.</p>

      <input
        type="text"
        placeholder="Buscar bloco..."
        className="tm-field"
        value={filters.searchTerm}
        onChange={(e) => setFilters((prev) => ({ ...prev, searchTerm: e.target.value }))}
      />

      <div className="tm-row">
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
        <label className="tm-chip">
          <input
            type="checkbox"
            checked={filters.showExternal}
            onChange={() => toggleFilter("showExternal")}
          />
          <span>Externos</span>
        </label>
      </div>
    </div>
  );
}
