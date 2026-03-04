using Siemens.Engineering;
using Siemens.Engineering.Compiler;
using Siemens.Engineering.HW;
using Siemens.Engineering.HW.Features;
using Siemens.Engineering.SW;
using Siemens.Engineering.SW.Blocks;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

public class TiaProjectExporter
{
    public static void Main(string[] args)
    {
        string targetProjectPath = args.Length > 0 ? Path.GetFullPath(args[0]) : string.Empty;
        string exportBasePath = args.Length > 1 ? Path.GetFullPath(args[1]) : @"C:\TiaExports\ControlModules";

        Console.WriteLine("Iniciando exportador TIA Openness V20...");
        Console.WriteLine("Projeto alvo: " + (string.IsNullOrEmpty(targetProjectPath) ? "(nao informado)" : targetProjectPath));
        Console.WriteLine("Pasta de exportacao: " + exportBasePath);

        try
        {
            Directory.CreateDirectory(exportBasePath);

            TiaPortal tiaPortal = null;
            Project project = null;

            if (!TryAttachToProject(targetProjectPath, out tiaPortal, out project))
            {
                Console.WriteLine("Nao foi possivel anexar a instancia aberta. Tentando abrir projeto por arquivo...");

                if (string.IsNullOrEmpty(targetProjectPath) || !File.Exists(targetProjectPath))
                {
                    Console.WriteLine("Projeto nao informado ou inexistente para abertura por arquivo.");
                    return;
                }

                tiaPortal = new TiaPortal(TiaPortalMode.WithoutUserInterface);
                project = tiaPortal.Projects.Open(new FileInfo(targetProjectPath));
            }

            if (project == null)
            {
                Console.WriteLine("Nenhum projeto acessivel no TIA Portal.");
                return;
            }

            Console.WriteLine("Projeto conectado: " + project.Name);

            DeviceItem cpu = FindFirstCpu(project);
            if (cpu == null)
            {
                Console.WriteLine("CPU nao encontrada no projeto.");
                return;
            }

            Console.WriteLine("CPU encontrada: " + cpu.Name);

            SoftwareContainer softwareContainer = cpu.GetService<SoftwareContainer>();
            PlcSoftware plcSoftware = softwareContainer != null ? softwareContainer.Software as PlcSoftware : null;
            if (plcSoftware == null)
            {
                Console.WriteLine("Nao foi possivel acessar PlcSoftware da CPU.");
                return;
            }

            TryCompile(plcSoftware, project);

            Console.WriteLine("Iniciando exportacao recursiva...");
            int exported = BrowseAndExportBlocks(plcSoftware.BlockGroup, exportBasePath);
            Console.WriteLine("Exportacao finalizada. Total exportado: " + exported);
        }
        catch (Exception ex)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine("Erro critico: " + ex.Message);
            Console.WriteLine(ex.StackTrace);
            Console.ResetColor();
        }
    }

    private static bool TryAttachToProject(string targetProjectPath, out TiaPortal attachedPortal, out Project attachedProject)
    {
        attachedPortal = null;
        attachedProject = null;

        IList<TiaPortalProcess> processes = TiaPortal.GetProcesses();
        if (processes == null || processes.Count == 0)
        {
            Console.WriteLine("Nenhum processo TIA encontrado para attach.");
            return false;
        }

        foreach (TiaPortalProcess p in processes.OrderByDescending(x => x.Id))
        {
            try
            {
                Console.WriteLine("Tentando attach no processo Id=" + p.Id + "...");

                if (!string.IsNullOrEmpty(targetProjectPath) && p.ProjectPath != null)
                {
                    string pp = p.ProjectPath.FullName;
                    if (!string.IsNullOrEmpty(pp) && !string.Equals(pp, targetProjectPath, StringComparison.OrdinalIgnoreCase))
                    {
                        Console.WriteLine("Ignorando processo " + p.Id + " (projeto diferente).");
                        continue;
                    }
                }

                TiaPortal portal = p.Attach();
                if (portal.Projects.Count > 0)
                {
                    attachedPortal = portal;
                    attachedProject = portal.Projects.First();
                    return true;
                }

                portal.Dispose();
            }
            catch (Exception ex)
            {
                Console.WriteLine("Attach falhou no processo " + p.Id + ": " + ex.Message);
            }
        }

        return false;
    }

    private static DeviceItem FindFirstCpu(Project project)
    {
        foreach (Device d in project.Devices)
        {
            DeviceItem found = FindCpuRecursive(d.DeviceItems);
            if (found != null)
            {
                return found;
            }
        }
        return null;
    }

    private static DeviceItem FindCpuRecursive(IEnumerable<DeviceItem> items)
    {
        foreach (DeviceItem di in items)
        {
            if (di.Classification == DeviceItemClassifications.CPU || di.Name.ToUpperInvariant().Contains("CPU"))
            {
                return di;
            }

            DeviceItem nested = FindCpuRecursive(di.DeviceItems);
            if (nested != null)
            {
                return nested;
            }
        }
        return null;
    }

    private static void TryCompile(PlcSoftware plcSoftware, Project project)
    {
        try
        {
            ICompilable c = plcSoftware.GetService<ICompilable>();
            if (c == null)
            {
                c = project.GetService<ICompilable>();
            }

            if (c == null)
            {
                Console.WriteLine("Compilacao indisponivel neste contexto. Continuando sem compilar.");
                return;
            }

            Console.WriteLine("Executando compilacao (best effort)...");
            CompilerResult r = c.Compile();
            Console.WriteLine("Compilacao: Estado=" + r.State + ", Erros=" + r.ErrorCount + ", Avisos=" + r.WarningCount);
        }
        catch (Exception ex)
        {
            Console.WriteLine("Aviso na compilacao: " + ex.Message);
        }
    }

    private static int BrowseAndExportBlocks(PlcBlockGroup group, string currentPath)
    {
        Directory.CreateDirectory(currentPath);
        Console.WriteLine("-- Pasta: " + group.Name);

        int exported = 0;

        // Snapshot local para evitar excecao de colecao modificada durante export.
        List<PlcBlock> blocks = group.Blocks.ToList();
        foreach (PlcBlock block in blocks)
        {
            if (!(block is OB) && !(block is FB) && !(block is FC))
            {
                continue;
            }

            string blockType = block.GetType().Name.Replace("Plc", "");
            string fileName = blockType + "_" + SanitizePathName(block.Name) + ".xml";
            string fullPath = Path.Combine(currentPath, fileName);

            try
            {
                Console.WriteLine("   -> Exportando [" + blockType + "] " + block.Name + " -> " + fullPath);
                block.Export(new FileInfo(fullPath), ExportOptions.WithDefaults | ExportOptions.WithReadOnly);
                exported++;
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("   AVISO: falha ao exportar " + block.Name + ": " + ex.Message);
                Console.ResetColor();
            }
        }

        // Snapshot local dos subgrupos pelo mesmo motivo de estabilidade da iteracao.
        var subGroups = group.Groups.ToList();
        foreach (var subGroup in subGroups)
        {
            string subPath = Path.Combine(currentPath, SanitizePathName(subGroup.Name));
            exported += BrowseAndExportBlocks(subGroup, subPath);
        }

        return exported;
    }

    private static string SanitizePathName(string value)
    {
        char[] invalid = Path.GetInvalidFileNameChars();
        string v = new string(value.Select(ch => invalid.Contains(ch) ? '_' : ch).ToArray());
        v = v.Trim();
        return string.IsNullOrWhiteSpace(v) ? "Unnamed" : v;
    }
}
