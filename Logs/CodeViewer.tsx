import React from 'react';
import Editor, { Monaco } from '@monaco-editor/react';

interface CodeViewerProps {
  code: string;
  language?: string;
  theme?: 'vs-dark' | 'light';
  readOnly?: boolean;
}

const CodeViewer: React.FC<CodeViewerProps> = ({ 
  code, 
  language = 'pascal', // SCL é similar a Pascal
  theme = 'vs-dark',
  readOnly = true 
}) => {

  const handleEditorDidMount = (editor: any, monaco: Monaco) => {
    // Configurações adicionais do Monaco podem ser feitas aqui
    // Ex: registrar linguagem SCL customizada se necessário
  };

  return (
    <div className="h-full w-full border border-gray-700 rounded-md overflow-hidden shadow-lg">
      <div className="bg-gray-800 text-gray-300 px-4 py-2 text-sm font-mono border-b border-gray-700 flex justify-between items-center">
        <span>SCL Viewer</span>
        <span className="text-xs opacity-70">{language.toUpperCase()}</span>
      </div>
      <Editor
        height="100%"
        defaultLanguage={language}
        defaultValue={code}
        value={code}
        theme={theme}
        options={{
          readOnly: readOnly,
          minimap: { enabled: true },
          scrollBeyondLastLine: false,
          fontSize: 14,
          fontFamily: "'Consolas', 'Monaco', 'Courier New', monospace",
          automaticLayout: true,
          renderWhitespace: 'selection',
        }}
        onMount={handleEditorDidMount}
        loading={
          <div className="flex items-center justify-center h-full text-gray-400">
            Carregando editor...
          </div>
        }
      />
    </div>
  );
};

export default CodeViewer;