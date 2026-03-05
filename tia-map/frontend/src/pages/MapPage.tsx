import { useCallback, useEffect, useMemo, useState } from "react";
import {
  Background,
  Controls,
  ReactFlow,
  useEdgesState,
  useNodesState,
  type NodeMouseHandler,
} from "@xyflow/react";

import DetailPanel from "../components/DetailPanel";
import FilterPanel, { type FilterState } from "../components/FilterPanel";
import type { GraphEdge, GraphNode, GraphPayload } from "../types/graph";

const API_BASE = "http://localhost:8001";

export default function MapPage() {
  const [nodes, setNodes, onNodesChange] = useNodesState<GraphNode>([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState<GraphEdge>([]);
  const [originalNodes, setOriginalNodes] = useState<GraphNode[]>([]);
  const [selectedNode, setSelectedNode] = useState<GraphNode | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);

  const [filters, setFilters] = useState<FilterState>({
    searchTerm: "",
    showOB: true,
    showFB: true,
    showFC: true,
    showDB: true,
    showExternal: true,
  });

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await fetch(`${API_BASE}/api/graph/demo`);
        if (!response.ok) {
          throw new Error(`Falha HTTP ${response.status}`);
        }
        const data: GraphPayload = await response.json();
        setNodes((data.nodes ?? []) as GraphNode[]);
        setOriginalNodes((data.nodes ?? []) as GraphNode[]);
        setEdges((data.edges ?? []) as GraphEdge[]);
        setLoadError(null);
      } catch (error) {
        console.error("Erro ao carregar grafo:", error);
        setLoadError(String(error));
      }
    };

    fetchData();
  }, [setEdges, setNodes]);

  const filteredNodes = useMemo(() => {
    return originalNodes.filter((node) => {
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
  }, [filters, originalNodes]);

  const visibleNodeIds = useMemo(() => new Set(filteredNodes.map((node) => node.id)), [filteredNodes]);

  const filteredEdges = useMemo(() => {
    return edges.filter((edge) => visibleNodeIds.has(edge.source) && visibleNodeIds.has(edge.target));
  }, [edges, visibleNodeIds]);

  const onNodeClick = useCallback<NodeMouseHandler<GraphNode>>((_, node) => {
    setSelectedNode(node);
  }, []);

  const onPaneClick = useCallback(() => {
    setSelectedNode(null);
  }, []);

  return (
    <div className="tm-page">
      <div className="tm-canvas">
        <FilterPanel onFilterChange={setFilters} />
        {loadError ? (
          <div className="tm-banner error">
            Erro ao conectar no backend (porta 8001). Verifique o launcher do TIA Map.
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

        <DetailPanel selectedNode={selectedNode} onClose={() => setSelectedNode(null)} />
      </div>
    </div>
  );
}
