using Siemens.Engineering;
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
        string exportBasePath = @"C:\TiaExports\ControlModules";

        Console.WriteLine("Iniciando a ferramenta de exportacao TIA Openness...");

        try
        {
            Directory.CreateDirectory(exportBasePath);

            Console.WriteLine("Conectando-se a instancias do TIA Portal...");
            IList<TiaPortalProcess> tiaPortalInstances = TiaPortal.GetProcesses();
            if (tiaPortalInstances.Count == 0)
            {
                Console.WriteLine("Nenhuma instancia do TIA Portal encontrada.");
                return;
            }
            TiaPortal tiaPortal = tiaPortalInstances.First().Attach();
            Console.WriteLine("Conectado com sucesso!");

            if (tiaPortal.Projects.Count == 0)
            {
                Console.WriteLine("Nenhum projeto aberto no TIA Portal.");
                return;
            }
            Project project = tiaPortal.Projects.First();
            Console.WriteLine("Acessando o projeto: " + project.Name);

            DeviceItem plcDeviceItem = project.Devices
                .SelectMany(d => d.DeviceItems)
                .FirstOrDefault(di => di.Name.Contains("PLC") || di.Classification == DeviceItemClassifications.CPU);

            if (plcDeviceItem == null)
            {
                Console.WriteLine("Nenhum PLC (DeviceItem) encontrado no projeto.");
                return;
            }
            Console.WriteLine("PLC encontrado: " + plcDeviceItem.Name);

            SoftwareContainer softwareContainer = plcDeviceItem.GetService<SoftwareContainer>();
            PlcSoftware plcSoftware = null;
            if (softwareContainer != null)
            {
                plcSoftware = softwareContainer.Software as PlcSoftware;
            }
            if (plcSoftware == null)
            {
                Console.WriteLine("Nao foi possivel acessar o software do PLC.");
                return;
            }

            Console.WriteLine("");
            Console.WriteLine("Iniciando a varredura e exportacao dos blocos...");
            BrowseAndExportBlocks(plcSoftware.BlockGroup, exportBasePath);

            Console.WriteLine("");
            Console.WriteLine("Exportacao concluida! Os arquivos .xml foram salvos em: " + exportBasePath);
        }
        catch (Exception ex)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine("Ocorreu um erro: " + ex.Message);
            Console.WriteLine(ex.StackTrace);
        }
        finally
        {
            Console.ResetColor();
            Console.WriteLine("Pressione qualquer tecla para sair.");
            Console.ReadKey();
        }
    }

    private static void BrowseAndExportBlocks(PlcBlockGroup group, string currentPath)
    {
        Directory.CreateDirectory(currentPath);
        Console.WriteLine("-- Processando pasta: " + group.Name);

        foreach (PlcBlock block in group.Blocks)
        {
            if (block is FC || block is FB || block is OB)
            {
                string blockType = block.GetType().Name.Replace("Plc", "");
                string fileName = block.Name + ".xml";
                string fullPath = Path.Combine(currentPath, fileName);

                try
                {
                    Console.WriteLine("   -> Exportando [" + blockType + "] " + block.Name + " para " + fullPath);
                    block.Export(new FileInfo(fullPath), ExportOptions.WithDefaults | ExportOptions.WithReadOnly);
                }
                catch (Exception ex)
                {
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    Console.WriteLine("      AVISO: Falha ao exportar o bloco " + block.Name + ". Erro: " + ex.Message);
                    Console.ResetColor();
                }
            }
        }

        foreach (PlcBlockGroup subGroup in group.Groups)
        {
            BrowseAndExportBlocks(subGroup, Path.Combine(currentPath, subGroup.Name));
        }
    }
}
