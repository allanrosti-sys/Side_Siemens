import React, { useState, useEffect } from 'react';

export interface FilterState {
  searchTerm: string;
  showOB: boolean;
  showFB: boolean;
  showFC: boolean;
  showDB: boolean;
}

interface FilterPanelProps {
  onFilterChange: (filters: FilterState) => void;
}

const FilterPanel: React.FC<FilterPanelProps> = ({ onFilterChange }) => {
  const [filters, setFilters] = useState<FilterState>({
    searchTerm: '',
    showOB: true,
    showFB: true,
    showFC: true,
    showDB: true,
  });

  // Notifica o pai sempre que os filtros mudarem
  useEffect(() => {
    onFilterChange(filters);
  }, [filters, onFilterChange]);

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFilters(prev => ({ ...prev, searchTerm: e.target.value }));
  };

  const toggleFilter = (key: keyof Omit<FilterState, 'searchTerm'>) => {
    setFilters(prev => ({ ...prev, [key]: !prev[key] }));
  };

  return (
    <div className="bg-white p-4 rounded-lg shadow-lg border border-gray-200 w-72 absolute top-4 left-4 z-10">
      <h3 className="text-sm font-bold text-gray-700 mb-3 uppercase tracking-wider">Filtros de Visualização</h3>
      
      {/* Busca */}
      <div className="mb-4">
        <input
          type="text"
          placeholder="Buscar bloco (ex: Main)..."
          className="w-full px-3 py-2 text-sm border border-gray-300 rounded focus:outline-none focus:border-blue-500 transition-colors"
          value={filters.searchTerm}
          onChange={handleSearchChange}
        />
      </div>

      {/* Checkboxes */}
      <div className="space-y-2">
        <label className="flex items-center space-x-2 cursor-pointer hover:bg-gray-50 p-1 rounded">
          <input
            type="checkbox"
            className="rounded text-purple-600 focus:ring-purple-500"
            checked={filters.showOB}
            onChange={() => toggleFilter('showOB')}
          />
          <div className="flex items-center">
            <span className="w-3 h-3 rounded-full bg-purple-500 mr-2"></span>
            <span className="text-sm text-gray-700">Organization Blocks (OB)</span>
          </div>
        </label>

        <label className="flex items-center space-x-2 cursor-pointer hover:bg-gray-50 p-1 rounded">
          <input
            type="checkbox"
            className="rounded text-blue-600 focus:ring-blue-500"
            checked={filters.showFB}
            onChange={() => toggleFilter('showFB')}
          />
          <div className="flex items-center">
            <span className="w-3 h-3 rounded-full bg-blue-500 mr-2"></span>
            <span className="text-sm text-gray-700">Function Blocks (FB)</span>
          </div>
        </label>

        <label className="flex items-center space-x-2 cursor-pointer hover:bg-gray-50 p-1 rounded">
          <input
            type="checkbox"
            className="rounded text-green-600 focus:ring-green-500"
            checked={filters.showFC}
            onChange={() => toggleFilter('showFC')}
          />
          <div className="flex items-center">
            <span className="w-3 h-3 rounded-full bg-green-600 mr-2"></span>
            <span className="text-sm text-gray-700">Functions (FC)</span>
          </div>
        </label>

        <label className="flex items-center space-x-2 cursor-pointer hover:bg-gray-50 p-1 rounded">
          <input
            type="checkbox"
            className="rounded text-gray-600 focus:ring-gray-500"
            checked={filters.showDB}
            onChange={() => toggleFilter('showDB')}
          />
          <div className="flex items-center">
            <span className="w-3 h-3 rounded-full bg-gray-500 mr-2"></span>
            <span className="text-sm text-gray-700">Data Blocks (DB)</span>
          </div>
        </label>
      </div>
      
      <div className="mt-4 pt-3 border-t border-gray-100 text-xs text-gray-400 text-center">
        TIA Map v0.1
      </div>
    </div>
  );
};

export default FilterPanel;