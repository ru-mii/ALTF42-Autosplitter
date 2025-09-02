//ALTF2 Autosplitter V1.0 - 5th June 2024
//Supports Load Remover & Autosplits
//By TheDementedSalad & Rumii
//Special thanks to Rumii for doing the code injection to get the loading progress bar

state("ALTF42-Win64-Shipping"){ }

startup
{
	vars.ItemSettingFormat = "[{0}] {1} ({2})";

	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
	Assembly.Load(File.ReadAllBytes("Components/uhara8")).CreateInstance("Main");
	vars.Helper.Settings.CreateFromXml("Components/ALTF42.Settings.xml");
	vars.Helper.GameName = "ALTF4 2 (2024)";
	vars.Uhara.EnableDebug();

	vars.completedSplits = new HashSet<string>();
	vars.LoadingStatus = 0;
	vars.NowLoading = false;
}

onStart
{
	vars.completedSplits.Clear();
	timer.IsGameTimePaused = true;
	vars.NowLoading = false;
	vars.LoadingStatus = 0;
}

init
{
	// default
	IntPtr GEngine = vars.Helper.ScanRel(3, "48 89 05 ???????? 48 85 c9 74 ?? e8 ???????? 48 8d 4d");
	vars.Helper["cantMove"] = vars.Helper.Make<bool>(GEngine, 0x1080, 0x38, 0x0, 0x30, 0x2E8, 0xB1F);
	vars.Helper["Level"] = vars.Helper.MakeString(GEngine, 0xB98, 0x20);
	vars.Helper["Level"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	
	// uhara
	var Events = vars.Uhara.CreateTool("UnrealEngine", "Events");
	vars.Helper["StartLoading"] = vars.Helper.Make<ulong>(Events.FunctionFlag("", "WBP_LoadingScreenMenu_Silence_C", "OnInitialized"));
	vars.Helper["EndLoading"] = vars.Helper.Make<ulong>(vars.Uhara.CodeHKFlag("48 89 5C 24 ?? 48 89 6C 24 ?? 48 89 74 24 ?? 57 41 54 41 55 41 56 41 57 48 83 EC ?? 48 8B 72 ?? 49 8B D8 48 8B 01 4C 8B F2 41 B0 01 48 8B D6 48 8B F9 4C 8B 66 ?? 4C 8B 6E ?? FF 50 ?? 41 B0 01"));
	vars.Helper["LoadingAdvance"] = vars.Helper.Make<ulong>(GEngine, 0x1080, 0x38, 0x0, 0x78, 0x78, 0x158);
	vars.Helper["LoadingAdvance"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
}

update
{
	vars.Helper.Update();
	vars.Helper.MapPointers();
	
	if (current.StartLoading != old.StartLoading && current.StartLoading != 0)
	{
		vars.NowLoading = true;
	}
	
	if (current.LoadingAdvance == 0 && old.LoadingAdvance != 0)
	{
		vars.LoadingStatus = 1;
	}
	
	if (current.LoadingAdvance != 0 && old.LoadingAdvance == 0 && vars.LoadingStatus == 1)
	{
		vars.LoadingStatus = 2;
	}
	
	if (current.LoadingAdvance != 0 && old.LoadingAdvance != 0 && current.LoadingAdvance != old.LoadingAdvance && vars.LoadingStatus == 1)
	{
		vars.LoadingStatus = 2;
	}
	
	if (vars.LoadingStatus == 2 && current.EndLoading != old.EndLoading)
	{
		vars.LoadingStatus = 0;
		vars.NowLoading = false;
	}
	
	print(vars.LoadingStatus.ToString());
}

start
{
	return (current.Level == "Map_A_01_Persistent" || current.Level == "Map_A_03_Persistent") && !current.cantMove && old.cantMove;
}

split
{
	string setting = "";

	if (current.Level != old.Level)
	{
		setting = current.Level;
	}

	if (settings.ContainsKey(setting) && settings[setting] && vars.completedSplits.Add(setting))
	{
		return true;
	}
}

isLoading
{
	return vars.NowLoading || current.Level == "MainMenu";
}

exit
{
	//pauses timer if the game crashes
	timer.IsGameTimePaused = true;
}
