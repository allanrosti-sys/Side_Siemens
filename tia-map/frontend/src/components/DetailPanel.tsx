import type { CSSProperties } from "react";
import CodeViewer from "./CodeViewer";
import type { GraphNode } from "../types/graph";

interface DetailPanelProps {
  selectedNode: GraphNode | null;
  onClose: () => void;
}

function typeStyle(blockType: string): CSSProperties {
  switch (blockType) {
    case "OB":
      return { background: "#ede9fe", color: "#5b21b6", border: "1px solid #c4b5fd" };
    case "FB":
      return { background: "#e0f2fe", color: "#075985", border: "1px solid #7dd3fc" };
    case "FC":
      return { background: "#dcfce7", color: "#166534", border: "1px solid #86efac" };
    case "DB":
      return { background: "#f1f5f9", color: "#334155", border: "1px solid #cbd5e1" };
    default:
      return { background: "#f8fafc", color: "#334155", border: "1px solid #dbe4ef" };
  }
}

export default function DetailPanel({ selectedNode, onClose }: DetailPanelProps) {
  if (!selectedNode) return null;

  const data = selectedNode.data;

  return (
    <div
      style={{
        position: "fixed",
        right: 0,
        top: 0,
        zIndex: 20,
        width: "34%",
        minWidth: 460,
        height: "100%",
        background: "#fff",
        borderLeft: "1px solid #dbe4ef",
        boxShadow: "-10px 0 24px rgba(15,23,42,.12)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <div style={{ padding: 16, borderBottom: "1px solid #e2e8f0", background: "#f8fafc", display: "flex", justifyContent: "space-between" }}>
        <div>
          <div style={{ display: "inline-block", padding: "2px 10px", borderRadius: 20, fontSize: 12, fontWeight: 700, ...typeStyle(data.blockType) }}>
            {data.blockType}
          </div>
          <h2 style={{ margin: "10px 0 0", fontSize: 20 }}>{data.label}</h2>
          {data.comment ? <p style={{ margin: "8px 0 0", color: "#64748b" }}>{data.comment}</p> : null}
        </div>
        <button onClick={onClose} style={{ border: 0, background: "#e2e8f0", borderRadius: 6, width: 34, height: 34, cursor: "pointer" }}>
          ✕
        </button>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, padding: 16, borderBottom: "1px solid #e2e8f0" }}>
        <div>
          <div style={{ color: "#64748b", fontSize: 11, textTransform: "uppercase" }}>Autor</div>
          <div>{data.author ?? "-"}</div>
        </div>
        <div>
          <div style={{ color: "#64748b", fontSize: 11, textTransform: "uppercase" }}>Versao</div>
          <div>{data.version ?? "0.0"}</div>
        </div>
      </div>

      <div
        style={{
          flex: 1,
          minHeight: 0,
          padding: 16,
          background: "#f8fafc",
          display: "flex",
          flexDirection: "column",
          overflow: "hidden",
        }}
      >
        <div style={{ fontSize: 12, textTransform: "uppercase", color: "#334155", marginBottom: 8, fontWeight: 700, flexShrink: 0 }}>
          Logica SCL
        </div>
        <div style={{ flex: 1, minHeight: 0, border: "1px solid #d1d5db", borderRadius: 8, overflow: "hidden" }}>
          {data.code ? (
            <CodeViewer code={data.code} readOnly />
          ) : (
            <div style={{ height: "100%", display: "flex", alignItems: "center", justifyContent: "center", color: "#94a3b8" }}>
              Codigo nao disponivel.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
