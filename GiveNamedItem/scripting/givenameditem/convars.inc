Handle g_cvar_print_debugmsgs;
bool cvar_print_debugmsgs;

stock void RegisterConvars()
{
	g_cvar_print_debugmsgs = CreateConVar("givenameditem_print_debugmsgs", "0", "Logs debug messages to each clients console during processing.");
	HookConVarChange(g_cvar_print_debugmsgs, OnConvarChanged);
	cvar_print_debugmsgs = GetConVarBool(g_cvar_print_debugmsgs);
}

public OnConvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == g_cvar_print_debugmsgs)
		cvar_print_debugmsgs = StringToInt(newVal) == 1 ? true : false;
}