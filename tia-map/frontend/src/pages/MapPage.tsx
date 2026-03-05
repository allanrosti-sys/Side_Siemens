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
import type { GraphEdge, GraphNode, GraphPayload } from "../types/graph";

const API_BASE = "http://localhost:8011";

export default function MapPage() {
  const [allNodes, setAllNodes] = useState<GraphNode[]>([]);
  const [allEdges, setAllEdges] = useState<GraphEdge[]>([]);
  const [selectedNodeId, setSelectedNodeId] = useState<string | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);

  const [filters, setFilters] = useState<FilterState>({
    searchTerm: "",
    showOB: true,
    showFB: true,
    showFC: true,
    showDB: true,
    showExternal: true,
  });

  const applyInitialLayout = useCallback((nodes: GraphNode[]): GraphNode[] => {
    const hasAnyPosition = nodes.some((node) => (node.position?.x ?? 0) !== 0 || (node.position?.y ?? 0) !== 0);
    if (hasAnyPosition) {
      return nodes;
    }

    const columns: Record<string, number> = { OB: 0, FB: 1, FC: 2, DB: 3, EXTERNAL: 4 };
    const rowByType = new Map<string, number>();

    return [...nodes]
      .sort((a, b) => String(a.data.label).localeCompare(String(b.data.label)))
      .map((node) => {
        const type = String(node.data.blockType ?? "EXTERNAL").toUpperCase();
        const column = columns[type] ?? 5;
        const currentRow = rowByType.get(type) ?? 0;
        rowByType.set(type, currentRow + 1);

        return {
          ...node,
          position: {
            x: 260 + column * 360,
            y: 120 + currentRow * 130,
          },
        };
      });
  }, []);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await fetch(`${API_BASE}/api/graph/demo`);
        if (!response.ok) {
          throw new Error(`Falha HTTP ${response.status}`);
        }
        const data: GraphPayload = await response.json();
        const initialNodes = applyInitialLayout((data.nodes ?? []) as GraphNode[]);
        setAllNodes(initialNodes);
        setAllEdges((data.edges ?? []) as GraphEdge[]);
        setLoadError(null);
      } catch (error) {
        console.error("Erro ao carregar grafo:", error);
        setLoadError(String(error));
      }
    };

    fetchData();
  }, [applyInitialLayout]);

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
            Erro ao conectar no backend (porta 8011). Verifique o launcher do TIA Map.
          </div>
        ) : (
          <div className="tm-banner">
            Blocos visiveis: {filteredNodes.length} | Conexoes: {filteredEdges.length}
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
