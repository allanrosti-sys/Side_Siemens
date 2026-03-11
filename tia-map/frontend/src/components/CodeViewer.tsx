interface CodeViewerProps {
  code: string;
  language?: string;
  readOnly?: boolean;
}

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

// Decodifica entidades HTML comuns para melhorar a leitura de SCL.
function decodeHtmlEntities(text: string): string {
  if (!text) return text;
  const textarea = document.createElement("textarea");
  textarea.innerHTML = text;
  return textarea.value;
}

function highlightXml(code: string): string {
  let html = escapeHtml(code);
  html = html.replace(
    /(&lt;\/?)([A-Za-z0-9_.:-]+)([^&]*?)(\/?&gt;)/g,
    '$1<span style="color:#7dd3fc;">$2</span><span style="color:#cbd5e1;">$3</span>$4',
  );
  html = html.replace(
    /([A-Za-z_:][A-Za-z0-9_.:-]*)(=&quot;[^&]*?&quot;)/g,
    '<span style="color:#f59e0b;">$1</span><span style="color:#e2e8f0;">$2</span>',
  );
  return html;
}

function highlightScl(code: string): string {
  let html = escapeHtml(code);
  html = html.replace(
    /\b(IF|THEN|ELSE|ELSIF|END_IF|CASE|OF|END_CASE|FOR|TO|DO|END_FOR|WHILE|END_WHILE|REPEAT|UNTIL|END_REPEAT|VAR|VAR_INPUT|VAR_OUTPUT|VAR_IN_OUT|END_VAR|FUNCTION_BLOCK|FUNCTION|BEGIN|END|TRUE|FALSE)\b/gi,
    '<span style="color:#a78bfa;">$1</span>',
  );
  html = html.replace(
    /\b(INT|DINT|REAL|BOOL|TIME|WORD|DWORD|LREAL|STRING|ARRAY|STRUCT)\b/gi,
    '<span style="color:#22d3ee;">$1</span>',
  );
  html = html.replace(/\/\/.*/g, '<span style="color:#94a3b8;">$&</span>');
  return html;
}

// Converte trechos Rockwell (RC/N) para um ST legivel, mantendo tags como comentarios.
function convertRockwellToSt(code: string): string {
  const lines = code.split(/\r?\n/);
  const output: string[] = [];

  const pushComment = (tag: string, text: string) => {
    const cleaned = text.replace(/^"+|"+$/g, "").replace(/\$N/g, "\n// ");
    output.push(`// ${tag}: ${cleaned}`.trim());
  };

  const splitByCommaTopLevel = (text: string): string[] => {
    const parts: string[] = [];
    let current = "";
    let depth = 0;
    for (let i = 0; i < text.length; i += 1) {
      const ch = text[i];
      if (ch === "(") depth += 1;
      if (ch === ")") depth = Math.max(0, depth - 1);
      if (ch === "," && depth === 0) {
        parts.push(current.trim());
        current = "";
        continue;
      }
      current += ch;
    }
    if (current.trim()) parts.push(current.trim());
    return parts;
  };

  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (!line) continue;

    if (/^RC:/i.test(line)) {
      const content = line.replace(/^RC:\s*/i, "").replace(/;$/, "");
      pushComment("RC", content);
      continue;
    }

    if (/^N:/i.test(line)) {
      const content = line.replace(/^N:\s*/i, "").replace(/;$/, "");
      output.push("// N:");

      const complex = content.match(
        /^XIC\(([^)]+)\)\s*(\[(.*)\])?\s*(OTL|OTU|OTE)\(([^)]+)\)$/i,
      );
      if (complex) {
        const condition = complex[1];
        const branch = complex[3];
        const coil = complex[4].toUpperCase();
        const target = complex[5];

        output.push(`IF ${condition} THEN`);
        if (branch) {
          output.push("  // Ramo paralelo:");
          const parts = splitByCommaTopLevel(branch);
          for (const part of parts) {
            if (/^ONS\(/i.test(part)) {
              output.push(`  // ${part}  (pulso de borda)`);
            } else {
              output.push(`  ${part};`);
            }
          }
        }
        if (coil === "OTL") {
          output.push(`  ${target} := TRUE;`);
        } else if (coil === "OTU") {
          output.push(`  ${target} := FALSE;`);
        } else {
          output.push(`  ${target} := TRUE;`);
        }
        output.push("END_IF;");
        continue;
      }

      if (content.startsWith("[") && content.endsWith("]")) {
        const inner = content.slice(1, -1);
        inner.split(/\s*,\s*/).forEach((chunk) => {
          if (chunk) output.push(`${chunk};`);
        });
        continue;
      }

      const xicOtl = content.match(/XIC\(([^)]+)\)\s*OTL\(([^)]+)\)/i);
      if (xicOtl) {
        output.push(`IF ${xicOtl[1]} THEN`);
        output.push(`  ${xicOtl[2]} := TRUE;`);
        output.push("END_IF;");
        continue;
      }

      const xicOtu = content.match(/XIC\(([^)]+)\)\s*OTU\(([^)]+)\)/i);
      if (xicOtu) {
        output.push(`IF ${xicOtu[1]} THEN`);
        output.push(`  ${xicOtu[2]} := FALSE;`);
        output.push("END_IF;");
        continue;
      }

      const xic = content.match(/XIC\(([^)]+)\)\s*OTE\(([^)]+)\)/i);
      if (xic) {
        output.push(`IF ${xic[1]} THEN`);
        output.push(`  ${xic[2]} := TRUE;`);
        output.push("END_IF;");
        continue;
      }

      const xio = content.match(/XIO\(([^)]+)\)\s*OTE\(([^)]+)\)/i);
      if (xio) {
        output.push(`IF NOT ${xio[1]} THEN`);
        output.push(`  ${xio[2]} := TRUE;`);
        output.push("END_IF;");
        continue;
      }

      output.push(`${content};`);
      continue;
    }

    output.push(rawLine);
  }

  return output.join("\n");
}

// Extrai o conteudo de logica a partir de XMLs e remove ruido tecnico.
function extractSclFromXml(xml: string): string | null {
  const candidates: string[] = [];

  // Captura blocos de texto simples (Siemens/XL).
  const textRegex = /<Text>([\s\S]*?)<\/Text>/gi;
  for (const match of xml.matchAll(textRegex)) {
    candidates.push(match[1]);
  }

  // Captura linhas ST (Rockwell L5X).
  const lineRegex = /<Line>([\s\S]*?)<\/Line>/gi;
  for (const match of xml.matchAll(lineRegex)) {
    candidates.push(match[1]);
  }

  // Captura blocos SourceCode/StructuredText se existirem.
  const sourceRegex = /<SourceCode>([\s\S]*?)<\/SourceCode>/gi;
  for (const match of xml.matchAll(sourceRegex)) {
    candidates.push(match[1]);
  }

  const decoded = candidates
    .map((chunk) => decodeHtmlEntities(chunk))
    .map((chunk) => chunk.replace(/<[^>]+>/g, "").trim())
    .filter((chunk) => chunk.length > 0);

  if (decoded.length === 0) {
    return null;
  }

  // Usa o maior trecho para maximizar a chance de ser a logica principal.
  return decoded.sort((a, b) => b.length - a.length)[0];
}

// Gera uma declaracao estilo SCL a partir da interface (XML Siemens) quando nao existe codigo fonte exportado.
function extractSiemensInterfaceToScl(xml: string): string | null {
  // Heuristica rapida para evitar parse XML desnecessario.
  if (!/(<SW\.Blocks\.)|(<SW\.Blocks\.)|(<Interface\b)/i.test(xml)) {
    return null;
  }

  let doc: Document | null = null;
  try {
    const parser = new DOMParser();
    doc = parser.parseFromString(xml, "application/xml");
    if (doc.getElementsByTagName("parsererror").length > 0) {
      return null;
    }
  } catch {
    return null;
  }
  if (!doc) return null;

  const rootName = (doc.documentElement && doc.documentElement.nodeName) ? doc.documentElement.nodeName : "";
  const isLikelySiemens =
    rootName.startsWith("SW.Blocks.") ||
    /siemens\.com\/automation\/Openness\/SW\/Interface/i.test(xml);
  if (!isLikelySiemens) {
    return null;
  }

  const sectionToVarBlock: Record<string, string> = {
    Input: "VAR_INPUT",
    Output: "VAR_OUTPUT",
    InOut: "VAR_IN_OUT",
    Static: "VAR",
    Temp: "VAR_TEMP",
    Constant: "VAR CONSTANT",
  };

  const normalizeDatatype = (raw: string): string => {
    // Alguns XMLs trazem tipos com aspas duplicadas ou escapadas: ""_Tipo"" ou \"_Tipo\".
    // Aqui queremos sempre exibir o tipo de forma "limpa" no pseudo-SCL.
    const trimmed = (raw || "").trim();
    const unescaped = trimmed.replace(/\\"/g, '"').replace(/&quot;/g, '"');
    // Remove aspas repetidas no inicio/fim, mas preserva o conteudo interno.
    return unescaped.replace(/^"+|"+$/g, "");
  };

  const getDirectChildrenByLocalName = (parent: Element, localName: string): Element[] => {
    return Array.from(parent.children).filter((child) => {
      const ln = (child as Element).localName || (child as Element).nodeName;
      return (ln || "").toLowerCase() === localName.toLowerCase();
    });
  };

  const findFirstElementByLocalName = (root: ParentNode, localName: string): Element | null => {
    const stack: Element[] = [];
    if ((root as Document).documentElement) {
      stack.push((root as Document).documentElement);
    } else if ((root as Element).nodeType === Node.ELEMENT_NODE) {
      stack.push(root as Element);
    }

    const target = localName.toLowerCase();
    while (stack.length > 0) {
      const el = stack.shift();
      if (!el) break;
      const ln = (el.localName || el.nodeName || "").toLowerCase();
      if (ln === target) return el;
      stack.push(...Array.from(el.children));
    }
    return null;
  };

  const getDirectMembers = (sectionEl: Element): Element[] => {
    // Importante: nao usar getElementsByTagName... pois ele inclui membros aninhados (STRUCT),
    // o que "polui" a lista de variaveis do Input/Output.
    return getDirectChildrenByLocalName(sectionEl, "Member");
  };

  const formatNestedStructure = (memberEl: Element): string[] => {
    const lines: string[] = [];
    const sectionsEls = getDirectChildrenByLocalName(memberEl, "Sections");
    if (sectionsEls.length === 0) return lines;

    const sectionEls = getDirectChildrenByLocalName(sectionsEls[0], "Section");
    if (sectionEls.length === 0) return lines;

    lines.push("  // Estrutura interna (campos do tipo):");
    for (const sec of sectionEls) {
      const secName = sec.getAttribute("Name") || "None";
      lines.push(`  //   Section: ${secName}`);
      const nestedMembers = getDirectMembers(sec);
      for (const nested of nestedMembers) {
        const nestedName = nested.getAttribute("Name") || "";
        const nestedType = normalizeDatatype(nested.getAttribute("Datatype") || "");
        if (!nestedName || !nestedType) continue;
        lines.push(`  //     ${nestedName} : ${nestedType}`);
      }
    }
    return lines;
  };

  const pickComment = (memberEl: Element): string => {
    // Importante: nao usar busca recursiva, pois um Member pode conter estrutura interna com seus proprios comentarios.
    const commentEls = getDirectChildrenByLocalName(memberEl, "Comment");
    if (commentEls.length === 0) return "";
    const multi = Array.from(commentEls[0].getElementsByTagName("MultiLanguageText"));
    if (multi.length === 0) return "";

    const byLang = (lang: string) =>
      multi.find((el) => (el.getAttribute("Lang") || "").toLowerCase() === lang.toLowerCase());

    const preferred =
      byLang("pt-BR") ||
      byLang("pt-PT") ||
      byLang("en-US") ||
      multi[0];

    const text = (preferred && preferred.textContent) ? preferred.textContent.trim() : "";
    return text;
  };

  const pickStartValue = (memberEl: Element): string => {
    // Nem todo XML Siemens traz StartValue. Quando existir, tentamos capturar.
    const queue: Element[] = [memberEl];
    while (queue.length > 0) {
      const current = queue.shift();
      if (!current) break;

      const local = (current as Element).localName || (current as Element).nodeName;
      // Evita "roubar" StartValue de membros internos quando este Member for um tipo estruturado (com Sections).
      if (local === "Sections") {
        continue;
      }
      if (local === "StartValue" || local === "DefaultValue") {
        const raw = (current.textContent || "").trim();
        if (!raw) return "";
        // Normaliza valores comuns para SCL.
        if (/^(true|false)$/i.test(raw)) return raw.toUpperCase();
        return raw;
      }

      for (const child of Array.from(current.children)) {
        queue.push(child);
      }
    }
    return "";
  };

  // Ponto critico:
  // - Existem <Section> dentro do Interface (Input/Output/etc.)
  // - Mas tambem pode existir <Sections>/<Section> dentro de um <Member> (estruturas internas).
  // Aqui queremos APENAS as Sections de primeiro nivel do bloco (Interface -> Sections -> Section).
  const interfaceEl = findFirstElementByLocalName(doc, "Interface");
  if (!interfaceEl) return null;
  const interfaceSectionsEl = getDirectChildrenByLocalName(interfaceEl, "Sections")[0];
  if (!interfaceSectionsEl) return null;
  const topSections = getDirectChildrenByLocalName(interfaceSectionsEl, "Section");
  if (topSections.length === 0) return null;

  const lines: string[] = [];
  lines.push("// Interface gerada a partir do XML Siemens.");
  lines.push("// Observacao: este bloco nao contem o codigo (SCL) exportado, apenas a assinatura/estrutura.");
  lines.push("");

  // Agrupa membros por seccao.
  for (const sectionEl of topSections) {
    const sectionName = sectionEl.getAttribute("Name") || "";
    if (!sectionName) continue;

    const varBlock = sectionToVarBlock[sectionName] || `VAR // ${sectionName}`;
    const memberEls = getDirectMembers(sectionEl);
    if (memberEls.length === 0) continue;

    lines.push(varBlock);

    for (const memberEl of memberEls) {
      const name = memberEl.getAttribute("Name") || "";
      const datatype = normalizeDatatype(memberEl.getAttribute("Datatype") || "");
      if (!name || !datatype) continue;

      const comment = pickComment(memberEl);
      if (comment) {
        lines.push(`  // ${comment}`);
      }

      const startValue = pickStartValue(memberEl);
      const assign = startValue ? ` := ${startValue}` : "";
      lines.push(`  ${name} : ${datatype}${assign};`);

      const nested = formatNestedStructure(memberEl);
      if (nested.length > 0) {
        lines.push(...nested);
      }

      lines.push("");
    }

    lines.push("END_VAR");
    lines.push("");
  }

  // Remove linhas em branco excessivas no fim.
  while (lines.length > 0 && lines[lines.length - 1].trim() === "") {
    lines.pop();
  }

  return lines.join("\n");
}

export default function CodeViewer({
  code,
  language = "scl",
}: CodeViewerProps) {
  const normalized = decodeHtmlEntities(code);
  const trimmed = normalized.trimStart();
  const isXml = trimmed.startsWith("<");
  const extracted =
    isXml
      ? (extractSclFromXml(normalized) || extractSiemensInterfaceToScl(normalized))
      : null;
  const rawCode = extracted ?? normalized;
  const shouldConvertRockwell = /(^|\n)\s*(RC:|N:)/i.test(rawCode);
  const displayCode = shouldConvertRockwell ? convertRockwellToSt(rawCode) : rawCode;
  const displayIsXml = extracted ? false : isXml;
  const highlighted = displayIsXml ? highlightXml(displayCode) : highlightScl(displayCode);

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
        <span>Visualizador SCL/XML</span>
        <span style={{ opacity: 0.7 }}>{displayIsXml ? "XML" : language.toUpperCase()}</span>
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
        dangerouslySetInnerHTML={{ __html: highlighted }}
      />
    </div>
  );
}
