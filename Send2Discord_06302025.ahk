#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn

SetTitleMatchMode("RegEx")
global iniFile := A_ScriptDir "\send2settings.ini"
global hotkeySection := "Hotkeys"
global silentSection := "Silent"
global hotkeyMap := Map()

CleanHotkey(str) {
    return Trim(str)
}

IniReadSection(path, section) {
    out := Map()
    if !FileExist(path)
        return out
    txt := FileRead(path)
    block := false
    for line in StrSplit(txt, "`n", "`r") {
        line := Trim(line)
        if line ~= "^\[.*\]$" {
            block := (Trim(StrReplace(StrReplace(line, "[", ""), "]", "")) = section)
            continue
        }
        if !block || line = "" || SubStr(line, 1, 1) = ";"
            continue
        parts := StrSplit(line, "=")
        if parts.Length >= 2
            out[Trim(parts[1])] := Trim(StrReplace(line, parts[1] "=", ""))
    }
    return out
}

TestHotkey(parentGui, lv) {
    row := lv.GetNext()
    if row = 0
        return
    hk := lv.GetText(row, 1)
    if hotkeyMap.Has(hk)
        HandleHotkey(hotkeyMap[hk])
}

LoadHotkeys() {
    global hotkeyMap
    hotkeyMap.Clear()
    for hk, pings in IniReadSection(iniFile, hotkeySection)
        RegisterHotkey(hk, pings)
}

RegisterHotkey(hotkeyStr, pingText) {
    global hotkeyMap
    Try Hotkey(hotkeyStr, (*) => HandleHotkey(pingText), "On")
    Catch {
        MsgBox("⚠ Failed to bind hotkey:`n" hotkeyStr)
        return
    }
    hotkeyMap[hotkeyStr] := pingText
}
PromptMentions(callback, defaultMentions := "") {
    local EMentionsGui, inputCtrl, tagGui, mentionList := defaultMentions != "" ? StrSplit(Trim(defaultMentions), " ") : []

    EMentionsGui := Gui("+AlwaysOnTop", "Mention Manager")
    EMentionsGui.SetFont("s10")

    EMentionsGui.Add("Text", "xm", "Enter Username:")
    inputCtrl := EMentionsGui.Add("Edit", "xm w200")
    EMentionsGui.Add("Button", "x+10 w80", "Add")
        .OnEvent("Click", (*) => AddMention(inputCtrl, tagGui, mentionList))

    EMentionsGui.Add("Text", "xm y+10", "Mentions:")

    tagGui := Gui("+Parent" EMentionsGui.Hwnd " -Caption +ToolWindow")
    tagGui.SetFont("s10")
    tagGui.Show("x15 y105 w300 h120")
    for _, nameItem in mentionList {
        local thisName := nameItem
        tagBtn := tagGui.Add("Button", , thisName)
        tagBtn.OnEvent("Click", (*) => RemoveMention(tagBtn, thisName, mentionList, tagGui))
    }
    ReflowTags(tagGui)

    EMentionsGui.Add("Button", "xm y+135 w100", "Confirm")
        .OnEvent("Click", (*) => ConfirmMentions(mentionList, EMentionsGui, callback))

    EMentionsGui.Show("AutoSize")
}

AddMention(inputCtrl, tagGui, listRef) {
    local name := Trim(inputCtrl.Value)
    if name = ""
        return
    if SubStr(name, 1, 1) != "@"
        name := "@" . name
    if listRef.Has(name)
        return
    listRef.Push(name)
    tagBtn := tagGui.Add("Button", , name)
    tagBtn.OnEvent("Click", (*) => RemoveMention(tagBtn, name, listRef, tagGui))
    ReflowTags(tagGui)
    inputCtrl.Value := ""
    inputCtrl.Focus()
}

RemoveMention(btn, name, listRef, tagGui) {
    idx := 0
    for i, val in listRef {
        if val = name {
            idx := i
            break
        }
    }
    if idx
        listRef.RemoveAt(idx)
    for ctrl in tagGui {
        ctrl.Visible := false
        ctrl.Enabled := false
    }
    for _, name in listRef {
        local fixedName := name
        tag := tagGui.Add("Button", , fixedName)
        tag.OnEvent("Click", (*) => RemoveMention(tag, fixedName, listRef, tagGui))
    }
    ReflowTags(tagGui)
}

ConfirmMentions(listRef, guiCtrl, callbackFn) {
    mentions := ""
    for _, name in listRef
        mentions .= (mentions ? " " : "") . name
    guiCtrl.Destroy()
    callbackFn(mentions)
}

ReflowTags(tagGui) {
    marginX := 5, marginY := 5, spacing := 5
    maxWidth := 300
    x := marginX, y := marginY, rowHeight := 0
    for ctrl in tagGui {
        if !ctrl.Visible
            continue
        x0 := 0, y0 := 0, w := 0, h := 0
        ctrl.GetPos(&x0, &y0, &w, &h)
        if (x + w > maxWidth) {
            x := marginX
            y += rowHeight + spacing
            rowHeight := 0
        }
        ctrl.Move(x, y)
        x += w + spacing
        if h > rowHeight
            rowHeight := h
    }
    totalHeight := y + rowHeight + marginY
    tagGui.Move(,, maxWidth, totalHeight)
}
PromptHotkey(title, defaultHotkey := "", defaultPings := "", callback := unset, showMentions := true) {
    local modMap := Map("None", "", "Ctrl", "^", "Alt", "!", "Shift", "+", "Win", "#")
    local reverseModMap := Map("^", "Ctrl", "!", "Alt", "+", "Shift", "#", "Win")

    keyList := [
        "A","B","C","D","E","F","G","H","I","J","K","L","M",
        "N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
        "0","1","2","3","4","5","6","7","8","9",
        "F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12",
        "Up","Down","Left","Right","Tab","Enter","Esc","Space"
    ]
    modOptions := ["None", "Ctrl", "Alt", "Shift", "Win"]

    currentMods := []
    keyFound := ""
    loop Parse, defaultHotkey {
        if reverseModMap.Has(A_LoopField)
            currentMods.Push(reverseModMap[A_LoopField])
        else
            keyFound .= A_LoopField
    }

    modPrefill1 := currentMods.Length >= 1 ? currentMods[1] : "None"
    modPrefill2 := currentMods.Length >= 2 ? currentMods[2] : "None"
    keyPrefill := keyList.Has(keyFound) ? keyFound : "C"

    phGui := Gui()
    phGui.Opt("+AlwaysOnTop")
    phGui.Title := title
    phGui.SetFont("s10")

    phGui.Add("Text", "xm y+10", "Modifier 1:")
    mod1 := phGui.Add("ComboBox", "x+90 yp w100", modOptions)
    mod1.Text := modPrefill1

    phGui.Add("Text", "xm y+10", "Modifier 2:")
    mod2 := phGui.Add("ComboBox", "x+90 yp w100", modOptions)
    mod2.Text := modPrefill2

    phGui.Add("Text", "xm y+10", "Key:")
    keyBox := phGui.Add("ComboBox", "x+125 yp w160", keyList)
    keyBox.Text := keyPrefill

    if showMentions {
        phGui.Add("Text", "xm y+10", "Mentions (e.g. <@123>):")
        mEdit := phGui.Add("Edit", "x+10 yp w300 ReadOnly", defaultPings)
        phGui.Add("Button", "x+5 yp w100", "Edit Mentions")
            .OnEvent("Click", (*) => PromptMentions((mentionStr) => mEdit.Value := mentionStr, mEdit.Value))
    } else {
        mEdit := { Value: "" }
    }

    silent := phGui.Add("Checkbox", "xm y+10", "Silent Mode (skip mention typing)")
    silent.Value := IniRead(iniFile, silentSection, defaultHotkey, "false") = "true" ? 1 : 0

    preview := phGui.Add("Text", "xm y+10 w300", "")

    updatePreview := (*) => (
        previewHotkey := modMap[mod1.Text] . modMap[mod2.Text] . keyBox.Text,
        preview.Value := "Hotkey: " previewHotkey
    )

    mod1.OnEvent("Change", updatePreview)
    mod2.OnEvent("Change", updatePreview)
    keyBox.OnEvent("Change", updatePreview)
    updatePreview()

    phGui.Add("Button", "xm y+10 w80 Default", "Save").OnEvent("Click", (*) => (
        phGui.Submit(),
        finalHotkey := modMap[mod1.Text] . modMap[mod2.Text] . keyBox.Text,
        IniWrite(silent.Value ? "true" : "false", iniFile, silentSection, finalHotkey),
        callback(finalHotkey, mEdit.Value),
        phGui.Destroy()
    ))

    phGui.Add("Button", "x+10 yp w80", "Cancel").OnEvent("Click", (*) => phGui.Destroy())
    phGui.Show()
}
IsInteger(val) {
    return val ~= "^\d+$"
}

HandleHotkey(pings) {
    downCount := IniRead(iniFile, "Settings", "DownCount", "2")
    isSilent := IniRead(iniFile, silentSection, A_ThisHotkey, "false") = "true"
    if !IsInteger(downCount) || downCount < 1 {
        MsgBox("Invalid DownCount")
        return
    }

    CoordMode("Mouse", "Screen")
    MouseGetPos(&x, &y)

    oldClip := A_Clipboard
    A_Clipboard := ""
    Click("Right")
    Sleep(200)
    Loop downCount
        Send("{Down}")
    Send("{Enter}")
    ClipWait(1)

    if A_Clipboard != "" {
        if WinExist("ahk_exe Discord.exe") {
            WinActivate("ahk_exe Discord.exe")
            WinWaitActive("ahk_exe Discord.exe")
            Sleep(400)

            A_Clipboard := A_Clipboard
            Send("^v")

            if isSilent || Trim(pings) = "" {
                Sleep(100)
                Send("{Enter}")
                A_Clipboard := oldClip
                return
            }

            Sleep(100)
            Send(" ")
            mentionList := StrSplit(pings, " ")

            for i, mention in mentionList {
                if SubStr(mention, 1, 1) = "@" {
                    Send("@")
                    Sleep(30)
                    Send(SubStr(mention, 2))
                    Sleep(250 + (i - 1) * 60)
                    Send("{Tab}")
                    Sleep(100)
                    Send(" ")
                } else {
                    Send(" " . mention)
                    Sleep(70)
                }
            }

            Sleep(250)
            Send("{Enter}")
        } else {
            MsgBox("Discord is not running.")
        }

        Sleep(150)
        A_Clipboard := oldClip
    } else {
        MsgBox("No link was copied.")
    }
}

ShowHotkeyManager() {
    global hotkeyMap
    if WinExist("Hotkey Manager")
        return

    managerGui := Gui()
    managerGui.Opt("+AlwaysOnTop +Resize")
    managerGui.Title := "Hotkey Manager"
    managerGui.SetFont("s10")
    lv := managerGui.Add("ListView", "r10 w450", ["Hotkey", "Mentions"])
    for hk, val in hotkeyMap
        lv.Add("", hk, val)

    managerGui.Add("Button", "w80", "Add").OnEvent("Click", (*) => AddHotkey(managerGui, lv))
    managerGui.Add("Button", "x+10 w80", "Edit").OnEvent("Click", (*) => EditHotkey(managerGui, lv))
    managerGui.Add("Button", "x+10 w80", "Delete").OnEvent("Click", (*) => DeleteHotkey(managerGui, lv))
    managerGui.Add("Button", "x+10 w80", "Test").OnEvent("Click", (*) => TestHotkey(managerGui, lv))
    managerGui.Add("Button", "x+10 w80", "Close").OnEvent("Click", (*) => managerGui.Destroy())
	managerGui.Add("Button", "x+10 w100", "View README")
    .OnEvent("Click", (*) => OpenReadme())
    managerGui.Show()
}

AddHotkey(parentGui, lv) {
    PromptHotkey("Add Hotkey", "", "", (hk, pingText) => (
        hk := CleanHotkey(hk),
        hotkeyMap.Has(hk)
        ? MsgBox("That hotkey is already assigned.")
        : (
            IniWrite(pingText, iniFile, hotkeySection, hk),
            RegisterHotkey(hk, pingText),
            lv.Add("", hk, pingText)
        )
    ))
}

EditHotkey(parentGui, lv) {
    row := lv.GetNext()
    if row = 0
        return

    oldHotkey := lv.GetText(row, 1)
    oldMention := lv.GetText(row, 2)

    PromptHotkey("Edit Hotkey", oldHotkey, oldMention, (newHotkey, newPings) =>
        HandleEdit(row, oldHotkey, oldMention, CleanHotkey(newHotkey), newPings, lv)
    )
}

HandleEdit(row, oldHotkey, oldMention, newHotkey, newPings, lv) {
    if newHotkey != oldHotkey && hotkeyMap.Has(newHotkey) {
        MsgBox("That hotkey is already assigned.")
        return
    }

    try Hotkey(oldHotkey, , "Off")
    catch {
        MsgBox("Could not unbind old hotkey: " oldHotkey)
        return
    }

    IniDelete(iniFile, hotkeySection, oldHotkey)
    IniDelete(iniFile, silentSection, oldHotkey)

    try {
        RegisterHotkey(newHotkey, newPings)
    } catch {
        MsgBox("❌ Failed to register hotkey:`n" newHotkey)
        RegisterHotkey(oldHotkey, oldMention)
        IniWrite(oldMention, iniFile, hotkeySection, oldHotkey)
        return
    }

    IniWrite(newPings, iniFile, hotkeySection, newHotkey)
    lv.Modify(row, , newHotkey, newPings)
}

DeleteHotkey(parentGui, lv) {
    row := lv.GetNext()
    if row = 0
        return
    hk := lv.GetText(row, 1)

    if ConfirmDelete(hk) {
        Hotkey(hk, , "Off")
        IniDelete(iniFile, hotkeySection, hk)
        IniDelete(iniFile, silentSection, hk)
        hotkeyMap.Delete(hk)
        lv.Delete(row)
    }
}

ConfirmDelete(hk) {
    confirmed := false
    confirmGui := Gui("+AlwaysOnTop +ToolWindow", "Confirm Deletion")
    confirmGui.Add("Text", , "Delete hotkey: " hk "?")
    confirmGui.Add("Button", "w70 Default", "Yes").OnEvent("Click", (*) => (
        confirmed := true,
        confirmGui.Destroy()
    ))
    confirmGui.Add("Button", "x+10 w70", "No").OnEvent("Click", (*) => confirmGui.Destroy())

    confirmGui.Show("AutoSize Center")
    WinActivate("Confirm Deletion")

    while WinExist("Confirm Deletion")
        Sleep(50)

    return confirmed
}

; === First-Time Setup ===
if !FileExist(iniFile) {
    FileAppend("", iniFile)

    defaultHotkey := PromptForHotkey()
    if defaultHotkey = ""
        ExitApp

    downVal := PromptForDownCount()
    if !IsInteger(downVal)
        ExitApp

    IniWrite(defaultHotkey, iniFile, "Settings", "Hotkey")
    IniWrite(downVal, iniFile, "Settings", "DownCount")
    IniWrite("false", iniFile, silentSection, defaultHotkey)
}

PromptForHotkey() {
    chosen := ""
    PromptHotkey("Choose Initial Hotkey", "^!m", "", (hk, _) => chosen := hk, false)
    WinWaitClose("Choose Initial Hotkey")
    return chosen
}

PromptForDownCount() {
    dcGui := Gui()
    dcGui.Opt("+AlwaysOnTop")
    dcGui.Title := "Set Context Menu Offset"
    dcGui.SetFont("s10")
    dcGui.Add("Text", , "How many times should I press Down to reach 'Copy link address'?")
    input := dcGui.Add("Edit", "w200", "2")
    ok := false
    dcGui.Add("Button", "w80 Default", "Save").OnEvent("Click", (*) => (ok := true, dcGui.Submit()))
    dcGui.Add("Button", "x+10 w80", "Cancel").OnEvent("Click", (*) => dcGui.Destroy())
    dcGui.Show()
    WinWaitClose(dcGui.Hwnd)
    return ok ? input.Value : ""
}

Hotkey(IniRead(iniFile, "Settings", "Hotkey"), (*) => ShowHotkeyManager())
OpenReadme() {
    readmeText := "
    (
🧠 Send2Discord – Smart Hotkey Mention Launcher

This script lets you send hovered links to Discord using customizable hotkeys, with optional @mentions and Silent Mode.

📦 Features
- Hotkey binding for link sharing
- GUI-based mention manager
- Silent Mode toggle per hotkey.  Toggle this if you're not pinging users for faster posting
- INI-based storage
- Works with Discord for quick pasting

🚀 How It Works
1. Simulates right-click at the current mouse position
2. Presses Down a configurable number of times, depending on your browser
3. Triggers 'Copy link address'
4. Switches to Discord, pastes the link
5. Types mentions (unless Silent Mode is enabled)

📝 Notes
- No need to type @ when adding mentions
- Clipboard is restored afterward
- GUI allows easy hotkey configuration


    )"

    readmeGui := Gui("+Resize +AlwaysOnTop", "Send2Discord – Help")
    readmeGui.SetFont("s10", "Segoe UI")
    readmeEdit := readmeGui.Add("Edit", "R30 W700 ReadOnly -Wrap VScroll HScroll")
    readmeEdit.Value := readmeText
    readmeGui.Show()
}
LoadHotkeys()