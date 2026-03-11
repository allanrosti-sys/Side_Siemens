import type { Edge, Node } from "@xyflow/react";

export type BlockType = "OB" | "FB" | "FC" | "DB" | "EXTERNAL" | "Task" | "MainProgram" | "Routine" | "AOI" | "TAG";
export type VendorType = "auto" | "siemens" | "rockwell";

export interface GraphNodeData extends Record<string, unknown> {
  label: string;
  blockType: BlockType;
  groupPath?: string;
  color?: string;
  code?: string;
  author?: string;
  version?: string;
  comment?: string;
  vendor?: VendorType;
}

export type GraphNode = Node<GraphNodeData>;
export type GraphEdge = Edge<Record<string, unknown>>;

export interface GraphPayload {
  projectId: string;
  source: string;
  vendor?: VendorType;
  nodes: GraphNode[];
  edges: GraphEdge[];
}
