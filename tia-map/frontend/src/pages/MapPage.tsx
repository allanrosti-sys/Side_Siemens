import { useCallback, useEffect, useMemo, useState } from "react";
import {
  applyEdgeChanges,
  applyNodeChanges,
  Background,
  Controls,
  ReactFlow,
  type EdgeChange,
  type NodeChange,
  type NodeMouseHandler,
} from "@xyflow/react";

import DetailPanel from "../components/DetailPanel";
import FilterPanel, { type FilterState } from "../components/FilterPanel";
import type { GraphEdge, GraphNode, GraphPayload, VendorType } from "../types/graph";

const API_BASE = "http://localhost:8021";

const buildColumnMap = (vendor: VendorType): Record<string, number> => {
  if (vendor === "rockwell") {
    return { Task: 0, MainProgram: 1, Routine: 2, AOI: 3, TAG: 4, EXTERNAL: 5 };
  }
  return { OB: 0, FB: 1, FC: 2, DB: 3, EXTERNAL: 4 };
};

export default function MapPage() {
  const [allNodes, setAllNodes] = useState<GraphNode[]>([]);
  const [allEdges, setAllEdges] = useState<GraphEdge[]>([]);
  const [selectedNodeId, setSelectedNodeId] = useState<string | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [activeVendor, setActiveVendor] = useState<VendorType>("auto");

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

  const applyInitialLayout = useCallback((nodes: GraphNode[], vendor: VendorType): GraphNode[] => {
    const hasAnyPosition = nodes.some((node) => (node.position?.x ?? 0) !== 0 || (node.position?.y ?? 0) !== 0);
    if (hasAnyPosition) {
      return nodes;
    }

    const columns = buildColumnMap(vendor);
    const rowByType = new Map<string, number>();

    return [...nodes]
      .sort((a, b) => String(a.data.label).localeCompare(String(b.data.label)))
      .map((node) => {
        const type = String(node.data.blockType ?? "EXTERNAL");
        const column = columns[type] ?? Object.keys(columns).length;
        const currentRow = rowByType.get(type) ?? 0;
        rowByType.set(type, currentRow + 1);

        return {
          ...node,
          position: {
            x: 260 + column * 340,
            y: 120 + currentRow * 130,
          },
        };
      });
  }, []);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await fetch(`${API_BASE}/api/graph/demo?vendor=${filters.vendor}`);
        if (!response.ok) {
          throw new Error(`Falha HTTP ${response.status}`);
        }
        const data: GraphPayload = await response.json();
        const resolvedVendor = (data.vendor ?? filters.vendor ?? "auto") as VendorType;
        const initialNodes = applyInitialLayout((data.nodes ?? []) as GraphNode[], resolvedVendor);
        setAllNodes(initialNodes);
        setAllEdges((data.edges ?? []) as GraphEdge[]);
        setActiveVendor(resolvedVendor);
        setLoadError(null);
      } catch (error) {
        console.error("Erro ao carregar grafo:", error);
        setLoadError(String(error));
      }
    };

    fetchData();
  }, [applyInitialLayout, filters.vendor]);

  const filteredNodes = useMemo(() => {
    return allNodes.filter((node) => {
      const data = node.data;
      const type = String(data.blockType ?? "");

      if (filters.searchTerm.trim()) {
        const term = filters.searchTerm.toLowerCase().trim();
        const label = String(data.label ?? "").toLowerCase();
        if (!label.includes(term)) return false;
      }

      if (type === "OB" && !filters.showOB) return false;
      if (type === "FB" && !filters.showFB) return false;
      if (type === "FC" && !filters.showFC) return false;
      if (type === "DB" && !filters.showDB) return false;
      if (type === "Task" && !filters.showTask) return false;
      if (type === "MainProgram" && !filters.showMainProgram) return false;
      if (type === "Routine" && !filters.showRoutine) return false;
      if (type === "AOI" && !filters.showAOI) return false;
      if (type === "TAG" && !filters.showTag) return false;
      if (type === "EXTERNAL" && !filters.showExternal) return false;

      return true;
    });
  }, [allNodes, filters]);

  const visibleNodeIds = useMemo(() => new Set(filteredNodes.map((node) => node.id)), [filteredNodes]);

  const filteredEdges = useMemo(() => {
    return allEdges.filter((edge) => visibleNodeIds.has(edge.source) && visibleNodeIds.has(edge.target));
  }, [allEdges, visibleNodeIds]);

  const selectedNode = useMemo(
    () => (selectedNodeId ? allNodes.find((node) => node.id === selectedNodeId) ?? null : null),
    [allNodes, selectedNodeId],
  );

  const onNodeClick = useCallback<NodeMouseHandler<GraphNode>>((_, node) => {
    setSelectedNodeId(node.id);
  }, []);

  const onPaneClick = useCallback(() => {
    setSelectedNodeId(null);
  }, []);

  const onNodesChange = useCallback((changes: NodeChange<GraphNode>[]) => {
    setAllNodes((current) => applyNodeChanges(changes, current));
  }, []);

  const onEdgesChange = useCallback((changes: EdgeChange<GraphEdge>[]) => {
    setAllEdges((current) => applyEdgeChanges(changes, current));
  }, []);

  return (
    <div className="tm-page">
      <div className="tm-canvas">
        <FilterPanel onFilterChange={setFilters} />
        {loadError ? (
          <div className="tm-banner error">
            Erro ao conectar no backend (porta 8021). Verifique o launcher do Puchta PLC Insight.
          </div>
        ) : (
          <div className="tm-banner">
            Vendor: {activeVendor} | Elementos visiveis: {filteredNodes.length} | Conexoes: {filteredEdges.length}
          </div>
        )}

        <ReactFlow
          nodes={filteredNodes}
          edges={filteredEdges}
          onNodesChange={onNodesChange}
          onEdgesChange={onEdgesChange}
          onNodeClick={onNodeClick}
          onPaneClick={onPaneClick}
          fitView
          attributionPosition="bottom-right"
        >
          <Background color="#ccc" gap={16} />
          <Controls />
        </ReactFlow>

        <DetailPanel selectedNode={selectedNode} onClose={() => setSelectedNodeId(null)} />
      </div>
    </div>
  );
}
