import CodeViewer from "./CodeViewer";
import type { GraphNode } from "../types/graph";

interface DetailPanelProps {
  selectedNode: GraphNode | null;
  onClose: () => void;
}

function typeClass(blockType: string): string {
  switch (blockType) {
    case "OB":
      return "bg-purple-100 text-purple-800 border-purple-200";
    case "FB":
      return "bg-blue-100 text-blue-800 border-blue-200";
    case "FC":
      return "bg-green-100 text-green-800 border-green-200";
    case "DB":
      return "bg-gray-100 text-gray-800 border-gray-200";
    default:
      return "bg-zinc-100 text-zinc-800 border-zinc-200";
  }
}

export default function DetailPanel({ selectedNode, onClose }: DetailPanelProps) {
  if (!selectedNode) return null;

  const data = selectedNode.data;

  return (
    <div className="fixed right-0 top-0 z-20 flex h-full w-1/3 min-w-[500px] flex-col border-l border-gray-200 bg-white shadow-2xl">
      <div className="flex items-start justify-between border-b border-gray-200 bg-gray-50 p-4">
        <div>
          <div className={`mb-2 inline-block rounded border px-2 py-0.5 text-xs font-bold ${typeClass(data.blockType)}`}>
            {data.blockType}
          </div>
          <h2 className="break-all text-xl font-bold text-gray-800">{data.label}</h2>
          {data.comment ? <p className="mt-1 text-sm text-gray-500">{data.comment}</p> : null}
        </div>
        <button
          onClick={onClose}
          className="rounded p-1 text-xl leading-none text-gray-400 hover:bg-gray-200 hover:text-gray-600"
        >
          &times;
        </button>
      </div>

      <div className="grid grid-cols-2 gap-4 border-b border-gray-200 bg-white p-4 text-sm">
        <div>
          <span className="block text-xs uppercase tracking-wide text-gray-500">Autor</span>
          <span className="font-medium text-gray-800">{data.author ?? "-"}</span>
        </div>
        <div>
          <span className="block text-xs uppercase tracking-wide text-gray-500">Versao</span>
          <span className="font-medium text-gray-800">{data.version ?? "0.0"}</span>
        </div>
      </div>

      <div className="flex flex-1 flex-col overflow-hidden bg-gray-50 p-4">
        <h3 className="mb-2 text-sm font-bold uppercase tracking-wide text-gray-700">Logica SCL</h3>
        <div className="flex-1 overflow-hidden rounded border border-gray-300 shadow-inner">
          {data.code ? (
            <CodeViewer code={data.code} readOnly />
          ) : (
            <div className="flex h-full items-center justify-center bg-gray-100 italic text-gray-400">
              Codigo nao disponivel.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

