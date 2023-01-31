#Requires AutoHotkey v2.0-a
#SingleInstance Force
#NoTrayIcon
;@Ahk2Exe-IgnoreBegin
if FileExist(trayicon_filepath := EnvGet("SystemRoot") "\System32\mmcndmgr.dll")
	TraySetIcon(trayicon_filepath, 48)
;@Ahk2Exe-IgnoreEnd
MainGui := Gui(, "Sequence Generator")
MainGui.SetFont("s12", "Courier")
MainGui.Add("Text", "xm", "Start:")
MainGui.Add("Edit", "x+10 w70 section")
MainGui.Add("UpDown", "Range-2147483648-2147483647 vstart")
MainGui.Add("Text", "x+18 vtext_stop", "Stop:")
MainGui.Add("Edit", "x+10 w70")
MainGui.Add("UpDown", "Range-2147483648-2147483647 vstop")
MainGui.Add("Text", "x+18", "Step:")
MainGui.Add("Edit", "x+10 w70")
MainGui.Add("UpDown", "vstep Range0-2147483647")
MainGui.Add("Text", "xm", "Template:")
MainGui.Add("Edit", "x+10 w150 vtemplate")
MainGui.Add("Text", "x+18", "Delimiter:")
MainGui.Add("Edit", "x+10 w60 vdelimiter")

; Default Values
MainGui["start"].value := 1
MainGui["stop"].value := 10
MainGui["step"].value := 1
MainGui["template"].value := "{}"
MainGui["delimiter"].value := "\n"

for ctl in MainGui
	if (ctl.type = "Edit")
		ctl.OnEvent("Change", UpdateState)
MainGui.Add("Edit", "xm r16 w420 voutput")
MainGui.Add("Button", "xm wp", "Copy").OnEvent("Click", (*) => (
	A_Clipboard := MainGui["output"].Text,
	Tooltip("Copied to clipboard"),
	SetTimer(() => ToolTip(), -1500)
))

UpdateState()

MainGui.Show()
MainGui.OnEvent("Close", (*) => ExitApp)
return


UpdateState(*) {
	global MainGui
	start := MainGui["start"].value
	stop := MainGui["stop"].value
	step := MainGui["step"].value
	template := MainGui["template"].value
	delimiter := MainGui["delimiter"].value
	delimiter := delimiter = "\n" ? "`n" : DecodeEscapeChar(delimiter)

	if (step > 0) {
		i := start
		incr := step
		ltr := start < stop
	} else {
		i := 1
		step := 1
		incr := 0
		ltr := true
	}
	if ltr {
		condition := () => (i <= stop)
	} else {
		condition := () => (i >= stop)
		step := -step
		incr := step
	}

	n := start
	output := ""
	while condition() {
		output .= delimiter Format(template, n)
		i += step
		n += incr
	}
	output := SubStr(output, 1+StrLen(delimiter))
	MainGui["output"].value := output
}

DecodeEscapeChar(str) {
	static esc := {n: "`n", r: "`r", b: "`b", t: "`t", v: "`v", a: "`a", f: "`f"}
	output := ""
	str := RegExReplace(str, "(.*?)(\\)(.)(?C)")
	output .= str
	return output

	pcre_callout(m, *) {
		output .= m[1] . (m[3] = "\" ? m[3] : esc.HasOwnProp(m[3]) ? esc.%m[3]% : "")
	}
}