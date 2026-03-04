import type { Edge, Node } from "@xyflow/react";

export type BlockType = "OB" | "FB" | "FC" | "DB" | "EXTERNAL";

export interface GraphNodeData extends Record<string, unknown> {
  label: string;
  blockType: BlockType;
  groupPath?: string;
  color?: string;
  code?: string;
  author?: string;
  version?: string;
  comment?: string;
}

export type GraphNode = Node<GraphNodeData>;

export type GraphEdge = Edge<Record<string, unknown>>;

export interface GraphPayload {
  projectId: string;
  source: string;
  nodes: GraphNode[];
  edges: GraphEdge[];
}
