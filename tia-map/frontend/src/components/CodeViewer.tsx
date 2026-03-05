interface CodeViewerProps {
  code: string;
  language?: string;
  readOnly?: boolean;
}

export default function CodeViewer({
  code,
  language = "scl",
}: CodeViewerProps) {
  return (
    <div
      style={{
        height: "100%",
        width: "100%",
        display: "flex",
        flexDirection: "column",
        overflow: "hidden",
        border: "1px solid #1f2937",
        borderRadius: 8,
        background: "#0b1020",
      }}
    >
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          padding: "8px 12px",
          borderBottom: "1px solid #1f2937",
          color: "#cbd5e1",
          fontFamily: "Consolas, 'Courier New', monospace",
          fontSize: 12,
          flexShrink: 0,
        }}
      >
        <span>Visualizador SCL</span>
        <span style={{ opacity: 0.7 }}>{language.toUpperCase()}</span>
      </div>

      <pre
        style={{
          margin: 0,
          padding: 12,
          flex: 1,
          minHeight: 0,
          overflow: "auto",
          whiteSpace: "pre",
          tabSize: 2,
          color: "#e2e8f0",
          fontFamily: "Consolas, 'Courier New', monospace",
          fontSize: 12,
          lineHeight: 1.4,
        }}
      >
        {code}
      </pre>
    </div>
  );
}
