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
    <div className="absolute left-4 top-4 z-10 w-72 rounded-lg border border-gray-200 bg-white p-4 shadow-lg">
      <h3 className="mb-3 text-sm font-bold uppercase tracking-wider text-gray-700">
        Filtros do Mapa
      </h3>

      <div className="mb-4">
        <input
          type="text"
          placeholder="Buscar bloco..."
          className="w-full rounded border border-gray-300 px-3 py-2 text-sm transition-colors focus:border-blue-500 focus:outline-none"
          value={filters.searchTerm}
          onChange={(e) => setFilters((prev) => ({ ...prev, searchTerm: e.target.value }))}
        />
      </div>

      <div className="space-y-2 text-sm text-gray-700">
        <label className="flex cursor-pointer items-center space-x-2 rounded p-1 hover:bg-gray-50">
          <input type="checkbox" checked={filters.showOB} onChange={() => toggleFilter("showOB")} />
          <span>OB</span>
        </label>
        <label className="flex cursor-pointer items-center space-x-2 rounded p-1 hover:bg-gray-50">
          <input type="checkbox" checked={filters.showFB} onChange={() => toggleFilter("showFB")} />
          <span>FB</span>
        </label>
        <label className="flex cursor-pointer items-center space-x-2 rounded p-1 hover:bg-gray-50">
          <input type="checkbox" checked={filters.showFC} onChange={() => toggleFilter("showFC")} />
          <span>FC</span>
        </label>
        <label className="flex cursor-pointer items-center space-x-2 rounded p-1 hover:bg-gray-50">
          <input type="checkbox" checked={filters.showDB} onChange={() => toggleFilter("showDB")} />
          <span>DB</span>
        </label>
        <label className="flex cursor-pointer items-center space-x-2 rounded p-1 hover:bg-gray-50">
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

