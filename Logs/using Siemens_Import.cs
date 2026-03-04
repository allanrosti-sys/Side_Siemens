using Siemens.Engineering;
using Siemens.Engineering.HW;
using Siemens.Engineering.HW.Features;
using Siemens.Engineering.SW;
using Siemens.Engineering.SW.ExternalSources;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

public class TiaBlockImporter
{
    public static void Main(string[] args)
    {
        Console.WriteLine("=== TIA Portal SCL Importer v20 ===");

        string sourceDir;
        string projectPath;
        bool isHeadless;
        ParseArgs(args, out sourceDir, out projectPath, out isHeadless);

        if (string.IsNullOrWhiteSpace(sourceDir))
        {
            sourceDir = Path.Combine(Directory.GetCurrentDirectory(), "Logs", "NewBlocks");
        }

        Console.WriteLine("Diretorio de fontes: " + sourceDir);
        Console.WriteLine("Modo: " + (isHeadless ? "Headless" : "Attach"));

        if (!Directory.Exists(sourceDir))
        {
            Console.WriteLine("ERRO: Diretorio de fontes nao encontrado.");
            return;
        }

        // Busca tanto .scl quanto .udt
        var files = new List<string>();
        files.AddRange(Directory.GetFiles(sourceDir, "*.scl", SearchOption.TopDirectoryOnly));
        files.AddRange(Directory.GetFiles(sourceDir, "*.udt", SearchOption.TopDirectoryOnly));

        if (files.Count == 0)
        {
            Console.WriteLine("AVISO: Nenhum arquivo .scl ou .udt encontrado para importar.");
            return;
        }

        TiaPortal tia = null;
        Project project = null;

        try
        {
            if (isHeadless)
            {
                if (string.IsNullOrWhiteSpace(projectPath) || !File.Exists(projectPath))
                {
                    Console.WriteLine("ERRO: Caminho do projeto (.ap20) invalido para modo headless.");
                    return;
                }

                try
                {
                    Console.WriteLine("Iniciando TIA em modo headless...");
                    tia = new TiaPortal(TiaPortalMode.WithoutUserInterface);
                    project = tia.Projects.Open(new FileInfo(projectPath));
                }
                catch (Exception ex)
                {
                    Console.WriteLine("Aviso: falha no headless open. Tentando fallback por attach.");
                    Console.WriteLine("Motivo: " + ex.Message);

                    if (tia != null)
                    {
                        tia.Dispose();
                        tia = null;
                    }

                    AttachToRunningPortal(out tia, out project);
                }
            }
            else
            {
                AttachToRunningPortal(out tia, out project);
            }

            if (project == null)
            {
                Console.WriteLine("ERRO: Nenhum projeto disponivel para importacao.");
                return;
            }

            Console.WriteLine("Projeto vinculado: " + project.Name);

            DeviceItem cpu = FindFirstCpu(project);
            if (cpu == null)
            {
                Console.WriteLine("ERRO: CPU nao encontrada no projeto.");
                return;
            }

            Console.WriteLine("CPU encontrada: " + cpu.Name);

            SoftwareContainer container = cpu.GetService<SoftwareContainer>();
            PlcSoftware software = container != null ? container.Software as PlcSoftware : null;
            if (software == null)
            {
                Console.WriteLine("ERRO: Nao foi possivel acessar o software PLC da CPU.");
                return;
            }

            PlcExternalSourceSystemGroup srcGroup = software.ExternalSourceGroup;
            ImportSclFiles(files.ToArray(), srcGroup);

            if (isHeadless)
            {
                Console.WriteLine("Salvando projeto...");
                project.Save();
            }

            Console.WriteLine("Importacao finalizada.");
        }
        catch (Exception ex)
        {
            Console.WriteLine("ERRO GERAL: " + ex.Message);
            Console.WriteLine(ex.StackTrace);
        }
        finally
        {
            if (tia != null)
            {
                Console.WriteLine("Encerrando sessao TIA...");
                tia.Dispose();
            }
        }
    }

    private static void ParseArgs(string[] args, out string sourceDir, out string projectPath, out bool isHeadless)
    {
        isHeadless = args.Any(a => string.Equals(a, "--headless", StringComparison.OrdinalIgnoreCase));

        List<string> positional = args
            .Where(a => !string.Equals(a, "--headless", StringComparison.OrdinalIgnoreCase))
            .ToList();

        sourceDir = positional.Count > 0 ? positional[0] : string.Empty;
        projectPath = positional.Count > 1 ? positional[1] : string.Empty;
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

    private static void AttachToRunningPortal(out TiaPortal tia, out Project project)
    {
        tia = null;
        project = null;

        Console.WriteLine("Conectando ao TIA aberto (attach)...");
        IList<TiaPortalProcess> processes = TiaPortal.GetProcesses();
        if (processes == null || processes.Count == 0)
        {
            Console.WriteLine("ERRO: Nenhuma instancia do TIA Portal em execucao para attach.");
            return;
        }

        foreach (TiaPortalProcess process in processes.OrderByDescending(p => p.Id))
        {
            try
            {
                TiaPortal attached = process.Attach();
                Project opened = attached.Projects.FirstOrDefault();
                if (opened != null)
                {
                    tia = attached;
                    project = opened;
                    return;
                }

                attached.Dispose();
            }
            catch
            {
                // tenta proximo processo
            }
        }
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

    private static void ImportSclFiles(string[] sclFiles, PlcExternalSourceSystemGroup srcGroup)
    {
        foreach (string file in sclFiles)
        {
            string name = Path.GetFileNameWithoutExtension(file);
            Console.WriteLine("Processando: " + name);

            try
            {
                PlcExternalSource existing = srcGroup.ExternalSources.Find(name);
                if (existing != null)
                {
                    existing.Delete();
                }

                PlcExternalSource src = srcGroup.ExternalSources.CreateFromFile(name, file);
                Console.WriteLine(" -> Gerando blocos...");
                src.GenerateBlocksFromSource();
                Console.WriteLine(" -> SUCESSO");
            }
            catch (Exception ex)
            {
                Console.WriteLine(" -> ERRO: " + ex.Message);
            }
        }
    }
}
