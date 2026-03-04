import React from 'react';
import CodeViewer from './CodeViewer';

// Interface para os dados do bloco (baseado no que o parser vai gerar)
export interface BlockData {
  id: string;
  name: string;
  type: 'OB' | 'FB' | 'FC' | 'DB';
  number: number;
  author?: string;
  version?: string;
  comment?: string;
  code?: string; // Código SCL
}

interface DetailPanelProps {
  selectedBlock: BlockData | null;
  onClose: () => void;
}

const DetailPanel: React.FC<DetailPanelProps> = ({ selectedBlock, onClose }) => {
  if (!selectedBlock) return null;

  const getTypeColor = (type: string) => {
    switch (type) {
      case 'OB': return 'bg-purple-100 text-purple-800 border-purple-200';
      case 'FB': return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'FC': return 'bg-green-100 text-green-800 border-green-200';
      case 'DB': return 'bg-gray-100 text-gray-800 border-gray-200';
      default: return 'bg-gray-50 text-gray-600 border-gray-200';
    }
  };

  return (
    <div className="fixed right-0 top-0 h-full w-1/3 min-w-[500px] bg-white shadow-2xl border-l border-gray-200 flex flex-col z-20 transform transition-transform duration-300 ease-in-out">
      {/* Header */}
      <div className="p-4 border-b border-gray-200 flex justify-between items-start bg-gray-50">
        <div>
          <div className={`inline-block px-2 py-0.5 rounded text-xs font-bold border mb-2 ${getTypeColor(selectedBlock.type)}`}>
            {selectedBlock.type} {selectedBlock.number}
          </div>
          <h2 className="text-xl font-bold text-gray-800 break-all">{selectedBlock.name}</h2>
          {selectedBlock.comment && (
            <p className="text-sm text-gray-500 mt-1">{selectedBlock.comment}</p>
          )}
        </div>
        <button 
          onClick={onClose}
          className="text-gray-400 hover:text-gray-600 p-1 rounded hover:bg-gray-200 font-bold text-xl leading-none"
        >
          &times;
        </button>
      </div>

      {/* Metadata */}
      <div className="p-4 grid grid-cols-2 gap-4 text-sm border-b border-gray-200 bg-white">
        <div>
          <span className="text-gray-500 block text-xs uppercase tracking-wide">Autor</span>
          <span className="font-medium text-gray-800">{selectedBlock.author || '-'}</span>
        </div>
        <div>
          <span className="text-gray-500 block text-xs uppercase tracking-wide">Versão</span>
          <span className="font-medium text-gray-800">{selectedBlock.version || '0.0'}</span>
        </div>
      </div>

      {/* Code Viewer */}
      <div className="flex-1 overflow-hidden p-4 bg-gray-50 flex flex-col">
        <h3 className="text-sm font-bold text-gray-700 mb-2 uppercase tracking-wide">Lógica SCL</h3>
        <div className="flex-1 border border-gray-300 rounded overflow-hidden shadow-inner">
          {selectedBlock.code ? (
            <CodeViewer code={selectedBlock.code} readOnly={true} />
          ) : (
            <div className="h-full flex items-center justify-center text-gray-400 italic bg-gray-100">
              Código não disponível ou protegido.
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default DetailPanel;