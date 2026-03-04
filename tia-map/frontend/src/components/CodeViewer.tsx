import Editor from "@monaco-editor/react";

interface CodeViewerProps {
  code: string;
  language?: string;
  theme?: "vs-dark" | "light";
  readOnly?: boolean;
}

export default function CodeViewer({
  code,
  language = "pascal",
  theme = "vs-dark",
  readOnly = true,
}: CodeViewerProps) {
  return (
    <div className="h-full w-full overflow-hidden rounded-md border border-gray-700 shadow-lg">
      <div className="flex items-center justify-between border-b border-gray-700 bg-gray-800 px-4 py-2 text-sm font-mono text-gray-300">
        <span>Visualizador SCL</span>
        <span className="text-xs opacity-70">{language.toUpperCase()}</span>
      </div>
      <Editor
        height="100%"
        defaultLanguage={language}
        value={code}
        theme={theme}
        options={{
          readOnly,
          minimap: { enabled: true },
          scrollBeyondLastLine: false,
          fontSize: 14,
          fontFamily: "'Consolas', 'Monaco', 'Courier New', monospace",
          automaticLayout: true,
        }}
        loading={
          <div className="flex h-full items-center justify-center text-gray-400">
            Carregando editor...
          </div>
        }
      />
    </div>
  );
}

