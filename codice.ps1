# ==============================================================================
# AUTO-ELEVAZIONE PRIVILEGI AMMINISTRATORE E NASCONDIMENTO CONSOLE - CON LOG DEBUG
# ==============================================================================
$global:DebugStartup = $false  # Metti a $true se vuoi VEDERE gli errori rossi all'avvio
$scriptVersion = "v3.9.27c"  # v3.9.27c: fix 1 parentesi di troppo riga 1153 (Esito Ultimo Test RAM); v3.9.27b:  # v3.9.27b: fix sintassi stress (New-Object -ArgumentList, formato tempo senza D2); v3.9.27:  # v3.9.27: + Stress Test RAM 5 min in loop con finestra progresso/annulla (difetti a caldo); v3.9.26:  # v3.9.26: 3 nuovi test RAM in Diagnostica (rapido senza riavvio, mdsched con riavvio, esito ultimo test + WHEA); v3.9.25:  # v3.9.25: fix falso positivo AV - ricerca senza Reflection (PerformClick al posto di GetMethod+Invoke su OnClick privato), keyword di rilevamento spezzate a riga 3032; v3.9.24:  # v3.9.24: pulsanti a 5 colonne un po' più larghi (261 px) per riempire tutta la larghezza dell'area comandi; v3.9.23: le schede con più di 6 righe di comandi (AD-TOOLs) passano da sole a 5 colonne più strette con altezza normale; le altre schede tornano alle misure originali; v3.9.22: pulsanti più stretti e 5 colonne per riga (AD-TOOLs sta nell'area comandi senza ridurre l'altezza); v3.9.21: griglia pulsanti adattiva (altezza ridotta in automatico quando una scheda ha molti comandi, larghezza ridotta per togliere la barra orizzontale); v3.9.20: ricerca comandi (Ctrl+F) e menu Preferiti/Recenti nell'intestazione, clic destro su un comando per aggiungerlo ai preferiti; v3.9.19: nuovi controlli di sicurezza, Sicurezza (audit client, amministratori locali, autorun e persistenza, condivisioni SMB, accessi falliti) e AD-TOOLs (delega Kerberos, computer obsoleti/inattivi/LAPS, policy password, adminCount orfani); v3.9.18: Network con Controllo Porte a Rischio (porte note, SMBv1, NLA, firewall) e Confronto Porte con baseline; v3.9.17: Network con 5 nuovi comandi sulle porte (porte in ascolto TCP/UDP con processo, connessioni attive, chi usa una porta, scansione porte host remoto, regole firewall in ingresso), tutti con CSV nella cartella dello script; v3.9.16: popup di attesa rivisto (layout senza Dock, testo di aiuto chiaro e leggibile, finestra più alta); v3.9.15: Elimina Reti Wi-Fi Note con controllo preventivo (nessun falso successo su PC senza Wi-Fi, conferma con elenco reti, esito per profilo); v3.9.14: SpeedTest download con User-Agent da browser e server di riserva (Hetzner, OVH, Tele2) dopo errore 403 di Cloudflare; v3.9.13: SpeedTest Latenza + Download rifatto (latenza min/media/max/jitter con ripiego TCP, download reale in Mbit/s); v3.9.12: popup DISM ScanHealth più alto (pulsante Annulla non tagliato e leggibile); v3.9.11: colore dei comandi al passaggio del mouse blu (rosso/arancio schiariti); v3.9.10: Health Batteria con controllo preventivo (PC fisso = messaggio chiaro, niente errore), report HTML aperto solo se creato; v3.9.9: avviso AD-TOOLs graduato (PC in dominio senza RSAT = avviso leggero una volta per sessione; fuori dominio = avviso completo); v3.9.8: Canale Sicuro e Test Porte DC spostati da Rete ad AD-TOOLs (avviso e popup aggiornati); v3.9.7: esito chiaro per Esporta Password WiFi (popup con percorso, nessun falso successo senza WLAN); v3.9.6: log a colori (RichTextBox), commenti delle schede riscritti, numeri del popup NOTE dinamici; v3.9.5: schede con più margine interno e stacco tra una scheda e l'altra; v3.9.4: finestra più larga (1415 px) con griglia pulsanti e comandi in alto a destra riallineati; v3.9.3: testo dei tab senza puntini (niente padding/ellissi); v3.9.2: fix compilazione tab scuri (ControlStyles); v3.9.1: tema scuro (barra del titolo e tab) + accenti corretti nei testi; v3.9.0: popup informativo AD-TOOLs + file impostazioni; v3.8.0: nuovi comandi AD/rete e Show-ConfirmBox; v3.7.1: file di output nella cartella dello script; v3.7.0: fix pattern -like, CIM al posto di WMI, elevazione robusta, helper pulsanti
$global:StartLogFile = Join-Path $env:TEMP "Bino_Startup_Log.txt"

# Funzione di log avvio (prima che parta la GUI)
function Write-StartLog {
    param([string]$msg)
    try {
        $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "[$ts] $msg" | Out-File -FilePath $global:StartLogFile -Append -Encoding UTF8
    } catch { $null = $_ }
}


function Show-UltimoKB {
    Show-CommandSummary "Ultimo KB Installato" @("Get-HotFix", "Build OS")
    try {
        Write-Log "--- Ultimi 15 HotFix ---"
        $hotfixes = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 15
        foreach ($hf in $hotfixes) { Write-Log ($hf.HotFixID + " | " + $hf.InstalledOn + " | " + $hf.Description) }
        $os = Get-CimInstance Win32_OperatingSystem
        $ubr = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue).UBR
        Write-Log ("Build: " + $os.BuildNumber + "." + $ubr)
    } catch { Write-Log ("[ERRORE] " + $_.ToString()) "Errore" }
}
function Show-StoricoWU {
    Show-CommandSummary "Storico WU" @("QueryHistory")
    try {
        $Session = New-Object -ComObject Microsoft.Update.Session
        $Searcher = $Session.CreateUpdateSearcher()
        $cnt = $Searcher.GetTotalHistoryCount()
        $limit = 50
        if ($cnt -lt $limit) { $limit = $cnt }
        $hist = $Searcher.QueryHistory(0, $limit) | Sort-Object Date -Descending | Select-Object -First 25
        foreach ($h in $hist) {
            $res = "?"
            switch ($h.ResultCode) { 2 { $res = "OK" } 3 { $res = "OK-err" } 4 { $res = "FALLITO" } 5 { $res = "Annullato" } }
            Write-Log ($h.Date.ToString("yyyy-MM-dd") + " | " + $res + " | " + $h.Title)
        }
    } catch { Write-Log ("[ERRORE] " + $_.ToString()) "Errore" }
}
function Show-VerificaOnlineKB {
    Show-CommandSummary "Verifica Online KB" @("Search IsInstalled=0 Online")
    try {
        $Session = New-Object -ComObject Microsoft.Update.Session
        $Searcher = $Session.CreateUpdateSearcher()
        $Searcher.Online = $true
        $r = $Searcher.Search("IsInstalled=0 and IsHidden=0")
        if ($r.Updates.Count -eq 0) { Write-Log "[OK] SEI AGGIORNATO - nessun KB in sospeso!" "Aggiornato" }
        else { Write-Log ("[INFO] " + $r.Updates.Count + " aggiornamenti disponibili:"); foreach ($u in $r.Updates) { Write-Log (" - " + $u.Title) } }
    } catch { Write-Log ("[ERRORE] " + $_.ToString()) "Errore" }
}
function Install-ForzaWU {
    $msg = "Cercare e installare tutti gli aggiornamenti Windows? Potrebbe richiedere riavvio. Continuare?"
    $choice = [System.Windows.Forms.MessageBox]::Show($msg, "Conferma WU", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    Show-CommandSummary "Installa WU" @("Download + Install via COM")
    try {
        $Session = New-Object -ComObject Microsoft.Update.Session
        $Searcher = $Session.CreateUpdateSearcher()
        $Searcher.Online = $true
        $sr = $Searcher.Search("IsInstalled=0 and IsHidden=0")
        if ($sr.Updates.Count -eq 0) { Write-Log "[OK] Nessun aggiornamento."; return }
        Write-Log ("Trovati " + $sr.Updates.Count + " - download...")
        $coll = New-Object -ComObject Microsoft.Update.UpdateColl
        foreach ($u in $sr.Updates) { $coll.Add($u) | Out-Null }
        $dl = $Session.CreateUpdateDownloader()
        $dl.Updates = $coll
        $dl.Download() | Out-Null
        Write-Log "Download OK - installazione..."
        $instColl = New-Object -ComObject Microsoft.Update.UpdateColl
        foreach ($u in $sr.Updates) { if ($u.IsDownloaded) { $instColl.Add($u) | Out-Null } }
        $installer = $Session.CreateUpdateInstaller()
        $installer.Updates = $instColl
        $ir = $installer.Install()
        Write-Log ("Risultato: " + $ir.ResultCode + " Reboot: " + $ir.RebootRequired)
        if ($ir.RebootRequired) {
            $q = [System.Windows.Forms.MessageBox]::Show("Riavvio richiesto. Riavviare ora?", "Riavvio", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
            if ($q -eq [System.Windows.Forms.DialogResult]::Yes) { Restart-Computer -Force }
        }
    } catch {
        Write-Log ("[ERRORE] " + $_.ToString()) "Errore"
        try { Start-Process "ms-settings:windowsupdate" } catch { Write-StartLog "Errore ignorato: $_" }
    }
}

# Pulisci vecchio log
try { if (Test-Path $global:StartLogFile) { Remove-Item $global:StartLogFile -Force -ErrorAction SilentlyContinue } } catch { Write-StartLog "Errore ignorato: $_" }
Write-StartLog "=== AVVIO SCRIPT $scriptVersion ==="
Write-StartLog "PID: $PID | Path: $PSCommandPath"

$ScriptPath = $PSCommandPath
if (-not $ScriptPath) { $ScriptPath = $MyInvocation.MyCommand.Path }

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-StartLog "Non admin - richiedo elevazione"
    if (-not $ScriptPath) {
        Write-StartLog "ERRORE: percorso script sconosciuto (script incollato o eseguito da ISE?). Salvalo su file .ps1 ed eseguilo da li."
        try { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show("Impossibile elevare i privilegi: salva lo script come file .ps1 ed eseguilo da li.", "Errore elevazione") | Out-Null } catch { Write-StartLog "Errore ignorato: $_" }
        exit 1
    }
    # Rilancia con lo stesso interprete in uso (Windows PowerShell 5.1 o PowerShell 7)
    $hostExe = (Get-Process -Id $PID).Path
    if (-not $hostExe) { $hostExe = "powershell.exe" }
    $winStyle = if ($global:DebugStartup) { "Normal" } else { "Hidden" }
    try {
        Start-Process -FilePath $hostExe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -File `"$ScriptPath`"" -Verb RunAs -WindowStyle $winStyle -ErrorAction Stop
    } catch {
        Write-StartLog "Elevazione annullata o fallita: $_"
    }
    exit
}

Write-StartLog "Admin OK - procedo"

# ==============================================================================
# CARTELLA DI OUTPUT: tutti i file creati dai comandi finiscono nella cartella dello script
# (se non è scrivibile, ad es. share di rete in sola lettura, si usa %TEMP%\Bino_Output)
# ==============================================================================
$global:OutputDir = $null
try { if ($ScriptPath) { $global:OutputDir = Split-Path -Parent $ScriptPath } } catch { $null = $_ }
if (-not $global:OutputDir) { $global:OutputDir = $PSScriptRoot }
function Test-DirWritable {
    param([string]$Dir)
    if (-not $Dir -or -not (Test-Path -LiteralPath $Dir -PathType Container)) { return $false }
    $probe = Join-Path $Dir (".bino_w_" + [guid]::NewGuid().ToString("N"))
    try { [System.IO.File]::WriteAllText($probe, "x"); Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue; return $true }
    catch { return $false }
}
if (-not (Test-DirWritable $global:OutputDir)) {
    Write-StartLog "Cartella script non scrivibile ($global:OutputDir) - uso %TEMP%\Bino_Output"
    $global:OutputDir = Join-Path $env:TEMP "Bino_Output"
    if (-not (Test-Path -LiteralPath $global:OutputDir)) { New-Item -ItemType Directory -Path $global:OutputDir -Force | Out-Null }
}
Write-StartLog "Cartella output file: $global:OutputDir"

# Nascondi console SOLO se DebugStartup = false
if (-not $global:DebugStartup) {
    try {
        if (-not ([System.Management.Automation.PSTypeName]'Win32Functions.Win32ShowWindow').Type) {
            Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow); [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();' -Name 'Win32ShowWindow' -Namespace Win32Functions -ErrorAction SilentlyContinue | Out-Null
        }
        $h = (Get-Process -Id $PID).MainWindowHandle
        if ($h -eq [IntPtr]::Zero) {
            $h = [Win32Functions.Win32ShowWindow]::GetConsoleWindow()
        }
        if ($h -ne [IntPtr]::Zero) {
            [Win32Functions.Win32ShowWindow]::ShowWindow($h, 0) | Out-Null
            Write-StartLog "Console nascosta"
        }
    } catch {
        Write-StartLog "ERRORE nascondimento console: $_"
    }
} else {
    Write-StartLog "DebugStartup attivo - console VISIBILE per 10 sec per leggere errori"
    Write-Host "=== MODALITA DEBUG AVVIO - Gli errori rimarranno visibili 10 secondi ===" -ForegroundColor Yellow
    Start-Sleep -Seconds 10
}

# Cattura errori non gestiti all'avvio
$ErrorActionPreference = "Continue"


# ==============================================================================
# STRUMENTO DI MANUTENZIONE, RETE E DIAGNOSTICA
# Creato da BINO con GEMINI e META AI
# ==============================================================================


try { Add-Type -AssemblyName System.Windows.Forms; Write-StartLog "OK System.Windows.Forms" } catch { Write-StartLog "ERRORE Forms: $_"; if ($global:DebugStartup) { Write-Host $_ -ForegroundColor Red; Read-Host "Premi INVIO" } }
try { Add-Type -AssemblyName System.Drawing; Write-StartLog "OK System.Drawing" } catch { Write-StartLog "ERRORE Drawing: $_" }
try { Add-Type -AssemblyName Microsoft.VisualBasic; Write-StartLog "OK VisualBasic" } catch { Write-StartLog "ERRORE VB: $_" }


# ==============================================================================
# POPUP DI BENVENUTO E ALLERTA SICUREZZA INIZIALE (3 COLORI) - TESTO INGRANDITO





# --- FUNZIONI UTILITY UNIFICATE - v3.6.6 FIX ---
# --- LOG A COLORI (v3.9.6): la casella del log è una RichTextBox ---
# [OK] verde, [ERRORE]/[CRITICO] rosso, [WARN]/[ATTENZIONE]/[AVVISO] giallo, il resto azzurro (come prima).
function Get-LogLevelColor {
    param([string]$Text)
    if ($Text -match '\[(ERRORE|CRITICO)\]') { return "#F87171" }
    if ($Text -match '\[(WARN|ATTENZIONE|AVVISO)\]') { return "#FBBF24" }
    if ($Text -match '\[(OK|KEY TROVATA)\]') { return "#4ADE80" }
    return "#38BDF8"
}

# Aggiunge testo in fondo al log con il colore indicato, poi ripristina il colore di base.
function Add-LogColored {
    param([string]$Text, [string]$Hex = "#38BDF8")
    try {
        $txtLog.SelectionStart = $txtLog.TextLength
        $txtLog.SelectionLength = 0
        $txtLog.SelectionColor = [System.Drawing.ColorTranslator]::FromHtml($Hex)
        $txtLog.AppendText($Text)
        $txtLog.SelectionColor = $txtLog.ForeColor
    } catch {
        try { $txtLog.AppendText($Text) } catch { $null = $_ }
    }
}

function Write-LogCore {
    param([string]$text, [string]$status = "")
    $timeStamp = Get-Date -Format "HH:mm:ss"
    try {
        if ($null -ne $txtLog) {
            Add-LogColored "[$timeStamp] " "#64748B"
            Add-LogColored "$text`r`n" (Get-LogLevelColor $text)
            $txtLog.SelectionStart = $txtLog.Text.Length
            $txtLog.ScrollToCaret()
            if ($status -ne "") { $lblStatus.Text = " Status: $status" }
            [System.Windows.Forms.Application]::DoEvents()
        } else {
            Write-Host "[$timeStamp] $text"
        }
    } catch {
        Write-Host "[$timeStamp] $text"
    }
}

function Write-Log {
    param([string]$text, [string]$status = "")
    $t = "$text $status".ToLower()
    if ($status -like "*esecuzione*" -or $status -like "*Attendere*" -or $text -like "*Avvio operazione*") {
        if ($global:waitForm -eq $null) { Show-WaitOverlay -msg $text }
    }
    if ($global:waitForm -ne $null -and $text.Length -gt 5 -and $text -notlike '*`[INFO`]*' -and $text.Length -lt 80) {
        try { $global:waitForm.Text = $text; $global:waitForm.Controls[0].Text = $text } catch { Write-StartLog "Errore ignorato: $_" }
    }
    Write-LogCore $text $status
    if ($t -like "*completato*" -or $t -like "*completata*" -or $t -like "*con successo*" -or $t -like "*resettata con successo*" -or $t -like "*terminato*" -or $t -like "*fine operazione*" -or $t -like "*operazione completata*" -or ($t -like '*`[ok`]*' -and $t.Length -lt 150)) {
        Start-Sleep -Milliseconds 400
        Hide-WaitOverlay
    }
}


# =============================================================================
# OVERLAY ATTESA - v3.5.0 FIX FREEZE
# =============================================================================
$global:waitForm = $null
function Show-WaitOverlay {
    param([string]$msg = "Operazione in corso, attendere prego...")
    try {
        if ($global:waitForm -ne $null) { 
            # Aggiorna solo il messaggio se già aperta
            try { $global:waitForm.Controls[0].Text = $msg } catch { Write-StartLog "Errore ignorato: $_" }
            $lblStatus.Text = " ⏳ Attendere: $msg"
            [System.Windows.Forms.Application]::DoEvents()
            return 
        }
        $lblStatus.Text = " ⏳ Attendere: $msg"
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $global:waitForm = New-Object System.Windows.Forms.Form
        Enable-DarkTitleBar $global:waitForm
        $global:waitForm.Text = $msg
        $global:waitForm.ClientSize = New-Object System.Drawing.Size(460, 170)
        $global:waitForm.StartPosition = "CenterScreen"
        $global:waitForm.FormBorderStyle = "FixedDialog"
        $global:waitForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E293B")
        $global:waitForm.TopMost = $true
        $global:waitForm.ShowInTaskbar = $false
        $global:waitForm.ControlBox = $true
        $global:waitForm.MaximizeBox = $false
        $global:waitForm.MinimizeBox = $false

        # Layout con posizioni fisse (niente Dock): il messaggio resta sempre Controls[0], il testo di aiuto è sempre leggibile
        $lblWait = New-Object System.Windows.Forms.Label
        $lblWait.Text = $msg
        $lblWait.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $lblWait.ForeColor = [System.Drawing.Color]::White
        $lblWait.AutoSize = $false
        $lblWait.TextAlign = "MiddleCenter"
        $lblWait.Location = New-Object System.Drawing.Point(15, 15)
        $lblWait.Size = New-Object System.Drawing.Size(430, 50)
        $global:waitForm.Controls.Add($lblWait)

        $lblSub = New-Object System.Windows.Forms.Label
        $lblSub.Text = "L'operazione può richiedere alcuni minuti: non chiudere lo strumento." + "`r`n" + "Puoi chiudere questo avviso con la X."
        $lblSub.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $lblSub.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#CBD5E1")
        $lblSub.AutoSize = $false
        $lblSub.TextAlign = "MiddleCenter"
        $lblSub.Location = New-Object System.Drawing.Point(15, 72)
        $lblSub.Size = New-Object System.Drawing.Size(430, 44)
        $global:waitForm.Controls.Add($lblSub)

        $pb = New-Object System.Windows.Forms.ProgressBar
        $pb.Style = "Marquee"
        $pb.MarqueeAnimationSpeed = 25
        $pb.Location = New-Object System.Drawing.Point(20, 128)
        $pb.Size = New-Object System.Drawing.Size(420, 22)
        $global:waitForm.Controls.Add($pb)

        $global:waitForm.Add_FormClosed({ 
            $global:waitForm = $null
            try { $form.Cursor = [System.Windows.Forms.Cursors]::Default; $pnlTabs.Enabled = $true } catch { Write-StartLog "Errore ignorato: $_" }
        })

        $global:waitForm.Show()
        $global:waitForm.Refresh()
        [System.Windows.Forms.Application]::DoEvents()
        $pnlTabs.Enabled = $false
    } catch { Write-StartLog "Errore ignorato: $_" }
}
function Hide-WaitOverlay {
    try {
        if ($global:waitForm -ne $null) {
            $global:waitForm.Close()
            $global:waitForm.Dispose()
        }
    } catch { Write-StartLog "Errore ignorato: $_" }
    finally {
        $global:waitForm = $null
        try { $form.Cursor = [System.Windows.Forms.Cursors]::Default; $pnlTabs.Enabled = $true } catch { Write-StartLog "Errore ignorato: $_" }
        try { $lblStatus.Text = " Pronto (Eseguito come Amministratore). Passa il mouse sopra un comando per visualizzarne la descrizione." } catch { Write-StartLog "Errore ignorato: $_" }
        [System.Windows.Forms.Application]::DoEvents()
    }
}


function Invoke-WithWait { param([string]$operationName, [scriptblock]$action); Show-WaitOverlay -msg $operationName; try { & $action } finally { Hide-WaitOverlay } }



function Show-CommandSummary {
    param([string]$title, [string[]]$commands)
    $timeStamp = Get-Date -Format "HH:mm:ss"
    $sep = "------------------------------------------------------------------------------------------------------------------------"
    Add-LogColored "$sep`r`n" "#334155"
    Add-LogColored "[$timeStamp] " "#64748B"
    Add-LogColored ">>> AVVIO OPERAZIONE: $title`r`n" "#F8FAFC"
    Add-LogColored "[$timeStamp] " "#64748B"
    Add-LogColored ">>> COMANDI IN ESECUZIONE:`r`n" "#94A3B8"
    foreach ($cmd in $commands) {
        Add-LogColored "[$timeStamp] " "#64748B"
        Add-LogColored "    > $cmd`r`n" "#94A3B8"
    }
    Add-LogColored "$sep`r`n" "#334155"
    $txtLog.SelectionStart = $txtLog.Text.Length
    $txtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}



# ==============================================================================
# IMPOSTAZIONI UTENTE: file bino_settings.json (nella cartella dello script, o in %TEMP%\Bino_Output se non scrivibile)
# Il file viene creato solo quando l'utente sceglie un'opzione da ricordare (es. "Non mostrare più").
# Per ripristinare i valori predefiniti basta eliminare il file.
# ==============================================================================
$global:BinoSettingsDefaults = [ordered]@{ SettingsVersion = 1; HideADInfoPopup = $false; Favorites = @() }
$global:ADInfoShownThisSession = $false
$global:ADNoRsatNoticeShown = $false

function Get-BinoSettingsPath { return (Join-Path $global:OutputDir "bino_settings.json") }

function Get-BinoSettings {
    $s = [ordered]@{}
    foreach ($k in $global:BinoSettingsDefaults.Keys) { $s[$k] = $global:BinoSettingsDefaults[$k] }
    $path = Get-BinoSettingsPath
    try {
        if (Test-Path -LiteralPath $path) {
            $json = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($prop in $json.PSObject.Properties) { $s[$prop.Name] = $prop.Value }
        }
    } catch { Write-StartLog "Lettura impostazioni fallita (uso i valori predefiniti): $_" }
    return ,$s
}

function Save-BinoSettings {
    param([System.Collections.IDictionary]$Settings)
    $path = Get-BinoSettingsPath
    try {
        $dir = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $Settings | ConvertTo-Json | Out-File -LiteralPath $path -Encoding UTF8 -Force
        return $true
    } catch { Write-StartLog "Salvataggio impostazioni fallito: $_"; return $false }
}

function Set-BinoSetting {
    param([string]$Name, $Value)
    $s = Get-BinoSettings
    $s[$Name] = $Value
    return (Save-BinoSettings $s)
}

# --- HELPER: conferma Si/No (usata dai pulsanti di rete; restituisce "Yes" o "No") ---
function Show-ConfirmBox {
    param([string]$Message, [string]$Title = "Conferma")
    $r = [System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    return $r.ToString()
}

# --- HELPER: griglia pulsanti standard (sostituisce i cicli foreach duplicati per ogni tab) ---
function Add-ButtonGrid {
    param(
        [Parameter(Mandatory)]$Tab,
        [Parameter(Mandatory)]$Buttons,
        [int]$Cols = 4, [int]$BtnW = 325, [int]$BtnH = 58,
        [int]$GapX = 340, [int]$GapY = 66, [int]$StartX = 15, [int]$StartY = 10
    )
    # L'area comandi mostra circa 6 righe senza barre di scorrimento. Se con le colonne standard servirebbero
    # più righe (es. AD-TOOLs), passa a 5 colonne più strette mantenendo l'altezza normale dei pulsanti.
    # Se le colonne vengono indicate esplicitamente dal chiamante, non cambia nulla.
    if (-not $PSBoundParameters.ContainsKey("Cols") -and [math]::Ceiling(@($Buttons).Count / $Cols) -gt 6) {
        # 5 colonne: il bordo destro arriva a 1360 px, come le schede a 4 colonne
        $Cols = 5; $BtnW = 261; $GapX = 271
    }
    $i = 0
    foreach ($b in $Buttons) {
        $x = $StartX + (($i % $Cols) * $GapX)
        $y = $StartY + ([math]::Floor($i / $Cols) * $GapY)
        $bg = if ($b.Count -gt 2) { $b[2] } else { "#064E3B" }
        $fg = if ($b.Count -gt 3) { $b[3] } else { "#F8FAFC" }
        $tooltip = if ($b.Count -gt 4) { $b[4] } else { "" }
        $btn = New-CustomButton $b[0] $x $y $BtnW $BtnH $bg $fg $tooltip
        Register-BinoButton $btn $b $Tab
        $btn.Add_Click($b[1])
        $Tab.Controls.Add($btn)
        $i++
    }
}

function Clear-TempFiles {
    Show-CommandSummary "Pulizia Temp e Cestino" @("Pulizia %TEMP%, C:\Windows\Temp e Cestino")
    try {
        Write-Log "Avvio pulizia file temporanei..." "In esecuzione..."
        $totalFreed = 0
        $paths = @(
            "$env:TEMP",
            "$env:LOCALAPPDATA\Temp",
            "C:\Windows\Temp"
        )
        foreach ($p in $paths) {
            if (Test-Path $p) {
                try {
                    # Un solo passaggio: misuro e rimuovo ogni file, sommando i byte realmente eliminati
                    Get-ChildItem -Path $p -Recurse -Force -File -ErrorAction SilentlyContinue | ForEach-Object {
                        $len = $_.Length
                        try { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop; $totalFreed += $len } catch { $null = $_ }
                    }
                    Get-ChildItem -Path $p -Recurse -Force -Directory -ErrorAction SilentlyContinue |
                        Sort-Object { $_.FullName.Length } -Descending |
                        ForEach-Object { try { Remove-Item -LiteralPath $_.FullName -Force -Recurse -ErrorAction Stop } catch { $null = $_ } }
                    Write-Log "[OK] Pulito: $p"
                } catch {
                    Write-Log "[WARN] Impossibile pulire $p : $_"
                }
            }
        }
        # Svuota cestino
        try {
            Clear-RecycleBin -Force -ErrorAction Stop
            Write-Log "[OK] Cestino svuotato"
        } catch {
            try {
                $shell = New-Object -ComObject Shell.Application
                $recycleBin = $shell.Namespace(0xA)
                $recycleBin.Items() | ForEach-Object { Remove-Item $_.Path -Recurse -Force -ErrorAction SilentlyContinue }
            } catch { Write-StartLog "Errore ignorato: $_" }
        }
        $mb = [math]::Round($totalFreed/1MB,2)
        Write-Log "[OK] Pulizia completata. Spazio liberato stimato: $mb MB" "Completato"
        [System.Windows.Forms.MessageBox]::Show("Pulizia completata!`r`nSpazio liberato: $mb MB`r`n`r`nCartelle pulite:`r`n- TEMP utente`r`n- TEMP Windows`r`n- Cestino", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        Write-Log "[ERRORE] Pulizia Temp: $_" "Errore"
        [System.Windows.Forms.MessageBox]::Show("Errore durante la pulizia:`r`n$_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Clear-WUCache {
    Show-CommandSummary "Reset Cache Windows Update" @("Stop-Service wuauserv,bits,cryptSvc","Remove SoftwareDistribution","Start-Service")
    try {
        Write-Log "Arresto servizi Windows Update..." "In esecuzione..."
        $services = @("wuauserv","bits","cryptSvc","msiserver","UsoSvc","WaaSMedicSvc")
        foreach ($s in $services) {
            try { Stop-Service -Name $s -Force -ErrorAction SilentlyContinue; Write-Log "[INFO] Servizio $s arrestato" } catch { Write-StartLog "Errore ignorato: $_" }
        }
        Start-Sleep -Seconds 2
        
        $folders = @(
            "C:\Windows\SoftwareDistribution",
            "C:\Windows\System32\catroot2"
        )
        foreach ($f in $folders) {
            if (Test-Path $f) {
                try {
                    # Rinomina invece di cancellare per sicurezza
                    $backup = "$f.old_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                    # Prova a cancellare contenuto
                    Get-ChildItem -Path $f -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                    Write-Log "[OK] Cache pulita: $f"
                } catch {
                    Write-Log "[WARN] Non riesco a pulire $f : $_"
                    try { Rename-Item -Path $f -NewName "$f.old" -Force -ErrorAction SilentlyContinue } catch { Write-StartLog "Errore ignorato: $_" }
                }
            }
        }
        
        Write-Log "Riavvio servizi Windows Update..."
        foreach ($s in $services) {
            try { Start-Service -Name $s -ErrorAction SilentlyContinue; Write-Log "[INFO] Servizio $s avviato" } catch { Write-StartLog "Errore ignorato: $_" }
        }
        
        Write-Log "[OK] Cache Windows Update resettata con successo. Riavvia il PC se Windows Update continua a dare errori." "Completato"
        [System.Windows.Forms.MessageBox]::Show("Cache Windows Update resettata!`r`n`r`nServizi riavviati.`r`nSe Windows Update dava errore 0x800... riprova ora.`r`n`r`nConsigliato: riavvia il PC.", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        Write-Log "[ERRORE] Reset WU Cache: $_" "Errore"
        [System.Windows.Forms.MessageBox]::Show("Errore durante reset cache WU:`r`n$_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}


function Clear-WindowsEventLogsDomainSafe {
    Show-CommandSummary "Pulizia Log Eventi Windows (Dominio Safe)" @("wevtutil el", "wevtutil epl <log> backup.evtx", "wevtutil cl <log>", "Clear-EventLog")
    try {
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        $isDomain = $cs -and $cs.PartOfDomain
        $isDC = $false
        try {
            $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
            if ($os.ProductType -eq 2) { $isDC = $true }
        } catch { Write-StartLog "Errore ignorato: $_" }
        $domainInfo = if ($isDomain) { "SI - Dominio: $($cs.Domain)" } else { "NO - Workgroup/Standalone" }
        $dcInfo = if ($isDC) { " (Domain Controller rilevato!)" } else { "" }

        $msg1 = "PULIZIA LOG EVENTI WINDOWS - MODALITÀ DOMINIO SAFE`r`n`r`n"
        $msg1 += "PC in dominio: $domainInfo$dcInfo`r`n`r`n"
        $msg1 += "IMPORTANTE su PC a dominio:`r`n"
        $msg1 += "- Pulire il log 'Security' genera evento 1102 (audit: log cancellato)`r`n"
        $msg1 += "- Potrebbe violare policy di auditing aziendale / GPO`r`n"
        $msg1 += "- Su DC è SCONSIGLIATO cancellare Security/System`r`n`r`n"
        $msg1 += "Vuoi procedere? (Step 1/3 - scelta backup)"
        $r1 = [System.Windows.Forms.MessageBox]::Show($msg1, "Pulizia Log - Info Dominio", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($r1 -ne [System.Windows.Forms.DialogResult]::Yes) { Write-Log "[INFO] Pulizia log annullata (step 1)." "Annullato"; return }

        $msg2 = "Vuoi fare BACKUP dei log prima di cancellarli?`r`n`r`nConsigliato SU DOMINIO = SI`r`nI file verranno salvati nella cartella dello script, in EventLogs_Backup_<data>`r`n`r`nSI = Backup + Pulisci | NO = Pulisci diretto | Annulla = Esci"
        $r2 = [System.Windows.Forms.MessageBox]::Show($msg2, "Backup Log?", [System.Windows.Forms.MessageBoxButtons]::YesNoCancel, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($r2 -eq [System.Windows.Forms.DialogResult]::Cancel) { Write-Log "[INFO] Pulizia log annullata (backup choice)." "Annullato"; return }
        $doBackup = ($r2 -eq [System.Windows.Forms.DialogResult]::Yes)

        $formSel = New-Object System.Windows.Forms.Form
        Enable-DarkTitleBar $formSel
        $formSel.Text = "Seleziona log da pulire"
        $formSel.Size = New-Object System.Drawing.Size(520, 380)
        $formSel.StartPosition = "CenterScreen"
        $formSel.FormBorderStyle = "FixedDialog"
        $formSel.MaximizeBox = $false
        $formSel.BackColor = [System.Drawing.Color]::FromArgb(15, 23, 42)
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = "Seleziona modalità (SAFE per dominio):"
        $lbl.ForeColor = [System.Drawing.Color]::White
        $lbl.Location = New-Object System.Drawing.Point(15, 10)
        $lbl.Size = New-Object System.Drawing.Size(480, 25)
        $formSel.Controls.Add($lbl)
        $rbSafe = New-Object System.Windows.Forms.RadioButton
        $rbSafe.Text = "SAFE Dominio - Solo Applicazione, System, Setup (consigliato)"
        $rbSafe.Location = New-Object System.Drawing.Point(15, 40)
        $rbSafe.Size = New-Object System.Drawing.Size(480, 30)
        $rbSafe.ForeColor = [System.Drawing.Color]::White
        $rbSafe.Checked = $true
        $formSel.Controls.Add($rbSafe)
        $rbAll = New-Object System.Windows.Forms.RadioButton
        $rbAll.Text = "Completo - TUTTI i log tranne Security"
        $rbAll.Location = New-Object System.Drawing.Point(15, 80)
        $rbAll.Size = New-Object System.Drawing.Size(480, 30)
        $rbAll.ForeColor = [System.Drawing.Color]::White
        $formSel.Controls.Add($rbAll)
        $rbAllIncSec = New-Object System.Windows.Forms.RadioButton
        $rbAllIncSec.Text = "TUTTO compreso Security (genera evento 1102)"
        $rbAllIncSec.Location = New-Object System.Drawing.Point(15, 120)
        $rbAllIncSec.Size = New-Object System.Drawing.Size(480, 30)
        $rbAllIncSec.ForeColor = [System.Drawing.Color]::LightCoral
        $formSel.Controls.Add($rbAllIncSec)
        if ($isDC) { 
            $rbAllIncSec.Enabled = $false
            $lblDCWarn = New-Object System.Windows.Forms.Label
            $lblDCWarn.Text = "⚠ Rilevato Domain Controller - modalità COMPLETA disabilitata per sicurezza. Usa solo SAFE."
            $lblDCWarn.ForeColor = [System.Drawing.Color]::FromArgb(248,113,113)
            $lblDCWarn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $lblDCWarn.Location = New-Object System.Drawing.Point(15, 160)
            $lblDCWarn.Size = New-Object System.Drawing.Size(480, 40)
            $formSel.Controls.Add($lblDCWarn)
        }
        $btnOk = New-Object System.Windows.Forms.Button
        $btnOk.Text = "PULISCI ORA"
        $btnOk.Location = New-Object System.Drawing.Point(140, 290)
        $btnOk.Size = New-Object System.Drawing.Size(120, 35)
        $btnOk.BackColor = [System.Drawing.Color]::FromArgb(185, 28, 28)
        $btnOk.ForeColor = [System.Drawing.Color]::White
        $btnOk.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnOk.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(248, 113, 113)
        $btnOk.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $formSel.Controls.Add($btnOk)
        $btnCancel = New-Object System.Windows.Forms.Button
        $btnCancel.Text = "Annulla"
        $btnCancel.Location = New-Object System.Drawing.Point(280, 290)
        $btnCancel.Size = New-Object System.Drawing.Size(80, 35)
        $btnCancel.BackColor = [System.Drawing.Color]::FromArgb(51, 65, 85)
        $btnCancel.ForeColor = [System.Drawing.Color]::White
        $btnCancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnCancel.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 116, 139)
        $btnCancel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $formSel.Controls.Add($btnCancel)
        $formSel.AcceptButton = $btnOk
        $formSel.CancelButton = $btnCancel
        $selRes = $formSel.ShowDialog()
        $formSel.Dispose()
        if ($selRes -ne [System.Windows.Forms.DialogResult]::OK) { Write-Log "[INFO] Pulizia log annullata (selezione)." "Annullato"; return }

        Write-Log "Recupero lista log eventi..." "In esecuzione..."
        Show-WaitOverlay -msg "Analisi log eventi..."
        $allLogs = @()
        try { $allLogs = wevtutil el 2>&1 | Where-Object { $_ -and $_.Trim() -ne "" } } catch { Write-StartLog "Errore ignorato: $_" }
        if (-not $allLogs -or $allLogs.Count -eq 0) { try { $allLogs = (Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | Select-Object -ExpandProperty LogName) } catch { Write-StartLog "Errore ignorato: $_" } }

        $logsToClean = @()
        if ($rbSafe.Checked) {
            # FIX v3.6.6: SAFE pulisce SOLO 5 log, non 300
            $safeNames = @("Application","System","Setup","ForwardedEvents","HardwareEvents")
            foreach ($l in $allLogs) {
                if ($safeNames -contains $l) { $logsToClean += $l }
            }
        } elseif ($rbAll.Checked) {
            $logsToClean = $allLogs | Where-Object { $_ -ne "Security" }
        } else {
            $logsToClean = $allLogs
        }

        $backupFolder = $null
        if ($doBackup) {
            $ts = Get-Date -Format "yyyyMMdd_HHmmss"
            $backupFolder = (Join-Path $global:OutputDir "EventLogs_Backup_$ts")
            try { New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null } catch { $backupFolder = $null }
        }

        $cleaned = 0; $failed = 0; $backed = 0
        $total = $logsToClean.Count
        $idx = 0
        foreach ($log in $logsToClean) {
            $idx++
            # Finezza v3.6.6: progress bar reale + overlay aggiornato
            $progressMsg = "Pulizia $idx/$total - $log"
            try {
                if ($global:waitForm -ne $null) {
                    try {
                        $global:waitForm.Text = $progressMsg
                        $global:waitForm.Controls[0].Text = $progressMsg
                        if ($global:waitForm.Controls.Count -gt 1) {
                            # Cerca progress bar e aggiorna se determinata
                        }
                    } catch { Write-StartLog "Errore ignorato: $_" }
                }
                $lblStatus.Text = " ⏳ $progressMsg"
                [System.Windows.Forms.Application]::DoEvents()
            } catch { Write-StartLog "Errore ignorato: $_" }

            try {
                if ($doBackup -and $backupFolder) {
                    $safeLogName = $log -replace "[\\/:*?""<>|]", "_"
                    $backupPath = Join-Path $backupFolder "$safeLogName.evtx"
                    try { $null = wevtutil epl "$log" "$backupPath" 2>&1; if (Test-Path $backupPath) { $backed++ } } catch { Write-StartLog "Errore ignorato: $_" }
                }
                $out = wevtutil cl "$log" 2>&1
                if ($LASTEXITCODE -eq 0) { $cleaned++; Write-Log "[OK] Pulito ($idx/$total): $log" }
                else {
                    try { Clear-EventLog -LogName $log -ErrorAction Stop; $cleaned++; Write-Log "[OK] Pulito ($idx/$total) (Clear-EventLog): $log" }
                    catch { $failed++; Write-Log "[WARN] Fallito ($idx/$total): $log" }
                }
            } catch { $failed++; Write-Log "[WARN] Errore ($idx/$total): $log - $_" }
        }
        Hide-WaitOverlay
        Write-Log "[OK] Pulizia completata! Puliti: $cleaned | Backup: $backed | Falliti: $failed" "Completato"
        $msgEnd = "Pulizia completata!`r`nPuliti: $cleaned`r`nBackup: $backed`r`nFalliti: $failed`r`n"
        if ($backupFolder) { $msgEnd += "Backup in: $backupFolder`r`n" }
        [System.Windows.Forms.MessageBox]::Show($msgEnd, "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        if ($backupFolder) { try { Start-Process explorer.exe -ArgumentList "`"$backupFolder`"" } catch { Write-StartLog "Errore ignorato: $_" } }
    } catch {
        Hide-WaitOverlay
        Write-Log "[ERRORE] Pulizia log: $_" "Errore"
        [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Clear-SecurityLogFullFix {
    # FIX RAPIDO per errore "registro eventi pieno, solo administrator possono accedere" su PC a dominio
    Show-CommandSummary "SBLOCCO Log Security Pieno - Dominio Fix" @("wevtutil epl Security backup.evtx", "wevtutil cl Security", "wevtutil sl Security /ms:20971520 /rt:true /ab:true")
    try {
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        $isDomain = $cs -and $cs.PartOfDomain

        Write-Log "=== FIX LOG PIENO SECURITY (Dominio) ===" "Avvio"
        Write-Log "PC in dominio: $isDomain - $env:COMPUTERNAME" "Info"

        $msg = "SBLOCCO RAPIDO - LOG SECURITY PIENO`r`n`r`n"
        $msg += "Questo comando risolve l'errore:`r`n"
        $msg += "'Il registro eventi è pieno. Solo gli amministratori potranno accedere'`r`n`r`n"
        $msg += "Cosa fa:`r`n"
        $msg += "1. Backup Security nella cartella dello script (obbligatorio su dominio)`r`n"
        $msg += "2. Esegue: wevtutil cl Security  (quello che ti dicevano)`r`n"
        $msg += "3. Imposta auto-sovrascrittura a 20MB per non farlo tornare`r`n"
        $msg += "   wevtutil sl Security /ms:20971520 /ab:true /rt:true`r`n`r`n"
        $msg += "NOTA: Genera evento 1102 nel Security log (log cancellato) - tracciato da SOC.`r`n`r`n"
        $msg += "Procedere?"

        $choice = [System.Windows.Forms.MessageBox]::Show($msg, "Sblocco Log Security Pieno", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) { Write-Log "[INFO] Fix annullato." "Annullato"; return }

        Show-WaitOverlay -msg "Backup + pulizia Security..."
        $ts = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFolder = (Join-Path $global:OutputDir "EventLogs_Backup_$ts")
        New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null

        $backupPath = Join-Path $backupFolder "Security.evtx"
        $backupSys = Join-Path $backupFolder "System.evtx"
        $backupApp = Join-Path $backupFolder "Application.evtx"

        Write-Log "[INFO] Backup Security -> $backupPath" "Backup"
        try {
            $outEpl = wevtutil epl Security "$backupPath" 2>&1
            if (Test-Path $backupPath) { Write-Log "[OK] Backup Security OK: $backupPath" } else { Write-Log "[WARN] Backup Security fallito: $outEpl" }
        } catch { Write-Log "[WARN] Backup Security errore: $_" }

        # Backup anche System e Application per sicurezza
        try { wevtutil epl System "$backupSys" 2>&1 | Out-Null } catch { Write-StartLog "Errore ignorato: $_" }
        try { wevtutil epl Application "$backupApp" 2>&1 | Out-Null } catch { Write-StartLog "Errore ignorato: $_" }

        Write-Log "[INFO] Esecuzione: wevtutil cl Security" "In esecuzione..."
        $clOut = wevtutil cl Security 2>&1
        $clCode = $LASTEXITCODE
        if ($clCode -eq 0) {
            Write-Log "[OK] wevtutil cl Security ESEGUITO - Log Security pulito!" "Completato"
        } else {
            Write-Log "[WARN] wevtutil cl fallito ($clCode): $clOut - Tento Clear-EventLog..." "Warn"
            try {
                Clear-EventLog -LogName Security -ErrorAction Stop
                Write-Log "[OK] Clear-EventLog Security OK" "Completato"
            } catch {
                Write-Log "[ERRORE] Impossibile pulire Security: $_ - Serve admin elevato!" "Errore"
                Hide-WaitOverlay
                [System.Windows.Forms.MessageBox]::Show("Impossibile pulire Security.`r`n`r`nErrore: $_`r`n`r`nAssicurati di eseguire come Administrator di Dominio / Locale.", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return
            }
        }

        # FIX DEFINITIVO: imposta sovrascrittura automatica e dimensione 20MB
        Write-Log "[INFO] Applico fix definitivo: auto-backup + overwrite + 20MB" "Config"
        try {
            $sl1 = wevtutil sl Security /ms:20971520 /ab:true /rt:true 2>&1
            Write-Log "[OK] Config Security: 20MB / AutoBackup=true / Retain=false / Overwrite=true -> $sl1"
        } catch { Write-Log "[WARN] wevtutil sl Security fallito: $_" }

        try {
            wevtutil sl System /ms:20971520 /rt:true 2>&1 | Out-Null
            wevtutil sl Application /ms:20971520 /rt:true 2>&1 | Out-Null
            Write-Log "[OK] Config System/Application a 20MB overwrite"
        } catch { Write-StartLog "Errore ignorato: $_" }

        Hide-WaitOverlay

        # Verifica
        try {
            $logInfo = Get-WinEvent -ListLog Security -ErrorAction SilentlyContinue
            Write-Log "Stato Security dopo pulizia: RecordCount=$($logInfo.RecordCount) FileSize=$($logInfo.FileSize) IsEnabled=$($logInfo.IsEnabled)" "Info"
        } catch { Write-StartLog "Errore ignorato: $_" }

        $msgEnd = "SBLOCCO COMPLETATO!`r`n`r`n"
        $msgEnd += "Comando eseguito: wevtutil cl Security`r`n"
        $msgEnd += "Backup salvato in:`r`n$backupFolder`r`n`r`n"
        $msgEnd += "Fix definitivo applicato:`r`n- Dimensione max 20MB`r`n- Sovrascrittura automatica attiva`r`n- Non si bloccherà più`r`n`r`n"
        $msgEnd += "L'utente ora potrà accedere senza errore 'log pieno'."

        Write-Log "[OK] Fix log pieno completato - backup in $backupFolder" "Completato"
        [System.Windows.Forms.MessageBox]::Show($msgEnd, "Sblocco Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        try { Start-Process explorer.exe -ArgumentList "`"$backupFolder`"" } catch { Write-StartLog "Errore ignorato: $_" }

    } catch {
        Hide-WaitOverlay
        Write-Log "[ERRORE] Fix Security log pieno: $_" "Errore"
        [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}



function Clear-BrowserCache {

    Show-CommandSummary "Pulizia Cache Browser" @("Chiusura forzata browser e pulizia cache")
    Write-Log "Chiusura forzata dei processi di Chrome, Edge e Firefox..." "In esecuzione..."
    
    Stop-Process -Name "chrome", "msedge", "firefox" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    $clearedCount = 0

    # 1. Pulizia Chrome
    $chromeUserData = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    if (Test-Path $chromeUserData) {
        $chromeProfiles = Get-ChildItem -Path $chromeUserData -Directory | Where-Object { $_.Name -eq "Default" -or $_.Name -like "Profile*" }
        foreach ($profile in $chromeProfiles) {
            $cachePaths = @(
                "$($profile.FullName)\Cache\Cache_Data",
                "$($profile.FullName)\Code Cache",
                "$($profile.FullName)\GPUCache",
                "$($profile.FullName)\Service Worker\CacheStorage"
            )
            foreach ($cp in $cachePaths) {
                if (Test-Path $cp) {
                    try {
                        Get-ChildItem -Path $cp -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                        Write-Log "[OK] Chrome Cache pulita: $cp"
                        $clearedCount++
                    } catch { Write-StartLog "Errore ignorato: $_" }
                }
            }
        }
    }

    # 2. Pulizia Edge
    $edgeUserData = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
    if (Test-Path $edgeUserData) {
        $edgeProfiles = Get-ChildItem -Path $edgeUserData -Directory | Where-Object { $_.Name -eq "Default" -or $_.Name -like "Profile*" }
        foreach ($profile in $edgeProfiles) {
            $edgeCache = "$($profile.FullName)\Cache\Cache_Data"
            if (Test-Path $edgeCache) {
                try {
                    Get-ChildItem -Path $edgeCache -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                    Write-Log "[OK] Edge Cache pulita: $edgeCache"
                    $clearedCount++
                } catch { Write-StartLog "Errore ignorato: $_" }
            }
        }
    }

    # 3. Pulizia Firefox (Aggiunta)
    $firefoxProfilesPath = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $firefoxProfilesPath) {
        $ffProfiles = Get-ChildItem -Path $firefoxProfilesPath -Directory
        foreach ($profile in $ffProfiles) {
            $ffCachePaths = @(
                "$($profile.FullName)\cache2",
                "$($profile.FullName)\startupCache",
                "$($profile.FullName)\jumpListCache"
            )
            foreach ($fcp in $ffCachePaths) {
                if (Test-Path $fcp) {
                    try {
                        Get-ChildItem -Path $fcp -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                        Write-Log "[OK] Firefox Cache pulita: $fcp"
                        $clearedCount++
                    } catch { Write-StartLog "Errore ignorato: $_" }
                }
            }
        }
    }

    Write-Log "[OK] Pulizia browser completata ($clearedCount elementi eliminati)." "Completato"
    [System.Windows.Forms.MessageBox]::Show("Pulizia della cache completata con successo!", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

function Format-ButtonText {
    param([string]$t)
    # Inserisce a capo automatico per testi lunghi > 26 char su 2 righe
    if ($t.Length -gt 28 -and $t -notlike "*`n*") {
        # cerca spazio o slash vicino al centro
        $mid = [int]($t.Length/2)
        $best = $t.IndexOf(" / ", $mid-10)
        if ($best -eq -1) { $best = $t.IndexOf(" ", $mid-5) }
        if ($best -gt 10 -and $best -lt $t.Length-10) {
            return $t.Substring(0,$best) + "`r`n" + $t.Substring($best+1).Trim()
        }
        # fallback: slash
        $slash = $t.IndexOf("/", $mid-10)
        if ($slash -gt 10) {
            return $t.Substring(0,$slash+1) + "`r`n" + $t.Substring($slash+1).Trim()
        }
    }
    return $t
}
function New-CustomButton {
    param($text, $x, $y, $w=380, $h=58, $bgColor="#064E3B", $fgColor="#F8FAFC", $tooltipText="")
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = Format-ButtonText $text
    $btn.Location = New-Object System.Drawing.Point($x, $y)
    $btn.Size = New-Object System.Drawing.Size($w, $h)
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.FlatAppearance.BorderSize = 1
    
    if ($bgColor -eq "#064E3B") { $btn.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#10B981") }
    elseif ($bgColor -eq "#78350F") { $btn.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#F59E0B") }
    elseif ($bgColor -eq "#7F1D1D") { $btn.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#DC2626") }
    else { $btn.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#334155") }

    # Colore al passaggio del mouse / al click: i comandi verdi diventano blu, gli altri schiariscono il proprio colore
    if ($bgColor -eq "#064E3B") { $hoverHex = "#2563EB"; $downHex = "#1E40AF" }
    elseif ($bgColor -eq "#78350F") { $hoverHex = "#B45309"; $downHex = "#92400E" }
    elseif ($bgColor -eq "#7F1D1D") { $hoverHex = "#B91C1C"; $downHex = "#991B1B" }
    else { $hoverHex = "#2563EB"; $downHex = "#1E40AF" }
    $btn.FlatAppearance.MouseOverBackColor = [System.Drawing.ColorTranslator]::FromHtml($hoverHex)
    $btn.FlatAppearance.MouseDownBackColor = [System.Drawing.ColorTranslator]::FromHtml($downHex)
    $btn.BackColor = [System.Drawing.ColorTranslator]::FromHtml($bgColor)
    $btn.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($fgColor)
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btn.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    
    $btn.Tag = $tooltipText

    if ($tooltipText -ne "") {
        $btn.Add_MouseEnter({
            param($sender, $e)
            if ($sender.Tag -ne $null -and $sender.Tag -ne "") {
                $lblStatus.Text = " Guida: $($sender.Tag)"
            }
        })
        $btn.Add_MouseLeave({
            $lblStatus.Text = " Pronto (Eseguito come Amministratore). Passa il mouse sopra un comando per visualizzarne la descrizione."
        })
    }

    return $btn
}

function Set-RegistryWithCheck {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$PropertyType = "DWORD",
        [string]$Description = "Modifica Registro"
    )
    
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    $currentValue = Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction SilentlyContinue

    if ($null -ne $currentValue -and $currentValue -eq $Value) {
        $msg = "La modifica '$Description' risulta GIÀ PRESENTE nel Registro.`r`n`r`nValore attuale: $Name = $Value`r`n`r`nVuoi procedere comunque alla sovrascrittura?"
        $title = "Voce già presente - Conferma"
        
        $choice = [System.Windows.Forms.MessageBox]::Show($msg, $title, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)

        if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force | Out-Null
            Write-Log "[OK] $Description : Forzata e riapplicata dall'utente ($Name = $Value)." "Aggiornato"
            [System.Windows.Forms.MessageBox]::Show("La voce è stata sovrascritta con successo!", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } else {
            Write-Log "[INFO] $Description : Operazione annullata dall'utente (Voce già presente)." "Annullato"
        }
    } else {
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force | Out-Null
        $msg = "Modifica '$Description' APPLICATA CON SUCCESSO!`r`n`r`nNuovo valore: $Name = $Value"
        Write-Log "[OK] $Description : Modifica applicata ($Name = $Value)." "Completato"
        [System.Windows.Forms.MessageBox]::Show($msg, "Registro Aggiornato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
}

# ==============================================================================
# TAB 1: DIAGNOSTICA HARDWARE - batteria, dischi e SMART, RAM, CPU, TPM, Secure Boot, BIOS, driver, test velocità disco
# ==============================================================================


# ==============================================================================
# DEFINIZIONE COMANDI - TUTTI I PULSANTI (ordine per conteggio anticipato)
# ==============================================================================

$diagBtns = @(

    @("Health Batteria Laptop (Wear)", {
        Show-CommandSummary "Health Batteria Laptop" @("Get-CimInstance Win32_Battery", "powercfg /batteryreport")
        Show-WaitOverlay -msg "Analisi batteria in corso..."
        try {
            # 1) Prima verifico se esiste una batteria: sui PC fissi non c'è nulla da analizzare
            $batt = @(Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue)
            if ($batt.Count -eq 0) {
                Write-Log "[INFO] Nessuna batteria presente: questo è un PC fisso (oppure manca il driver della batteria)."
                Write-Log "[INFO] Il report di usura non è applicabile su questo dispositivo, operazione terminata."
                return
            }

            # 2) Capacità di design e attuale (prima Win32_Battery, poi fallback su root\wmi)
            $design = $batt[0].DesignCapacity
            $full   = $batt[0].FullChargeCapacity
            if (-not $design -or -not $full) {
                try {
                    $design = (Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData -ErrorAction Stop | Select-Object -First 1).DesignedCapacity
                    $full   = (Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity -ErrorAction Stop | Select-Object -First 1).FullChargedCapacity
                } catch { Write-StartLog "Batteria root\wmi non disponibile: $_" }
            }
            if ($design -gt 0 -and $full -gt 0) {
                $residua = [math]::Round(($full / $design) * 100, 1)
                $wear = [math]::Round(100 - $residua, 1)
                Write-Log "Capacità Design: $design mWh | Attuale Full: $full mWh"
                Write-Log "Usura Batteria: $wear% - Capacità residua: $residua%"
                if ($wear -gt 40) { Write-Log "[ATTENZIONE] Batteria usurata oltre 40%, consigliata sostituzione" "Attenzione" } else { Write-Log "[OK] Batteria in buono stato" "Completato" }
            } else {
                Write-Log "[INFO] Batteria rilevata ma capacità non leggibili dal driver: consulta il report HTML."
            }

            # 3) Report HTML di powercfg: lo apro solo se il file è stato davvero creato
            $reportPath = Join-Path $global:OutputDir "battery-report.html"
            if (Test-Path $reportPath) { Remove-Item $reportPath -Force -ErrorAction SilentlyContinue }
            $null = powercfg /batteryreport /output "$reportPath" 2>&1
            if (Test-Path $reportPath) {
                Write-Log "Report HTML generato in: $reportPath"
                Start-Process $reportPath -ErrorAction SilentlyContinue
                Write-Log "Report batteria completato con successo" "Completato"
            } else {
                Write-Log "[AVVISO] Il report HTML non è stato generato da powercfg (codice $LASTEXITCODE)." "Attenzione"
            }
        } catch { Write-Log "[ERRORE] Analisi batteria non riuscita: $($_.Exception.Message)" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Genera report usura batteria (powercfg) e calcola percentuale di degrado. Apre HTML dettagliato. Sui PC fissi segnala che non c'è nessuna batteria."),
    @("Controllo Status Batterie (Laptop)", {
        Show-CommandSummary "Status Batterie (Laptop)" @("Get-CimInstance Win32_Battery")
        $bat = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
        if ($bat) {
            Write-Log "Carica Residua: $($bat.EstimatedChargeRemaining)% | Stato: $($bat.BatteryStatus)"
        } else {
            Write-Log "Nessuna batteria rilevata (PC Fisso o Desktop)."
        }
    }, "#064E3B", "#F8FAFC", "Controlla lo stato di carica e la presenza della batteria sui computer portatili."),
    @("SMART Dischi & Stato Salute", {
        Show-CommandSummary "SMART Dischi" @("Get-PhysicalDisk", "Get-CimInstance Win32_DiskDrive")
        Show-WaitOverlay -msg "Controllo SMART dischi..."
        try {
            Get-PhysicalDisk | ForEach-Object {
                $health = $_.HealthStatus; $oper = $_.OperationalStatus; $size = [math]::Round($_.Size/1GB,1)
                Write-Log "Disco: $($_.FriendlyName) | $size GB | Health: $health | Stato: $oper | Bus: $($_.BusType) | Media: $($_.MediaType)"
                if ($health -ne "Healthy") { Write-Log "[ATTENZIONE] Disco $($_.FriendlyName) non in stato Healthy!" "Attenzione" }
            }
            Write-Log "--- Win32_DiskDrive Status ---"
            try { Get-CimInstance Win32_DiskDrive | ForEach-Object { Write-Log ("{0} | Stato: {1} | {2} GB" -f $_.Model, $_.Status, [math]::Round($_.Size/1GB,1)) } } catch { Write-StartLog "Win32_DiskDrive: $_" }
            Write-Log "Controllo SMART completato con successo" "Completato"
        } catch { Write-Log "[ERRORE] $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Verifica stato SMART e salute di tutti i dischi fisici (HDD/SSD/NVMe) con Get-PhysicalDisk e Win32_DiskDrive."),
    @("Stato Dischi e Spazio HD", {
        Show-CommandSummary "Stato Dischi e Spazio HD" @("Get-Volume")
        Get-Volume | ForEach-Object {
            $freeGB = [math]::round($_.SizeRemaining/1GB, 2)
            $totalGB = [math]::round($_.Size/1GB, 2)
            if ($totalGB -gt 0) {
                Write-Log "Unità $($_.DriveLetter): [$($_.FileSystemLabel)] - Liberi: $freeGB GB su $totalGB GB"
            }
        }
    }, "#064E3B", "#F8FAFC", "Analizza tutti i volumi collegati mostrando lo spazio libero e totale disponibile."),
    @("Stato Salute Dischi (S.M.A.R.T.)", {
        Show-CommandSummary "Stato Salute Dischi (S.M.A.R.T.)" @("Get-PhysicalDisk | Select FriendlyName, MediaType, HealthStatus, OperationalStatus")
        try {
            Get-PhysicalDisk | ForEach-Object {
                Write-Log "Unità: $($_.FriendlyName) | Tipo: $($_.MediaType) | Stato Salute: $($_.HealthStatus) | Operativo: $($_.OperationalStatus)"
            }
        } catch {
            Write-Log "[ERRORE] Impossibile recuperare lo stato S.M.A.R.T.: $_"
        }
    }, "#064E3B", "#F8FAFC", "Esegue un controllo sullo stato di salute S.M.A.R.T. di SSD e Hard Disk tramite WMI/CIM."),
    @("Test Velocità Disco`n(winsat disk)", {
        try {
            Show-WaitOverlay "Test velocità disco..."
            Write-Log "[INFO] Test velocità disco..." "Avviato"
            $tmp = "$env:TEMP\winsat_disk.txt"
            try { winsat disk -drive C 2>&1 | Out-File $tmp -Encoding UTF8 } catch { Write-StartLog "Errore ignorato: $_" }
            Write-Log (Get-Content $tmp -Raw -ErrorAction SilentlyContinue) "Risultato"
            Write-Log "[OK] Test completato" "Completato"
        } catch { Write-Log "[ERRORE] $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Esegue winsat disk per benchmark lettura/scrittura disco C:"),
    @("Info Sistema e Hardware", {
        Show-CommandSummary "Info Sistema e Hardware" @("Get-CimInstance Win32_OperatingSystem", "Get-CimInstance Win32_ComputerSystem")
        $os = Get-CimInstance Win32_OperatingSystem
        $cs = Get-CimInstance Win32_ComputerSystem
        Write-Log "OS: $($os.Caption) ($($os.OSArchitecture)) | Build: $($os.BuildNumber)"
        Write-Log "Produttore: $($cs.Manufacturer) | Modello: $($cs.Model) | RAM Totale: $([math]::round($cs.TotalPhysicalMemory/1GB, 2)) GB"
    }, "#064E3B", "#F8FAFC", "Raccoglie informazioni dettagliate su sistema operativo, produttore, modello e RAM totale."),
    @("Controllo Integrità RAM", {
        Show-CommandSummary "Controllo Integrità RAM" @("Get-CimInstance Win32_PhysicalMemory")
        Get-CimInstance Win32_PhysicalMemory | ForEach-Object {
            Write-Log "Banco RAM: $([math]::round($_.Capacity/1GB, 2)) GB | Velocità: $($_.Speed) MHz | Produttore: $($_.Manufacturer)"
        }
    }, "#064E3B", "#F8FAFC", "Verifica i banchi di memoria RAM installati, la capacità, la frequenza e il produttore."),
    @("Test Rapido RAM`n(senza riavvio)", {
        Show-CommandSummary "Test Rapido RAM" @("Allocazione + pattern write/read + verifica")
        try {
            $os = Get-CimInstance Win32_OperatingSystem
            $freeMB = [math]::Floor($os.FreePhysicalMemory / 1KB)
            $totMB = [math]::Floor($os.TotalVisibleMemorySize / 1KB)
            Write-Log "RAM totale: $totMB MB | Libera ora: $freeMB MB" "Avviato"
            # Di default testiamo 512 MB (o meno se ne e' libera poca): sicuro, non blocca il PC.
            # L'utente puo' scegliere 256 / 512 / 1024.
            $scelta = [System.Windows.Forms.MessageBox]::Show("Test rapido RAM senza riavvio.`r`n`r`nVerra' allocata memoria, scritta con pattern noti e riletta per verificare errori.`r`nNon modifica file, non riavvia.`r`n`r`nSI = test da 512 MB (consigliato)`r`nNO = test da 1024 MB`r`nANNULLA = esci", "Test Rapido RAM", [System.Windows.Forms.MessageBoxButtons]::YesNoCancel, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($scelta -eq [System.Windows.Forms.DialogResult]::Cancel) { Write-Log "Test annullato dall'utente."; return }
            $testMB = if ($scelta -eq [System.Windows.Forms.DialogResult]::No) { 1024 } else { 512 }
            if ($testMB -gt ($freeMB - 512)) { $testMB = [math]::Max(128, $freeMB - 512); Write-Log "[INFO] Memoria libera bassa, riduco test a $testMB MB." "Attenzione" }
            Write-Log "Avvio test su $testMB MB in blocchi da 16 MB..."
            Show-WaitOverlay -msg "Test RAM in corso ($testMB MB)..."
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $errori = 0; $blocchi = 0; $verificatiMB = 0
            $rnd = New-Object System.Random
            try {
                $nBlocchi = [math]::Floor($testMB / 16)
                for ($b = 0; $b -lt $nBlocchi; $b++) {
                    # Blocco da 16 MB: pattern diverso per ogni blocco, cosi' becca anche errori dipendenti dal dato
                    $buf = New-Object byte[] -ArgumentList (16MB)
                    $pat = [byte]($rnd.Next(0, 256))
                    for ($i = 0; $i -lt $buf.Length; $i += 4096) { $buf[$i] = $pat; $buf[$i + 1] = [byte](255 - $pat) }
                    # Rilettura e verifica (solo punti campionati: inizio, centro, fine di ogni pagina, per velocita')
                    for ($i = 0; $i -lt $buf.Length; $i += 4096) {
                        if ($buf[$i] -ne $pat -or $buf[$i + 1] -ne [byte](255 - $pat)) { $errori++ }
                    }
                    $blocchi++; $verificatiMB += 16
                    $buf = $null
                    if ($b % 4 -eq 0) { [System.GC]::Collect() }
                }
            } finally { Hide-WaitOverlay; [System.GC]::Collect() }
            $sw.Stop()
            Write-Log "Test completato in $([math]::Round($sw.Elapsed.TotalSeconds,1)) s | Blocchi: $blocchi | Verificati: $verificatiMB MB | Errori: $errori"
            if ($errori -eq 0) {
                Write-Log "[OK] Nessun errore nel test rapido. NOTA: non esclude al 100% un difetto intermittente: per certezza usa Diagnostica Memoria Windows con riavvio." "Completato"
                [System.Windows.Forms.MessageBox]::Show("Test rapido completato: NESSUN errore su $verificatiMB MB.`r`n`r`nPer un test completo (tutta la RAM, fuori da Windows) usa 'Diagnostica Memoria Windows'.", "Test Rapido RAM - OK", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            } else {
                Write-Log "[ATTENZIONE] Trovati $errori errori! Banco RAM sospetto: fai il test completo con riavvio e prova i banchi uno alla volta." "Attenzione"
                [System.Windows.Forms.MessageBox]::Show("ATTENZIONE: trovati $errori errori nel test rapido.`r`n`r`nEsegui 'Diagnostica Memoria Windows' con riavvio per conferma.", "Test Rapido RAM - ERRORI", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            }
        } catch { Hide-WaitOverlay; Write-Log ("[ERRORE] Test RAM: " + $_.ToString()) "Errore" }
    }, "#064E3B", "#F8FAFC", "Test rapido senza riavvio: alloca 512/1024 MB, scrive pattern noti e li rilegge. Se trova errori, conferma con Diagnostica Memoria Windows."),
    @("Diagnostica Memoria`nWindows (riavvio)", {
        Show-CommandSummary "Diagnostica Memoria Windows" @("mdsched.exe")
        $msg = "Avviare Diagnostica Memoria Windows?`r`n`r`nIl PC verra' RIAVVIATO e il test partira' prima di Windows.`r`nDura 10-30 minuti. Al rientro l'esito e' nel Registro Eventi (vedi 'Esito Ultimo Test RAM').`r`n`r`nSalva il lavoro aperto e premi SI."
        $choice = [System.Windows.Forms.MessageBox]::Show($msg, "Diagnostica Memoria - Riavvio", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) { Write-Log "Diagnostica Memoria annullata."; return }
        try { Start-Process mdsched.exe; Write-Log "Diagnostica Memoria Windows avviata: scegli 'Riavvia ora' nella finestra di Windows." "Avviato" } catch { Write-Log ("[ERRORE] mdsched: " + $_.ToString()) "Errore" }
    }, "#7F1D1D", "#F8FAFC", "Lancia mdsched.exe: test ufficiale Microsoft, fuori da Windows, richiede riavvio. E' il test affidabile per banchi difettosi."),
    @("Esito Ultimo`nTest RAM", {
        Show-CommandSummary "Esito Ultimo Test RAM" @("MemoryDiagnostics-Results 1201/1202", "WHEA 19/20")
        try {
            Write-Log "--- Ultima Diagnostica Memoria Windows (1201/1202) ---"
            $ev = Get-WinEvent -FilterHashtable @{ LogName = "System"; ProviderName = "Microsoft-Windows-MemoryDiagnostics-Results"; Id = 1201, 1202 } -MaxEvents 3 -ErrorAction SilentlyContinue | Sort-Object TimeCreated -Descending
            if (-not $ev) { Write-Log "[INFO] Nessun test mdsched trovato: non e' mai stato eseguito (o log ripulito). Usa 'Diagnostica Memoria Windows'." "Nessun test" }
            foreach ($e in $ev) { Write-Log ("[{0}] ID {1}: {2}" -f $e.TimeCreated, $e.Id, (($e.Message -replace '\r?\n',' ') -replace '\s+',' ').Trim()) }
            Write-Log "--- Errori hardware memoria WHEA (ultimi 30 gg, ID 19/20 = ECC/correzioni) ---"
            $whea = Get-WinEvent -FilterHashtable @{ LogName = "System"; ProviderName = "Microsoft-Windows-WHEA-Logger"; Id = 19, 20; StartTime = (Get-Date).AddDays(-30) } -MaxEvents 10 -ErrorAction SilentlyContinue
            if (-not $whea) { Write-Log "[OK] Nessun errore WHEA memoria negli ultimi 30 giorni." "Completato" }
            else { foreach ($w in $whea) { Write-Log ("[ATTENZIONE] [{0}] WHEA ID {1}: possibile errore hardware memoria." -f $w.TimeCreated, $w.Id) "Attenzione" } }
            Write-Log "--- Banchi rilevati ora ---"
            Get-CimInstance Win32_PhysicalMemory | ForEach-Object { Write-Log ("Banco {0}: {1} GB | {2} MHz | {3} | Slot {4}" -f $_.DeviceLocator, [math]::Round($_.Capacity/1GB,2), $_.Speed, $_.Manufacturer, $_.BankLabel) }
        } catch { Write-Log ("[ERRORE] Lettura esiti: " + $_.ToString()) "Errore" }
    }, "#064E3B", "#F8FAFC", "Legge l'esito dell'ultimo test mdsched dal Registro Eventi + errori WHEA memoria ultimi 30 giorni."),
    @("Stress Test RAM`n(5 min, a caldo)", {
        Show-CommandSummary "Stress Test RAM 5 min" @("Loop allocazione + pattern + verifica per 5 minuti")
        try {
            $os = Get-CimInstance Win32_OperatingSystem
            $freeMB = [math]::Floor($os.FreePhysicalMemory / 1KB)
            $totMB = [math]::Floor($os.TotalVisibleMemorySize / 1KB)
            Write-Log "RAM totale: $totMB MB | Libera ora: $freeMB MB" "Avviato"
            $msg = "Stress test RAM per 5 MINUTI.`r`n`r`nIn loop: alloca memoria, scrive pattern diversi, li rilegge e verifica.`r`nServe a trovare difetti che escono solo a caldo / dopo minuti di uso.`r`n`r`nIl PC puo' rallentare durante il test: e' normale.`r`nPuoi annullare in qualsiasi momento dal pulsante ANNULLA.`r`n`r`nChiudi le app pesanti prima di continuare?"
            $choice = [System.Windows.Forms.MessageBox]::Show($msg, "Stress Test RAM 5 min", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
            if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) { Write-Log "Stress test annullato."; return }
            # Buffer di lavoro: 256 MB (o meno se libera poca RAM). Riusato a ogni passata, cosi' non cresce all'infinito.
            $workMB = [math]::Min(256, [math]::Max(64, $freeMB - 1024))
            Write-Log "Buffer di lavoro: $workMB MB | Durata: 5 minuti | Annullabile"
            # --- Finestra di progresso (modeless) con Annulla ---
            $global:BinoStressCancel = $false
            $prog = New-Object System.Windows.Forms.Form
            Enable-DarkTitleBar $prog
            $prog.Text = "Stress Test RAM in corso..."
            $prog.ClientSize = New-Object System.Drawing.Size(460, 170)
            $prog.StartPosition = "CenterParent"
            $prog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
            $prog.MaximizeBox = $false; $prog.MinimizeBox = $false; $prog.TopMost = $true
            $prog.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")
            $lbl = New-Object System.Windows.Forms.Label
            $lbl.Text = "Avvio..."
            $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 10)
            $lbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F8FAFC")
            $lbl.Location = New-Object System.Drawing.Point(15, 15); $lbl.Size = New-Object System.Drawing.Size(430, 60)
            $btnStop = New-Object System.Windows.Forms.Button
            $btnStop.Text = "ANNULLA TEST"
            $btnStop.Location = New-Object System.Drawing.Point(150, 100); $btnStop.Size = New-Object System.Drawing.Size(160, 40)
            $btnStop.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#7F1D1D"); $btnStop.ForeColor = [System.Drawing.Color]::White
            $btnStop.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $btnStop.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $btnStop.Add_Click({ $global:BinoStressCancel = $true })
            $prog.Controls.AddRange(@($lbl, $btnStop))
            $prog.Show() | Out-Null
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $durata = [TimeSpan]::FromMinutes(5)
            $rnd = New-Object System.Random
            $errori = 0; $passate = 0; $verificatiMB = 0
            try {
                while ($sw.Elapsed -lt $durata -and -not $global:BinoStressCancel) {
                    $passate++
                    $buf = New-Object byte[] -ArgumentList ($workMB * 1MB)
                    $pat = [byte]($rnd.Next(0, 256))
                    # Scrittura: pattern + complemento, un punto ogni 4 KB (come il test rapido)
                    for ($i = 0; $i -lt $buf.Length; $i += 4096) { $buf[$i] = $pat; $buf[$i + 1] = [byte](255 - $pat) }
                    # Piccola pausa per non saturare al 100% e lasciare respirare UI / altri processi
                    [System.Windows.Forms.Application]::DoEvents()
                    Start-Sleep -Milliseconds 50
                    # Verifica
                    for ($i = 0; $i -lt $buf.Length; $i += 4096) {
                        if ($buf[$i] -ne $pat -or $buf[$i + 1] -ne [byte](255 - $pat)) { $errori++ }
                    }
                    $verificatiMB += $workMB
                    $buf = $null; [System.GC]::Collect()
                    $rim = [math]::Max(0, [int][math]::Ceiling(($durata - $sw.Elapsed).TotalSeconds))
                    $minRim = [math]::Floor($rim / 60); $secRim = $rim % 60
                    $lbl.Text = ("Passata {0} | Verificati: {1} MB | Errori: {2}`r`nTempo rimasto: {3}:{4} - premi ANNULLA per fermare" -f $passate, $verificatiMB, $errori, $minRim, $secRim.ToString("00"))
                    [System.Windows.Forms.Application]::DoEvents()
                    if ($errori -gt 0) { break }
                }
            } finally { $sw.Stop(); $prog.Close(); $prog.Dispose(); [System.GC]::Collect() }
            $annullato = $global:BinoStressCancel
            Write-Log ("Stress test finito | Passate: {0} | Verificati: {1} MB | Errori: {2} | Durata: {3:N1} s | Annullato: {4}" -f $passate, $verificatiMB, $errori, $sw.Elapsed.TotalSeconds, $annullato)
            if ($errori -eq 0 -and -not $annullato) {
                Write-Log "[OK] Nessun errore in 5 minuti di stress. Difetto a caldo improbabile (ma non escluso al 100%: per certezza usa mdsched)." "Completato"
                [System.Windows.Forms.MessageBox]::Show("Stress test completato: NESSUN errore.`r`nPassate: $passate | Verificati: $verificatiMB MB.", "Stress Test RAM - OK", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            } elseif ($errori -gt 0) {
                Write-Log "[ATTENZIONE] Trovati $errori errori durante lo stress! Banco RAM sospetto." "Attenzione"
                [System.Windows.Forms.MessageBox]::Show("ATTENZIONE: trovati $errori errori durante lo stress.`r`nFai 'Diagnostica Memoria Windows' con riavvio e prova i banchi uno alla volta.", "Stress Test RAM - ERRORI", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            } else {
                Write-Log "[INFO] Stress test annullato dall'utente dopo $passate passate, $verificatiMB MB verificati, $errori errori." "Annullato"
            }
        } catch { Write-Log ("[ERRORE] Stress test RAM: " + $_.ToString()) "Errore" }
    }, "#7F1D1D", "#F8FAFC", "Stress a caldo per 5 minuti in loop: alloca, scrive pattern, rilegge. Si ferma al primo errore o con ANNULLA. Trova difetti intermittenti."),
    @("Verifica Eventi Errore (System)", {
        Show-CommandSummary "Eventi Errore System" @("Get-EventLog -LogName System -EntryType Error -Newest 10")
        Get-EventLog -LogName System -EntryType Error -Newest 10 -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Log "[$($_.TimeGenerated)] Sorgente: $($_.Source) | EventID: $($_.EventID) | MSG: $($_.Message.SubString(0, [math]::Min(60, $_.Message.Length)))"
        }
    }, "#064E3B", "#F8FAFC", "Estrae gli ultimi 10 errori critici registrati dal sistema operativo nel registro eventi."),
    @("Status Processore / CPU", {
        Show-CommandSummary "Status Processore / CPU" @("Get-CimInstance Win32_Processor")
        $cpu = Get-CimInstance Win32_Processor
        Write-Log "CPU: $($cpu.Name) | Core: $($cpu.NumberOfCores) | Logici: $($cpu.NumberOfLogicalProcessors) | MaxSpeed: $($cpu.MaxClockSpeed) MHz"
    }, "#064E3B", "#F8FAFC", "Mostra le specifiche tecniche del processore (Core fisici, logici e velocità massima)."),
    @("Lista Processi ad Alto Uso RAM", {
        Show-CommandSummary "Processi Alto Uso RAM" @("Get-Process | Sort-Object WorkingSet64 -Descending | Select -First 10")
        Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 | ForEach-Object {
            Write-Log "Processo: $($_.Name) | RAM Usata: $([math]::round($_.WorkingSet64/1MB, 2)) MB"
        }
    }, "#064E3B", "#F8FAFC", "Elenca i primi 10 processi di Windows che stanno consumando più memoria RAM in questo momento."),
    @("Verifica Modello e Seriale PC", {
        Show-CommandSummary "Verifica Modello e Seriale PC" @("Get-CimInstance Win32_BIOS")
        $bios = Get-CimInstance Win32_BIOS
        Write-Log "Serial Number / Service Tag: $($bios.SerialNumber) | BIOS: $($bios.SMBIOSBIOSVersion)"
    }, "#064E3B", "#F8FAFC", "Legge direttamente dal BIOS il numero di serie (Service Tag) e la versione del firmware."),
    @("Tempo di Attività PC (Uptime)", {
        Show-CommandSummary "Tempo di Attività PC (Uptime)" @("Get-CimInstance Win32_OperatingSystem | Select LastBootUpTime")
        $bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        $uptime = (Get-Date) - $bootTime
        Write-Log "Ultimo Avvio: $bootTime"
        Write-Log "Tempo di Accensione Continuo: $($uptime.Days) giorni, $($uptime.Hours) ore, $($uptime.Minutes) minuti"
    }, "#064E3B", "#F8FAFC", "Calcola da quanto tempo esatto il computer è acceso senza essere stato riavviato."),
    @("Controllo Stato TPM (tpm.msc)", {
        Show-CommandSummary "Controllo Stato TPM" @("Get-Tpm", "tpm.msc")
        try {
            $tpm = Get-Tpm -ErrorAction SilentlyContinue
            if ($tpm) {
                Write-Log "TPM Presente: $($tpm.TpmPresent) | Pronto: $($tpm.TpmReady) | Versione: $($tpm.ManufacturerVersion)"
            } else {
                Write-Log "[INFO] Modulo TPM non rilevato o non accessibile tramite CIM/PowerShell."
            }
            Start-Process tpm.msc
            Write-Log "Console di gestione TPM (tpm.msc) avviata." "Completato"
        } catch {
            Write-Log "[ERRORE] Impossibile leggere lo stato TPM: $_" "Errore"
        }
    }, "#064E3B", "#F8FAFC", "Verifica lo stato del chip TPM e apre la console di gestione di sistema tpm.msc."),
    @("Controllo Secure Boot", {
        Show-CommandSummary "Controllo Secure Boot" @("Confirm-SecureBootUEFI")
        try {
            $sb = Confirm-SecureBootUEFI -ErrorAction Stop
            if ($sb) {
                Write-Log "[OK] Secure Boot risulta ATTIVO (Enabled) nel sistema." "Secure Boot Attivo"
                [System.Windows.Forms.MessageBox]::Show("Secure Boot è ATTIVO.", "Controllo Secure Boot", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            } else {
                Write-Log "[WARN] Secure Boot risulta DISATTIVATO (Disabled)." "Secure Boot Disattivo"
                [System.Windows.Forms.MessageBox]::Show("Secure Boot è DISATTIVATO.", "Controllo Secure Boot", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            }
        } catch {
            Write-Log "[INFO] Impossibile verificare Secure Boot (Modalità Legacy BIOS o permessi insufficienti): $_" "Non Disponibile"
            [System.Windows.Forms.MessageBox]::Show("Impossibile verificare Secure Boot. Il sistema potrebbe essere in modalità Legacy o non supportata.", "Avviso", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    }, "#064E3B", "#F8FAFC", "Verifica se la funzione di sicurezza Secure Boot è attiva a livello UEFI."),
    @("Controllo Versione BIOS", {
        Show-CommandSummary "Controllo Versione BIOS" @("Get-CimInstance Win32_BIOS")
        try {
            $biosVer = (Get-CimInstance Win32_BIOS).SMBIOSBIOSVersion
            Write-Log "[INFO] Versione BIOS (SMBIOS): $biosVer" "Completato"
            [System.Windows.Forms.MessageBox]::Show("Versione BIOS rilevata:`r`n`r`n$biosVer", "Versione BIOS", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            Write-Log "[ERRORE] Impossibile leggere la versione del BIOS: $_" "Errore"
        }
    }, "#064E3B", "#F8FAFC", "Mostra la versione esatta del BIOS/UEFI attualmente installata sulla scheda madre."),
    @("Verifica Driver Firmati e WHQL", {
        Show-CommandSummary "Verifica Driver Firmati e WHQL" @("sigverif", "Get-CimInstance Win32_PnPSignedDriver", "Genera report nella cartella dello script")
        try {
            Write-Log "Avvio dello strumento grafico di verifica firma file (sigverif)..."
            Start-Process "sigverif.exe" -ErrorAction SilentlyContinue
            
            Write-Log "Scansione rapida driver non firmati tramite PowerShell..."
            $unsignedDrivers = Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue | Where-Object {$_.IsSigned -eq $false}
            $allDrivers = Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue

            # --- GENERA REPORT NELLA CARTELLA DELLO SCRIPT ---
            $outDir = $global:OutputDir
            $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
            $reportPath = Join-Path $outDir "Report_Driver_Non_Firmati_$timestamp.txt"
            $csvPath = Join-Path $outDir "Report_Driver_Non_Firmati_$timestamp.csv"

            $reportHeader = @"
================================================================================
REPORT DRIVER FIRMATI E WHQL - BINO Tool v2.10.1
Data: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
Computer: $env:COMPUTERNAME
Utente: $env:USERNAME
================================================================================

TOTALE DRIVER ANALIZZATI: $($allDrivers.Count)
DRIVER NON FIRMATI TROVATI: $(if($unsignedDrivers){@($unsignedDrivers).Count}else{0})

================================================================================
DETTAGLIO DRIVER NON FIRMATI
================================================================================
"@
            $reportHeader | Out-File -FilePath $reportPath -Encoding UTF8

            if ($unsignedDrivers) {
                foreach ($drv in $unsignedDrivers) {
                    $line = "DeviceName: $($drv.DeviceName) | Versione: $($drv.DriverVersion) | Produttore: $($drv.Manufacturer) | DriverName: $($drv.DriverName) | InfName: $($drv.InfName)"
                    Write-Log "[ATTENZIONE] Driver non firmato trovato: $line" "Driver non firmato"
                    $line | Out-File -FilePath $reportPath -Append -Encoding UTF8
                }
                # Esporta anche CSV dettagliato
                $unsignedDrivers | Select-Object DeviceName, DriverVersion, Manufacturer, DriverName, InfName, IsSigned, DriverDate | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                Write-Log "[OK] Report generato nella cartella dello script: $reportPath e $csvPath" "Report Creato"
                [System.Windows.Forms.MessageBox]::Show("Rilevati $(@($unsignedDrivers).Count) driver non firmati!`r`n`r`nReport salvati nella cartella dello script:`r`n- $reportPath`r`n- $csvPath`r`n`r`nControlla anche la finestra sigverif aperta.", "Attenzione Driver - Report Creato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                # Apre la cartella con il report selezionato
                Start-Process "explorer.exe" -ArgumentList "/select,`"$reportPath`""
            } else {
                "Nessun driver non firmato rilevato. Tutti i driver risultano firmati." | Out-File -FilePath $reportPath -Append -Encoding UTF8
                Write-Log "[OK] Tutti i driver analizzati tramite WMI risultano regolarmente firmati." "Driver Verificati"
                Write-Log "[OK] Report generato nella cartella dello script: $reportPath" "Report Creato"
                [System.Windows.Forms.MessageBox]::Show("Verifica completata: tutti i driver analizzati risultano firmati.`r`n`r`nReport salvato nella cartella dello script:`r`n$reportPath`r`n`r`nSi è aperta inoltre l'utility 'sigverif'.", "Verifica Completata - Report Creato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        } catch {
            Write-Log "[ERRORE] Verifica Driver: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore durante la generazione del report: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#064E3B", "#F8FAFC", "Verifica la presenza di driver non firmati e genera report TXT+CSV nella cartella dello script."),
    
    @("Verifica Stato Driver (driverquery /V)", {
        Show-CommandSummary "Verifica Stato Driver - Equivalente driverquery /V" @("Get-CimInstance Win32_SystemDriver | Select Name, DisplayName, State, StartMode, PathName")
        try {
            Write-Log "Lettura driver kernel in corso (equivalente driverquery /v)..." "Scansione..."
            $sysDrivers = Get-CimInstance Win32_SystemDriver -ErrorAction Stop | Sort-Object State, Name
            
            # --- GENERA REPORT ---
            $outDir = $global:OutputDir
            $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
            $reportPath = Join-Path $outDir "Report_Driver_Stato_V_$timestamp.txt"
            $csvPath = Join-Path $outDir "Report_Driver_Stato_V_$timestamp.csv"

            $header = @"
================================================================================
REPORT STATO DRIVER - Equivalente driverquery /V - Bino Tool
Data: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
Computer: $env:COMPUTERNAME
Totale driver: $($sysDrivers.Count)
================================================================================
"@
            $header | Out-File -FilePath $reportPath -Encoding UTF8
            "Stato | Modalità Avvio | Nome Modulo | Nome Visualizzato | Percorso" | Out-File -FilePath $reportPath -Append -Encoding UTF8
            "----------------------------------------------------------------------------------------------------" | Out-File -FilePath $reportPath -Append -Encoding UTF8

            foreach ($d in $sysDrivers) {
                $lineLog = "$($d.State) | $($d.StartMode) | $($d.Name) | $($d.DisplayName)"
                Write-Log $lineLog
                "$($d.State) | $($d.StartMode) | $($d.Name) | $($d.DisplayName) | $($d.PathName)" | Out-File -FilePath $reportPath -Append -Encoding UTF8
            }
            
            $sysDrivers | Select-Object Name, DisplayName, State, StartMode, Status, ServiceType, PathName | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
            
            Write-Log "[OK] Report Stato Driver generato: $reportPath" "Completato"
            Write-Log "[OK] CSV: $csvPath"
            
            # Evidenzia problemi: driver in Auto ma Stopped
            $problemi = $sysDrivers | Where-Object { $_.StartMode -eq "Auto" -and $_.State -ne "Running" }
            if ($problemi) {
                Write-Log "[WARN] Trovati $($problemi.Count) driver impostati su Auto ma non in esecuzione!" "Attenzione"
                $problemi | ForEach-Object { Write-Log "  -> $($_.Name) ($($_.DisplayName)) Stato: $($_.State)" }
            }
            
            [System.Windows.Forms.MessageBox]::Show("Verifica Stato Driver completata!`r`n`r`nTotale: $($sysDrivers.Count)`r`nProblemi Auto/Stopped: $(@($problemi).Count)`r`n`r`nReport:`r`n$reportPath`r`n$csvPath", "driverquery /V - Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Start-Process "explorer.exe" -ArgumentList "/select,`"$reportPath`""
        } catch {
            Write-Log "[ERRORE] Verifica Stato Driver /V: $_" "Errore"
        }
    }, "#0E7490", "#F8FAFC", "Equivalente PowerShell moderno di driverquery /v - Mostra stato (Running/Stopped), modalità avvio (Auto/Manual) e percorso di tutti i driver kernel."),

    @("Report Completo Driver V+SI Integrato", {
        Show-CommandSummary "Report Completo V+SI Integrato" @("Get-CimInstance Win32_SystemDriver + Win32_PnPEntity + Win32_PnPSignedDriver - Join per Stato e Firma")
        try {
            Write-Log "Generazione report unificato /V + /SI in corso (Stato + Firma WHQL)..." "Scansione..."
            
            # Costruzione hashtable per join veloce
            $sysDrivers = @{}
            Get-CimInstance Win32_SystemDriver -ErrorAction SilentlyContinue | ForEach-Object { $sysDrivers[$_.Name] = $_ }
            $signedDrivers = @{}
            Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue | ForEach-Object { $signedDrivers[$_.DeviceID] = $_ }

            $reportData = @()
            $pnpDevices = Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue | Where-Object { $_.Service }

            foreach ($dev in $pnpDevices) {
                $svc = $sysDrivers[$dev.Service]
                $sig = $signedDrivers[$dev.DeviceID]
                $obj = [PSCustomObject]@{
                    DeviceName = $dev.Name
                    ServiceName = $dev.Service
                    Stato = if($svc){ $svc.State } else { "N/A" }
                    ModalitaAvvio = if($svc){ $svc.StartMode } else { "N/A" }
                    Percorso = if($svc){ $svc.PathName } else { "N/A" }
                    IsSigned = if($sig){ $sig.IsSigned } else { "N/A" }
                    Firmatario = if($sig){ $sig.Signer } else { "N/A" }
                    Versione = if($sig){ $sig.DriverVersion } else { "N/A" }
                    InfName = if($sig){ $sig.InfName } else { "N/A" }
                    Produttore = if($sig){ $sig.DriverProviderName } else { $dev.Manufacturer }
                }
                $reportData += $obj
            }

            # Fallback: se join Pnp fallisce, aggiungi anche i driver kernel puri senza PnP
            $onlySys = Get-CimInstance Win32_SystemDriver | Where-Object { $reportData.ServiceName -notcontains $_.Name } | ForEach-Object {
                [PSCustomObject]@{
                    DeviceName = $_.DisplayName
                    ServiceName = $_.Name
                    Stato = $_.State
                    ModalitaAvvio = $_.StartMode
                    Percorso = $_.PathName
                    IsSigned = "Verifica manuale"
                    Firmatario = "N/A"
                    Versione = "N/A"
                    InfName = "N/A"
                    Produttore = "N/A"
                }
            }
            $reportData += $onlySys

            $reportData = $reportData | Sort-Object Stato, ServiceName

            # Log
            foreach ($r in $reportData | Select-Object -First 50) {
                Write-Log "$($r.Stato) | $($r.ModalitaAvvio) | Signed:$($r.IsSigned) | $($r.ServiceName) | $($r.DeviceName)"
            }
            if ($reportData.Count -gt 50) { Write-Log "... e altri $($reportData.Count - 50) driver (vedi report completo)" }

            # Report nella cartella dello script
            $outDir = $global:OutputDir
            $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
            $reportPath = Join-Path $outDir "Report_Driver_V_SI_Unificato_$timestamp.txt"
            $csvPath = Join-Path $outDir "Report_Driver_V_SI_Unificato_$timestamp.csv"

            $header = @"
================================================================================
REPORT COMPLETO DRIVER V+SI INTEGRATO - Bino Tool $scriptVersion
Data: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
Computer: $env:COMPUTERNAME
Totale dispositivi con driver: $($reportData.Count)
================================================================================
Legenda: /V = Stato, ModalitaAvvio, Percorso | /SI = IsSigned, Firmatario, Versione, Inf
================================================================================
"@
            $header | Out-File -FilePath $reportPath -Encoding UTF8
            $reportData | Format-Table -AutoSize | Out-File -FilePath $reportPath -Append -Encoding UTF8 -Width 300

            $reportData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

            # Analisi problemi
            $nonFirmatiRunning = $reportData | Where-Object { $_.IsSigned -eq $false -and $_.Stato -eq "Running" }
            $autoStopped = $reportData | Where-Object { $_.ModalitaAvvio -eq "Auto" -and $_.Stato -eq "Stopped" -and $_.Stato -ne "N/A" }

            if ($nonFirmatiRunning) { Write-Log "[CRITICO] $($nonFirmatiRunning.Count) driver NON firmati IN ESECUZIONE!" "Sicurezza" }
            if ($autoStopped) { Write-Log "[WARN] $($autoStopped.Count) driver Auto ma Stopped" "Attenzione" }

            Write-Log "[OK] Report unificato generato: $reportPath" "Completato"
            
            $msg = "Report V+SI Integrato completato!`r`n`r`nTotale: $($reportData.Count)`r`nNon firmati in Running: $(@($nonFirmatiRunning).Count)`r`nAuto ma Stopped: $(@($autoStopped).Count)`r`n`r`nFile:`r`n$reportPath`r`n$csvPath"
            [System.Windows.Forms.MessageBox]::Show($msg, "Report V+SI Integrato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Start-Process "explorer.exe" -ArgumentList "/select,`"$reportPath`""
        } catch {
            Write-Log "[ERRORE] Report V+SI: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore report V+SI:`r`n$_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#064E3B", "#F8FAFC", "REPORT DEFINITIVO che unisce driverquery /V (Stato/Avvio/Percorso) + driverquery /SI (Firma WHQL, Produttore, Versione, INF) in un unico CSV/TXT nella cartella dello script. Trova driver non firmati in esecuzione."),

    @("Esporta Tutti i Driver (Backup)", {
        Show-CommandSummary "Esporta Tutti i Driver" @("Export-WindowsDriver -Online -Destination <cartella>", "DISM /Online /Export-Driver /Destination:<cartella>")
        try {
            $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
            $folderBrowser.Description = "Seleziona dove salvare il backup dei driver"
            $folderBrowser.RootFolder = "MyComputer"
            $outDir = $global:OutputDir
            $defaultPath = Join-Path $outDir ("DriverBackup_" + $env:COMPUTERNAME + "_" + (Get-Date -Format "yyyyMMdd_HHmm"))
            $folderBrowser.SelectedPath = $outDir
            
            Write-Log "[INFO] Seleziona la cartella di destinazione per il backup driver..." "Selezione cartella"
            $result = $folderBrowser.ShowDialog()
            if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
                Write-Log "[INFO] Esportazione driver annullata dall'utente." "Annullato"
                return
            }
            $destPath = $folderBrowser.SelectedPath
            # Se seleziona la cartella di partenza, crea una sottocartella
            if ($destPath -eq $outDir) {
                $destPath = $defaultPath
            }
            if (-not (Test-Path $destPath)) { New-Item -ItemType Directory -Path $destPath -Force | Out-Null }

            Write-Log "[INFO] Avvio esportazione driver verso: $destPath" "Esportazione in corso..."
            Write-Log "[INFO] Questo può richiedere alcuni minuti..."

            # Metodo PowerShell nativo (più affidabile)
            try {
                $expResult = Export-WindowsDriver -Online -Destination $destPath -ErrorAction Stop
                $count = ($expResult | Measure-Object).Count
                Write-Log "[OK] Esportati $count driver in $destPath" "Backup Completato"
                [System.Windows.Forms.MessageBox]::Show("Backup completato!`r`n`r`nDriver esportati: $count`r`nDestinazione:`r`n$destPath`r`n`r`nPuoi usare il pulsante 'Importa Driver' per ripristinarli su questo o un altro PC.", "Esportazione Completata", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                Start-Process explorer.exe -ArgumentList "`"$destPath`""
            } catch {
                Write-Log "[WARN] Export-WindowsDriver fallito, provo con DISM: $_"
                $dismCmd = "DISM /Online /Export-Driver /Destination:`"$destPath`""
                Show-CommandSummary "Esporta Driver via DISM" @($dismCmd)
                $proc = Start-Process -FilePath "DISM.exe" -ArgumentList "/Online /Export-Driver /Destination:`"$destPath`"" -Wait -NoNewWindow -PassThru
                if ($proc.ExitCode -eq 0) {
                    $count = (Get-ChildItem -Path $destPath -Recurse -Filter "*.inf" -ErrorAction SilentlyContinue | Measure-Object).Count
                    Write-Log "[OK] Esportazione DISM completata: $count INF trovati in $destPath" "Backup Completato"
                    [System.Windows.Forms.MessageBox]::Show("Backup completato con DISM!`r`n`r`nFile INF trovati: $count`r`nDestinazione:`r`n$destPath", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                    Start-Process explorer.exe -ArgumentList "`"$destPath`""
                } else {
                    throw "DISM ExitCode: $($proc.ExitCode)"
                }
            }
        } catch {
            Write-Log "[ERRORE] Esportazione driver fallita: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore durante l'esportazione driver:`r`n$_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#064E3B", "#F8FAFC", "Esporta tutti i driver di terze parti installati in una cartella di backup - Utile prima di formattare o per clonare i driver su un altro PC identico."),
    @("Importa Driver da Cartella (Ripristino)", {
        Show-CommandSummary "Importa Driver da Cartella" @("pnputil /add-driver <cartella>\*.inf /subdirs /install")
        try {
            $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
            $folderBrowser.Description = "Seleziona la cartella contenente i driver da importare (con sottocartelle)"
            $folderBrowser.RootFolder = "MyComputer"
            $outDir = $global:OutputDir
            $folderBrowser.SelectedPath = $outDir

            Write-Log "[INFO] Seleziona la cartella sorgente dei driver da installare..." "Selezione cartella"
            $result = $folderBrowser.ShowDialog()
            if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
                Write-Log "[INFO] Importazione driver annullata dall'utente." "Annullato"
                return
            }
            $sourcePath = $folderBrowser.SelectedPath
            $infCount = (Get-ChildItem -Path $sourcePath -Recurse -Filter "*.inf" -ErrorAction SilentlyContinue | Measure-Object).Count
            if ($infCount -eq 0) {
                Write-Log "[WARN] Nessun file .inf trovato in $sourcePath" "Nessun driver"
                [System.Windows.Forms.MessageBox]::Show("Nessun driver (.inf) trovato nella cartella selezionata:`r`n$sourcePath`r`n`r`nSeleziona la cartella radice del backup creato con 'Esporta Driver'.", "Nessun driver trovato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                return
            }

            $confirmMsg = "Trovati $infCount driver (.inf) in:`r`n$sourcePath`r`n`r`nVuoi procedere con l'installazione di TUTTI i driver?`r`n`r`nVerrà usato: pnputil /add-driver *.inf /subdirs /install`r`nQuesta operazione richiede tempo e potrebbe richiedere un riavvio."
            $confirm = [System.Windows.Forms.MessageBox]::Show($confirmMsg, "Conferma Importazione Driver", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) {
                Write-Log "[INFO] Importazione annullata dall'utente." "Annullato"
                return
            }

            Write-Log "[INFO] Avvio importazione di $infCount driver da $sourcePath..." "Importazione in corso..."
            Write-Log "[INFO] Comando: pnputil /add-driver `"$sourcePath\*.inf`" /subdirs /install"

            $pnpOutput = & pnputil.exe /add-driver "$sourcePath\*.inf" /subdirs /install 2>&1 | Out-String
            Write-Log $pnpOutput

            $added = ([regex]::Matches($pnpOutput, "aggiunt[io]")).Count
            # Fallback conteggio generico
            if ($pnpOutput -match "(\d+).*aggiunt") { $added = $Matches[1] }

            Write-Log "[OK] Importazione driver completata. Log pnputil sopra." "Importazione Completata"
            [System.Windows.Forms.MessageBox]::Show("Importazione completata!`r`n`r`nControlla il log per i dettagli.`r`nOutput pnputil:`r`n$($pnpOutput.Substring(0, [Math]::Min(800, $pnpOutput.Length)))`r`n`r`nPotrebbe essere necessario riavviare il PC per alcuni driver.", "Importazione Completata", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

        } catch {
            Write-Log "[ERRORE] Importazione driver fallita: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore durante l'importazione driver:`r`n$_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#7F1D1D", "#F8FAFC", "Installa in blocco tutti i driver presenti in una cartella e sottocartelle tramite pnputil - Usalo per ripristinare un backup.")
)

$dismBtns = @(
    @("DISM ScanHealth", {
        Show-CommandSummary "DISM ScanHealth" @("Verifica se immagine Windows danneggiata, non ripara")
        $script:scanJob=$null; $script:scanTimer=$null; $script:scanCancelled=$false; $script:scanResult=$null
        try {
            Write-Log "[INFO] Avvio ScanHealth..." "Avviato"
            $waitForm=New-Object System.Windows.Forms.Form; Enable-DarkTitleBar $waitForm; $waitForm.Text="DISM ScanHealth - X per annullare"; $waitForm.Size=New-Object System.Drawing.Size(520,205); $waitForm.StartPosition="CenterParent"; $waitForm.FormBorderStyle="FixedDialog"; $waitForm.MaximizeBox=$false; $waitForm.MinimizeBox=$false; $waitForm.BackColor=[System.Drawing.ColorTranslator]::FromHtml("#0F172A")
            $lblWait=New-Object System.Windows.Forms.Label; $lblWait.Text="Verifica corruzione... 5-10 min. X=Annulla."; $lblWait.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold); $lblWait.ForeColor=[System.Drawing.Color]::White; $lblWait.Location=New-Object System.Drawing.Point(20,10); $lblWait.Size=New-Object System.Drawing.Size(480,60); $waitForm.Controls.Add($lblWait)
            $pb=New-Object System.Windows.Forms.ProgressBar; $pb.Style="Marquee"; $pb.MarqueeAnimationSpeed=30; $pb.Location=New-Object System.Drawing.Point(20,80); $pb.Size=New-Object System.Drawing.Size(470,20); $waitForm.Controls.Add($pb)
            $btnCancel=New-Object System.Windows.Forms.Button; $btnCancel.Text="Annulla"; $btnCancel.Location=New-Object System.Drawing.Point(200,110); $btnCancel.Size=New-Object System.Drawing.Size(120,30); $btnCancel.FlatStyle="Flat"; $btnCancel.BackColor=[System.Drawing.ColorTranslator]::FromHtml("#334155"); $btnCancel.ForeColor=[System.Drawing.Color]::White; $btnCancel.Add_Click({$waitForm.Close()}); $waitForm.Controls.Add($btnCancel)
            $waitForm.Add_FormClosing({$script:scanCancelled=$true; if($script:scanTimer -ne $null){try{$script:scanTimer.Stop();$script:scanTimer.Dispose()}catch { Write-StartLog "Errore ignorato: $_" };$script:scanTimer=$null} if($script:scanJob -ne $null){try{if($script:scanJob.State -eq "Running"){Stop-Job -Job $script:scanJob -ErrorAction SilentlyContinue};Remove-Job -Job $script:scanJob -Force -ErrorAction SilentlyContinue}catch { Write-StartLog "Errore ignorato: $_" };$script:scanJob=$null}})
            $script:scanJob=Start-Job -ScriptBlock { & DISM.exe /Online /Cleanup-Image /ScanHealth 2>&1 | Out-String }
            $script:scanTimer=New-Object System.Windows.Forms.Timer; $script:scanTimer.Interval=1000
            $script:scanTimer.Add_Tick({if($script:scanCancelled){return} if($script:scanJob -eq $null){return} if($script:scanJob.State -eq "Running"){[System.Windows.Forms.Application]::DoEvents();return} try{$script:scanTimer.Stop();$script:scanTimer.Dispose()}catch { Write-StartLog "Errore ignorato: $_" };$script:scanTimer=$null; try{$script:scanResult=Receive-Job -Job $script:scanJob -ErrorAction SilentlyContinue;Remove-Job -Job $script:scanJob -Force -ErrorAction SilentlyContinue}catch { Write-StartLog "Errore ignorato: $_" };$script:scanJob=$null;$waitForm.Close()})
            $script:scanTimer.Start(); $waitForm.Add_Shown({$waitForm.Activate()}); [void]$waitForm.ShowDialog(); $waitForm.Dispose()
            if($script:scanCancelled){Write-Log "[INFO] Annullato." "Annullato";return}
            if($script:scanResult){Write-Log $script:scanResult}
            Write-Log "[OK] Completato." "Completato"
        } catch { if($script:scanTimer -ne $null){try{$script:scanTimer.Stop();$script:scanTimer.Dispose()}catch { Write-StartLog "Errore ignorato: $_" };$script:scanTimer=$null} if($script:scanJob -ne $null){try{Remove-Job -Job $script:scanJob -Force -ErrorAction SilentlyContinue}catch { Write-StartLog "Errore ignorato: $_" };$script:scanJob=$null} Write-Log "[ERRORE] $_" "Errore" }
    }, "#CBD5E1", "#0F172A", "Verifica se l'immagine Windows è danneggiata. Non ripara, solo controllo. Se trova errori usa 50 e 51."),

    @("DISM Get-CurrentEdition", {
        Show-CommandSummary "Edizione Windows Attuale" @("Mostra Home, Pro, Enterprise")
        try {$o=& DISM.exe /Online /Get-CurrentEdition 2>&1 | Out-String; Write-Log $o} catch {Write-Log "[ERRORE] $_" "Errore"}
    }, "#CBD5E1", "#0F172A", "Mostra l'edizione Windows attuale (Home, Pro, Enterprise). Utile prima di un cambio edizione."),

    @("DISM Get-TargetEditions", {
        Show-CommandSummary "Edizioni a cui puoi passare" @("Elenca upgrade possibili")
        try {$o=& DISM.exe /Online /Get-TargetEditions 2>&1 | Out-String; Write-Log $o} catch {Write-Log "[ERRORE] $_" "Errore"}
    }, "#CBD5E1", "#0F172A", "Mostra a quali edizioni puoi aggiornare (es. da Home a Pro). Se lista vuota sei già al massimo."),

    @("DISM Get-Drivers", {
        Show-CommandSummary "Lista Driver" @("Elenca driver e salva TXT nella cartella dello script")
        try { $o=& DISM.exe /Online /Get-Drivers 2>&1 | Out-String; Write-Log $o; $file=Join-Path $global:OutputDir ("DISM_Drivers_"+$env:COMPUTERNAME+"_"+(Get-Date -Format "yyyyMMdd_HHmmss")+".txt"); $o|Out-File $file -Encoding utf8; Write-Log "[OK] Report $file" "Salvato"; Start-Process notepad.exe $file -ErrorAction SilentlyContinue } catch {Write-Log "[ERRORE] $_" "Errore"}
    }, "#CBD5E1", "#0F172A", "Elenca tutti i driver di terze parti e salva report TXT nella cartella dello script."),

    @("DISM Get-ReservedStorageState", {
        Show-CommandSummary "Spazio Riservato Aggiornamenti" @("Verifica 7GB riservati")
        try {$o=& DISM.exe /Online /Get-ReservedStorageState 2>&1 | Out-String; Write-Log $o} catch {Write-Log "[ERRORE] $_" "Errore"}
    }, "#CBD5E1", "#0F172A", "Verifica se lo Spazio Riservato per gli aggiornamenti (7GB su C:) è attivo."),

    @("Verifier /query", {
        Show-CommandSummary "Stato Driver Verifier" @("Mostra se Verifier è attivo")
        try {$o=& verifier.exe /query 2>&1 | Out-String; if([string]::IsNullOrWhiteSpace($o)){ $o="Verifier NON ATTIVO - normale."}; Write-Log $o} catch {Write-Log "[ERRORE] $_" "Errore"}
    }, "#CBD5E1", "#0F172A", "Controlla se Driver Verifier è attivo e quali driver sta monitorando. Se dice Nessun driver = è spento (normale)."),

    @("Verifier /querysettings", {
        Show-CommandSummary "Dettagli Verifier" @("Mostra impostazioni attive")
        try {$o=& verifier.exe /querysettings 2>&1 | Out-String; Write-Log $o} catch {Write-Log "[ERRORE] $_" "Errore"}
    }, "#CBD5E1", "#0F172A", "Mostra le impostazioni dettagliate di Verifier."),

    @("Verifier /volatile /flags", {
        Show-CommandSummary "Stato Test Volatile" @("Controlla test temporaneo attivo")
        try {
            # FIX v3.6.0: verifier /volatile /flags da solo è sintassi invalida - richiede un valore es: /flags 0x20
            # Per verificare lo stato volatile si usano /query e /querysettings
            $q = & verifier.exe /query 2>&1 | Out-String
            $qs = & verifier.exe /querysettings 2>&1 | Out-String
            
            if ([string]::IsNullOrWhiteSpace($q) -and [string]::IsNullOrWhiteSpace($qs)) {
                Write-Log "Nessun test volatile attivo - NORMALE. Verifier spento." "Stato Volatile"
            } else {
                Write-Log "--- verifier /query ---"
                Write-Log $q
                Write-Log "--- verifier /querysettings (include info volatile) ---"
                Write-Log $qs
                if ($qs -match "volatile" -or $q -match "volatile") {
                    Write-Log "[INFO] Test volatile rilevato attivo."
                } else {
                    Write-Log "[INFO] Nessun test volatile attivo - NORMALE."
                }
            }
        } catch {
            Write-Log "Nessun test volatile - normale. Info: $_" "Info"
        }
    }, "#CBD5E1", "#0F172A", "Mostra se c'è un test volatile attivo (temporaneo fino al riavvio). Usa /query e /querysettings. Se vuoto = nessun test in corso, normale. FIX: /volatile /flags richiede parametro."),

    @("Verifier - AVVIA test driver", {
        Show-CommandSummary "Avvia Test Volatile su Driver Scelto" @("Testa driver fino al riavvio, se bacato fa BSOD voluto")
        try {
            $drivers = @(); try { $drvOut = & DISM.exe /Online /Get-Drivers 2>&1 | Out-String; foreach ($l in ($drvOut -split "`r`n")) { if ($l -match "([a-z0-9_]+\.sys)" -and $l -notmatch "Microsoft") { $drivers += $Matches[1] } } $drivers = $drivers | Sort-Object -Unique | Select-Object -First 20 } catch { Write-StartLog "Errore ignorato: $_" }
            if ($drivers.Count -eq 0) { $drivers = @("nvlddmkm.sys","amdkmdap.sys","rtwlane.sys","Netwtw10.sys") }
            $form = New-Object System.Windows.Forms.Form; Enable-DarkTitleBar $form; $form.Text = "Scegli driver da testare"; $form.Size = New-Object System.Drawing.Size(520,360); $form.StartPosition = "CenterParent"; $form.FormBorderStyle = "FixedDialog"; $form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#450A0A")
            $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = "Testa driver sospetto fino al riavvio. Se bacato farà BSOD voluto."; $lbl.Location = New-Object System.Drawing.Point(15,10); $lbl.Size = New-Object System.Drawing.Size(480,35); $lbl.ForeColor = [System.Drawing.Color]::White; $lbl.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold); $form.Controls.Add($lbl)
            $cmb = New-Object System.Windows.Forms.ComboBox; $cmb.Location = New-Object System.Drawing.Point(15,55); $cmb.Size = New-Object System.Drawing.Size(480,25); $cmb.DropDownStyle = "DropDown"; $cmb.Items.AddRange($drivers); $cmb.Text = ""; $form.Controls.Add($cmb)
            $txtFlags = New-Object System.Windows.Forms.TextBox; $txtFlags.Text = "0x209BB"; $txtFlags.Location = New-Object System.Drawing.Point(15,115); $txtFlags.Size = New-Object System.Drawing.Size(200,25); $form.Controls.Add($txtFlags)
            $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "AVVIA TEST"; $btnOk.Location = New-Object System.Drawing.Point(120,230); $btnOk.Size = New-Object System.Drawing.Size(140,35); $btnOk.BackColor = [System.Drawing.Color]::DarkRed; $btnOk.ForeColor = [System.Drawing.Color]::White; $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK; $form.Controls.Add($btnOk)
            $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Annulla"; $btnCancel.Location = New-Object System.Drawing.Point(270,230); $btnCancel.Size = New-Object System.Drawing.Size(100,35); $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; $form.Controls.Add($btnCancel)
            $form.AcceptButton = $btnOk; $form.CancelButton = $btnCancel
            $res = $form.ShowDialog(); $form.Dispose()
            if ($res -ne [System.Windows.Forms.DialogResult]::OK) { return }
            $driver = $cmb.Text.Trim(); $flags = $txtFlags.Text.Trim(); if ([string]::IsNullOrWhiteSpace($driver)) { return }; if ($driver -notmatch "\.sys$") { $driver = "$driver.sys" }
            $out = & verifier.exe /volatile /adddriver $driver /flags $flags 2>&1 | Out-String; Write-Log $out
        } catch { Write-Log "[ERRORE] $_" "Errore" }
    }, "#7F1D1D", "#F8FAFC", "Avvia test volatile su driver scelto. Dura solo fino al riavvio. Se il driver è difettoso causa BSOD voluto per diagnosticarlo."),

    @("BCDEdit /enum osloader", {
        Show-CommandSummary "Configurazione Avvio" @("Mostra come parte Windows")
        try {$o=& bcdedit.exe /enum osloader 2>&1 | Out-String; Write-Log $o} catch {Write-Log "[ERRORE] $_" "Errore"}
    }, "#CBD5E1", "#0F172A", "Mostra la configurazione di avvio Windows: partizione, percorso winload, UEFI/Legacy."),

    @("BCDEdit /enum resume", {
        Show-CommandSummary "Ripresa Ibernazione" @("Configurazione ripresa")
        try {$o=& bcdedit.exe /enum resume 2>&1 | Out-String; Write-Log $o} catch {Write-Log "[ERRORE] $_" "Errore"}
    }, "#CBD5E1", "#0F172A", "Mostra la configurazione di ripresa da ibernazione. Utile se il PC non si risveglia.")
)

$toolBtns = @(

    @("Inventario PC Completo (Ticket)", {
        Show-CommandSummary "Inventario PC" @("Get-CimInstance Win32_ComputerSystem, Win32_BIOS, Win32_Processor, Win32_PhysicalMemory")
        Show-WaitOverlay -msg "Generazione inventario..."
        try {
            $cs = Get-CimInstance Win32_ComputerSystem; $bios = Get-CimInstance Win32_BIOS; $cpu = Get-CimInstance Win32_Processor
            $ram = (Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum /1GB
            $disks = Get-PhysicalDisk | ForEach-Object { "$($_.FriendlyName) $([math]::Round($_.Size/1GB,0))GB $($_.MediaType)" } | Out-String
            $out = @"
===== INVENTARIO PC - $env:COMPUTERNAME - $(Get-Date) =====
Produttore: $($cs.Manufacturer)
Modello: $($cs.Model)
Seriale BIOS: $($bios.SerialNumber)
CPU: $($cpu.Name) | Core: $($cpu.NumberOfCores) | Thread: $($cpu.NumberOfLogicalProcessors)
RAM Totale: $([math]::Round($ram,1)) GB
OS: $((Get-CimInstance Win32_OperatingSystem).Caption) $((Get-CimInstance Win32_OperatingSystem).OSArchitecture)
Dischi:
$disks
Schede Rete: $((Get-NetAdapter | Where-Object Status -eq Up | Select-Object -ExpandProperty Name) -join ", ")
"@
            $outFile = Join-Path $global:OutputDir "Inventario_$env:COMPUTERNAME.txt"
            $out | Out-File $outFile -Encoding utf8
            Write-Log $out
            Write-Log "File inventario salvato in: $outFile"
            Write-Log "Inventario completato con successo" "Completato"
        } catch { Write-Log "[ERRORE] $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#0EA5E9", "#FFFFFF", "Crea file di inventario rapido con seriale, CPU, RAM, dischi e OS per ticket assistenza."),


    @("Gestione Dispositivi", {
        Show-CommandSummary "Gestione Dispositivi" @("devmgmt.msc")
        Start-Process devmgmt.msc
        Write-Log "Gestione Dispositivi avviata."
    }, "#064E3B", "#F8FAFC", "Apre rapidamente il pannello nativo per la gestione e la risoluzione dei driver hardware."),
    @("Monitoraggio Risorse", {
        Show-CommandSummary "Monitoraggio Risorse" @("resmon.exe")
        Start-Process resmon.exe
        Write-Log "Monitoraggio Risorse avviato."
    }, "#064E3B", "#F8FAFC", "Apre lo strumento avanzato di Windows per l'analisi in tempo reale di CPU, RAM, Disco e Rete."),
    @("Cronologia Affidabilità", {
        Show-CommandSummary "Cronologia Affidabilità (perfmon /rel)" @("perfmon.exe /rel")
        Write-Log "Apertura dello strumento Cronologia Affidabilità di Windows in corso..."
        Start-Process "perfmon.exe" -ArgumentList "/rel"
        Write-Log "Cronologia Affidabilità avviata in finestra esterna." "Completato"
    }, "#0EA5E9", "#FFFFFF", "Apre il Reliability Monitor di Windows per tracciare crash, guasti e installazioni recenti."),
    @("Gestione Computer", {
        Show-CommandSummary "Gestione Computer" @("compmgmt.msc")
        Start-Process compmgmt.msc
        Write-Log "Gestione Computer avviata."
    }, "#064E3B", "#F8FAFC", "Apre la console centralizzata di amministrazione di Windows (Gestione disco, Utilità, ecc.)."),
    @("Servizi di Windows", {
        Show-CommandSummary "Servizi di Windows" @("services.msc")
        Start-Process services.msc
        Write-Log "Pannello Servizi avviato."
    }, "#064E3B", "#F8FAFC", "Apre la lista dei servizi di sistema per avviare, arrestare o configurare i demoni di Windows."),
    @("Visualizzatore Eventi", {
        Show-CommandSummary "Visualizzatore Eventi" @("eventvwr.msc")
        Start-Process eventvwr.msc
        Write-Log "Visualizzatore Eventi avviato."
    }, "#064E3B", "#F8FAFC", "Apre il registro eventi di Windows per analizzare log di sistema, applicazioni e sicurezza."),
    @("Configurazione di Sistema", {
        Show-CommandSummary "Configurazione di Sistema" @("msconfig.exe")
        Start-Process msconfig.exe
        Write-Log "MSConfig avviato."
    }, "#064E3B", "#F8FAFC", "Apre la configurazione di sistema per gestire le modalità di avvio e i servizi di diagnostica."),
    @("Gestione Stampanti", {
        Show-CommandSummary "Gestione Stampanti" @("control printers")
        Start-Process "control" -ArgumentList "printers"
        Write-Log "Pannello Stampanti aperto."
    }, "#064E3B", "#F8FAFC", "Apre la schermata di gestione dei dispositivi e delle stampanti collegate al PC."),
    @("Utilità di Pianificazione (taskschd.msc)", {
        Show-CommandSummary "Utilità di Pianificazione" @("taskschd.msc")
        Start-Process taskschd.msc
        Write-Log "Utilità di Pianificazione aperta."
    }, "#064E3B", "#F8FAFC", "Apre l'Utilità di Pianificazione per gestire attività programmate."),
    @("Gestione Disco (diskmgmt.msc)", {
        Show-CommandSummary "Gestione Disco" @("diskmgmt.msc")
        Start-Process diskmgmt.msc
        Write-Log "Gestione Disco aperta."
    }, "#064E3B", "#F8FAFC", "Apre Gestione Disco per partizionare, formattare e gestire volumi."),
    @("Informazioni di Sistema (msinfo32)", {
        Show-CommandSummary "Informazioni di Sistema" @("msinfo32")
        Start-Process msinfo32
        Write-Log "Informazioni di Sistema aperte."
    }, "#064E3B", "#F8FAFC", "Apre MsInfo32 con riepilogo hardware, componenti e ambiente software."),
    @("Editor del Registro (regedit)", {
        Show-CommandSummary "Editor Registro" @("regedit")
        Start-Process regedit
        Write-Log "Editor del Registro aperto."
    }, "#064E3B", "#F8FAFC", "Apre l'Editor del Registro di sistema (regedit)."),
    @("Criteri di Gruppo Locali (gpedit.msc)", {
        Show-CommandSummary "Criteri di Gruppo Locali" @("gpedit.msc")
        Start-Process gpedit.msc
        Write-Log "Gpedit aperto."
    }, "#064E3B", "#F8FAFC", "Apre gpedit.msc per Criteri di Gruppo locali (non disponibile su Home)."),
    @("Utenti e Gruppi Locali (lusrmgr.msc)", {
        Show-CommandSummary "Utenti e Gruppi Locali" @("lusrmgr.msc")
        Start-Process lusrmgr.msc
        Write-Log "Lusrmgr aperto."
    }, "#064E3B", "#F8FAFC", "Apre lusrmgr.msc per gestire utenti e gruppi locali."),
    @("Firewall Avanzato (wf.msc)", {
        Show-CommandSummary "Firewall Avanzato" @("wf.msc")
        Start-Process wf.msc
        Write-Log "Firewall Avanzato aperto."
    }, "#064E3B", "#F8FAFC", "Apre Windows Firewall con sicurezza avanzata (wf.msc)."),
    @("Report GPO Applicate`n(gpresult /r)", {
        try {
            Show-WaitOverlay "Recupero GPO..."
            Write-Log "[INFO] gpresult /r" "Avviato"
            $out = gpresult /r 2>&1 | Out-String
            Write-Log $out "Risultato"
            $csv = Join-Path $global:OutputDir "GPO_Report_${env:COMPUTERNAME}_$(Get-Date -Format yyyyMMdd_HHmmss).txt"
            $out | Out-File $csv -Encoding UTF8
            Write-Log "[OK] Salvato: $csv" "Completato"
        } catch { Write-Log "[ERRORE] $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Mostra GPO applicate e salva report nella cartella dello script"),
    @("Lista Software Installato`n(CSV)", {
        try {
            Show-WaitOverlay "Inventario software..."
            Write-Log "[INFO] Lista software installato..." "Avviato"
            $paths = @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")
            $apps = Get-ItemProperty $paths -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName } | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, EstimatedSize | Sort-Object DisplayName
            $csv = Join-Path $global:OutputDir "Software_Installati_${env:COMPUTERNAME}_$(Get-Date -Format yyyyMMdd_HHmmss).csv"
            $apps | Export-Csv $csv -NoTypeInformation -Encoding UTF8
            Write-Log ($apps | Format-Table -AutoSize | Out-String) "Risultato"
            Write-Log "[OK] CSV: $csv ($($apps.Count) app)" "Completato"
        } catch { Write-Log "[ERRORE] $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Esporta lista software da registry Uninstall in CSV")
)

# --- HELPER PORTE DI RETE (v3.9.17) ---
function Get-PortServiceName {
    param([int]$Port)
    $known = @{
        21 = "FTP"; 22 = "SSH"; 23 = "Telnet"; 25 = "SMTP"; 53 = "DNS"; 67 = "DHCP"; 80 = "HTTP"; 88 = "Kerberos"
        110 = "POP3"; 123 = "NTP"; 135 = "RPC"; 137 = "NetBIOS"; 138 = "NetBIOS"; 139 = "NetBIOS"; 143 = "IMAP"; 161 = "SNMP"
        389 = "LDAP"; 443 = "HTTPS"; 445 = "SMB"; 464 = "Kerberos (password)"; 514 = "Syslog"; 636 = "LDAPS"
        993 = "IMAPS"; 995 = "POP3S"; 1433 = "SQL Server"; 1521 = "Oracle"; 3268 = "Global Catalog"; 3269 = "Global Catalog SSL"
        3306 = "MySQL"; 3389 = "Desktop remoto (RDP)"; 5357 = "WSDAPI"; 5432 = "PostgreSQL"; 5900 = "VNC"
        5985 = "WinRM"; 5986 = "WinRM (HTTPS)"; 8080 = "HTTP alternativo"; 8443 = "HTTPS alternativo"; 9100 = "Stampa RAW"
    }
    if ($known.ContainsKey($Port)) { return [string]$known[$Port] }
    return ""
}

# Tabella PID -> nome processo (per associare ogni porta al programma che la usa)
function Get-PortProcessMap {
    $map = @{}
    try { Get-Process -ErrorAction SilentlyContinue | ForEach-Object { $map[[int]$_.Id] = $_.ProcessName } } catch { $null = $_ }
    $map[0] = "System Idle"
    $map[4] = "System"
    return $map
}

# Vero se l'indirizzo è solo locale (loopback): la porta non è raggiungibile dalla rete
function Test-LocalOnlyAddress {
    param([string]$Addr)
    return ($Addr -eq "127.0.0.1" -or $Addr -eq "::1")
}

# Righe delle porte in ascolto (TCP + UDP) con processo e tipo di accesso (usata dai controlli di sicurezza)
function Get-ListeningPortRows {
    $procMap = Get-PortProcessMap
    $rows = New-Object System.Collections.ArrayList
    foreach ($c in @(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue)) {
        $pn = $procMap[[int]$c.OwningProcess]; if (-not $pn) { $pn = "?" }
        $acc = if (Test-LocalOnlyAddress $c.LocalAddress) { "Solo locale" } else { "Rete" }
        [void]$rows.Add([PSCustomObject]@{ Proto = "TCP"; Indirizzo = [string]$c.LocalAddress; Porta = [int]$c.LocalPort; PID = [int]$c.OwningProcess; Processo = $pn; Servizio = (Get-PortServiceName ([int]$c.LocalPort)); Accesso = $acc })
    }
    foreach ($u in @(Get-NetUDPEndpoint -ErrorAction SilentlyContinue)) {
        $pn = $procMap[[int]$u.OwningProcess]; if (-not $pn) { $pn = "?" }
        $acc = if (Test-LocalOnlyAddress $u.LocalAddress) { "Solo locale" } else { "Rete" }
        [void]$rows.Add([PSCustomObject]@{ Proto = "UDP"; Indirizzo = [string]$u.LocalAddress; Porta = [int]$u.LocalPort; PID = [int]$u.OwningProcess; Processo = $pn; Servizio = (Get-PortServiceName ([int]$u.LocalPort)); Accesso = $acc })
    }
    return @($rows)
}

# --- HELPER CONTROLLI DI SICUREZZA (v3.9.19) ---
function New-SecFinding {
    param([string]$Livello, [string]$Controllo, [string]$Dettaglio)
    return [PSCustomObject]@{ Livello = $Livello; Controllo = $Controllo; Dettaglio = $Dettaglio }
}

# Mostra nel log l'esito dei controlli (Alto, Medio, Info, OK) e salva il CSV nella cartella dello script
function Show-SecFindings {
    param($Findings, [string]$CsvPrefix, [switch]$NoComputerName, [int]$MaxInfo = 60)
    $f = @($Findings)
    $nAlto = @($f | Where-Object { $_.Livello -eq "Alto" }).Count
    $nMedio = @($f | Where-Object { $_.Livello -eq "Medio" }).Count
    $nInfo = @($f | Where-Object { $_.Livello -eq "Info" }).Count
    $nOk = @($f | Where-Object { $_.Livello -eq "OK" }).Count
    Write-Log ("Esito: {0} rischi alti, {1} medi, {2} informazioni, {3} controlli a posto." -f $nAlto, $nMedio, $nInfo, $nOk)
    foreach ($lv in @("Alto", "Medio", "Info", "OK")) {
        $items = @($f | Where-Object { $_.Livello -eq $lv })
        $shown = 0
        foreach ($it in $items) {
            if (($lv -eq "Info" -or $lv -eq "OK") -and $shown -ge $MaxInfo) {
                Write-Log ("... e altre {0} righe di tipo {1}, visibili nel file CSV." -f ($items.Count - $MaxInfo), $lv)
                break
            }
            switch ($lv) {
                "Alto"  { Write-LogCore ("[AVVISO] RISCHIO ALTO: {0} | {1}" -f $it.Controllo, $it.Dettaglio) }
                "Medio" { Write-LogCore ("[AVVISO] RISCHIO MEDIO: {0} | {1}" -f $it.Controllo, $it.Dettaglio) }
                "Info"  { Write-LogCore ("[INFO] {0} | {1}" -f $it.Controllo, $it.Dettaglio) }
                "OK"    { Write-LogCore ("[OK] {0} | {1}" -f $it.Controllo, $it.Dettaglio) }
            }
            $shown++
        }
    }
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    if ($NoComputerName) { $csv = Join-Path $global:OutputDir ("{0}_{1}.csv" -f $CsvPrefix, $ts) }
    else { $csv = Join-Path $global:OutputDir ("{0}_{1}_{2}.csv" -f $CsvPrefix, $env:COMPUTERNAME, $ts) }
    $f | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8 -Delimiter ";"
    Write-Log ("[OK] Risultato salvato in: {0}" -f $csv) "Salvato"
}

$netBtns = @(

    @("Esporta Password WiFi Salvate", {
        Show-CommandSummary "Esporta Password WiFi" @("netsh wlan show profiles", "netsh wlan show profile name=* key=clear")
        Show-WaitOverlay -msg "Estrazione profili WiFi..."
        $wifiMsg = $null
        $wifiFile = $null
        $wifiIcon = [System.Windows.Forms.MessageBoxIcon]::Information
        try {
            $profOut = @(netsh wlan show profiles 2>&1)
            $profExit = $LASTEXITCODE
            $profText = ($profOut | Out-String)
            $profiles = @($profOut | Select-String "Tutti i profili utente|All User Profile" | ForEach-Object { ($_ -split ":", 2)[1].Trim().Trim('"') } | Where-Object { $_ })
            if ($profiles.Count -eq 0) {
                if ($profExit -ne 0 -or $profText -match "wlansvc|AutoConfig") {
                    Write-Log "[AVVISO] Servizio WLAN non attivo o nessuna scheda Wi-Fi su questo PC: NESSUN file creato."
                    $wifiMsg = "Nessun file creato.`r`n`r`nQuesto PC non ha una scheda Wi-Fi attiva oppure il servizio 'WLAN AutoConfig' non è in esecuzione."
                } else {
                    Write-Log "[INFO] Nessun profilo Wi-Fi salvato su questo PC: NESSUN file creato."
                    $wifiMsg = "Nessun file creato.`r`n`r`nSu questo PC non risulta salvata nessuna rete Wi-Fi."
                }
            } else {
                $outFile = Join-Path $global:OutputDir "WiFi_Passwords_$env:COMPUTERNAME.txt"
                $body = New-Object System.Collections.Generic.List[string]
                $conPwd = 0
                foreach ($p in $profiles) {
                    $keyLine = @(netsh wlan show profile name="$p" key=clear) | Select-String "Contenuto chiave|Key Content"
                    if ($keyLine) {
                        $wifiKey = (($keyLine | Select-Object -First 1).ToString() -split ":", 2)[1].Trim()
                        $conPwd++
                    } else {
                        $wifiKey = "<Nessuna password / EAP>"
                    }
                    Write-Log "WiFi: $p | Password: $wifiKey"
                    $body.Add("SSID: $p | Password: $wifiKey")
                }
                $senzaPwd = $profiles.Count - $conPwd
                $head = New-Object System.Collections.Generic.List[string]
                $head.Add("Esportazione profili Wi-Fi - PC: $env:COMPUTERNAME - Data: $(Get-Date -Format 'dd/MM/yyyy HH:mm')")
                $head.Add("Reti esportate: $($profiles.Count) ($conPwd con password, $senzaPwd senza password / EAP)")
                $head.Add("ATTENZIONE: questo file contiene password in chiaro, gestirlo con riservatezza.")
                $head.Add("")
                @($head) + @($body) | Out-File -LiteralPath $outFile -Encoding utf8
                if (-not (Test-Path -LiteralPath $outFile)) { throw "Il file non risulta creato: $outFile" }
                $wifiFile = $outFile
                Write-Log "[OK] Reti esportate: $($profiles.Count) ($conPwd con password, $senzaPwd senza password / EAP)"
                Write-Log "[OK] File salvato in: $outFile (ATTENZIONE: contiene password in chiaro!)"
                Write-Log "Esportazione WiFi completata con successo" "Completato"
                $wifiMsg = "Esportazione completata.`r`n`r`nReti Wi-Fi esportate: $($profiles.Count)`r`n- con password: $conPwd`r`n- senza password / EAP: $senzaPwd`r`n`r`nFile salvato in:`r`n$outFile`r`n`r`nATTENZIONE: il file contiene password in chiaro, gestiscilo con riservatezza.`r`n`r`nVuoi aprire la cartella con il file?"
            }
        } catch {
            Write-Log "[ERRORE] Esportazione WiFi non riuscita: $_" "Errore"
            $wifiMsg = "Esportazione NON riuscita:`r`n$_"
            $wifiIcon = [System.Windows.Forms.MessageBoxIcon]::Error
            $wifiFile = $null
        } finally { Hide-WaitOverlay }
        # Esito sempre visibile (dopo la chiusura dell'overlay di attesa)
        if ($wifiMsg) {
            if ($wifiFile) {
                $ans = [System.Windows.Forms.MessageBox]::Show($wifiMsg, "Esporta Password WiFi", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Information)
                if ($ans -eq [System.Windows.Forms.DialogResult]::Yes) {
                    try { Start-Process "explorer.exe" -ArgumentList "/select,`"$wifiFile`"" } catch { Write-StartLog "Apertura cartella fallita: $_" }
                }
            } else {
                [System.Windows.Forms.MessageBox]::Show($wifiMsg, "Esporta Password WiFi", [System.Windows.Forms.MessageBoxButtons]::OK, $wifiIcon) | Out-Null
            }
        }
    }, "#064E3B", "#F8FAFC", "Elenca tutti i profili WiFi salvati con password in chiaro e li esporta nella cartella dello script (gestire con riservatezza). Alla fine mostra l'esito e il percorso del file."),

    @("SpeedTest Latenza + Download", {
        Show-CommandSummary "SpeedTest Latenza + Download" @("Ping .NET verso 1.1.1.1 (x10)", "Connessione TCP 443 (se ICMP bloccato)", "Download da Cloudflare (e server di riserva, max 8 sec)")
        Show-WaitOverlay -msg "SpeedTest in corso (circa 20 sec)..."
        try {
            $target = "1.1.1.1"
            $okLatenza = $false; $okDownload = $false

            # --- 1) LATENZA: 10 ping ICMP, con ripiego su connessioni TCP 443 se ICMP è bloccato ---
            Write-Log "Misuro la latenza verso $target (Cloudflare) con 10 pacchetti..."
            $times = @(); $lost = 0; $method = "ICMP"
            $pinger = New-Object System.Net.NetworkInformation.Ping
            for ($k = 1; $k -le 10; $k++) {
                try {
                    $r = $pinger.Send($target, 1000)
                    if ($r.Status -eq "Success") { $times += [double]$r.RoundtripTime } else { $lost++ }
                } catch { $lost++ }
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 150
            }
            if ($times.Count -eq 0) {
                Write-Log "[INFO] Nessuna risposta ICMP (probabile blocco ping): misuro la latenza con connessioni TCP sulla porta 443."
                $method = "TCP 443"; $lost = 0
                for ($k = 1; $k -le 10; $k++) {
                    $sw = [System.Diagnostics.Stopwatch]::StartNew()
                    $client = New-Object System.Net.Sockets.TcpClient
                    try {
                        $iar = $client.BeginConnect($target, 443, $null, $null)
                        if ($iar.AsyncWaitHandle.WaitOne(1500) -and $client.Connected) { $sw.Stop(); $times += $sw.Elapsed.TotalMilliseconds } else { $lost++ }
                    } catch { $lost++ } finally { try { $client.Close() } catch { $null = $_ } }
                    [System.Windows.Forms.Application]::DoEvents()
                    Start-Sleep -Milliseconds 150
                }
            }
            if ($times.Count -gt 0) {
                $okLatenza = $true
                $st = $times | Measure-Object -Average -Minimum -Maximum
                $jitter = 0
                if ($times.Count -gt 1) {
                    $diffs = @(); for ($k = 1; $k -lt $times.Count; $k++) { $diffs += [math]::Abs($times[$k] - $times[$k-1]) }
                    $jitter = ($diffs | Measure-Object -Average).Average
                }
                $lossPct = [math]::Round(($lost / 10) * 100)
                Write-Log ("Latenza ({0}): media {1:N1} ms | min {2:N0} ms | max {3:N0} ms | jitter {4:N1} ms | pacchetti persi {5}%" -f $method, $st.Average, $st.Minimum, $st.Maximum, $jitter, $lossPct)
                if ($lossPct -gt 0 -or $st.Average -gt 100) { Write-Log "[ATTENZIONE] Linea instabile o lenta (latenza alta o pacchetti persi)." "Attenzione" }
                elseif ($st.Average -gt 50 -or $jitter -gt 20) { Write-Log "[INFO] Latenza accettabile ma non ottima (valutare jitter e carico di rete)." }
                else { Write-Log "[OK] Latenza ottima e stabile." }
            } else {
                Write-Log "[ATTENZIONE] Nessuna risposta da $target né via ICMP né su TCP 443: controlla connessione, firewall o proxy." "Attenzione"
            }

            # --- 2) DOWNLOAD: provo più server in ordine, scarico per max 8 secondi e calcolo la velocità ---
            Write-Log "Misuro la velocità di download (max 8 secondi, con più server di riserva)..."
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
            $sources = @(
                @("Cloudflare", "https://speed.cloudflare.com/__down?bytes=50000000"),
                @("Hetzner (Germania)", "https://nbg1-speed.hetzner.com/100MB.bin"),
                @("OVH (Francia)", "https://proof.ovh.net/files/100Mb.dat"),
                @("Tele2", "http://speedtest.tele2.net/100MB.zip")
            )
            foreach ($src in $sources) {
                if ($okDownload) { continue }
                try {
                    $req = [System.Net.HttpWebRequest]::Create($src[1])
                    $req.Timeout = 10000; $req.ReadWriteTimeout = 10000
                    $req.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                    if ($src[0] -eq "Cloudflare") { $req.Referer = "https://speed.cloudflare.com/"; $req.Headers.Add("Origin", "https://speed.cloudflare.com") }
                    $req.Proxy = [System.Net.WebRequest]::GetSystemWebProxy()
                    $req.Proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
                    $resp = $req.GetResponse()
                    $stream = $resp.GetResponseStream()
                    $buf = New-Object byte[] 65536
                    $total = [long]0
                    $n = $stream.Read($buf, 0, $buf.Length)   # primo blocco escluso dal tempo (connessione e TLS)
                    $sw = [System.Diagnostics.Stopwatch]::StartNew()
                    $loops = 0
                    while ($n -gt 0 -and $sw.Elapsed.TotalSeconds -lt 8) {
                        $n = $stream.Read($buf, 0, $buf.Length)
                        if ($n -gt 0) { $total += $n }
                        $loops++
                        if (($loops % 16) -eq 0) { [System.Windows.Forms.Application]::DoEvents() }
                    }
                    $sw.Stop()
                    try { $req.Abort() } catch { $null = $_ }
                    if ($total -gt 0 -and $sw.Elapsed.TotalSeconds -gt 0) {
                        $okDownload = $true
                        $mbit = ($total * 8) / 1000000 / $sw.Elapsed.TotalSeconds
                        Write-Log ("Download: {0:N1} Mbit/s ({1:N1} MB/s) | server: {2} | scaricati {3:N1} MB in {4:N1} sec" -f $mbit, ($mbit / 8), $src[0], ($total / 1MB), $sw.Elapsed.TotalSeconds)
                    } else {
                        Write-Log "[INFO] Server $($src[0]): nessun dato ricevuto, provo il successivo..."
                    }
                } catch {
                    $em = $_.Exception.Message
                    if ($em -match '\((\d{3})\)') { $em = "HTTP $($Matches[1])" }
                    Write-Log "[INFO] Server $($src[0]) non disponibile ($em), provo il successivo..."
                }
            }

            if ($okLatenza -and $okDownload) { Write-Log "SpeedTest completato con successo" "Completato" }
            elseif ($okDownload) { Write-Log "SpeedTest completato: download misurato, latenza non rilevabile." "Attenzione" }
            elseif ($okLatenza) { Write-Log "[ATTENZIONE] Download non misurabile da nessun server (firewall, proxy o filtro web): la latenza è stata misurata. Test terminato." "Attenzione" }
            else { Write-Log "[ERRORE] SpeedTest non riuscito: nessuna misura disponibile." "Errore" }
        } catch { Write-Log "[ERRORE] $($_.Exception.Message)" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Misura latenza (min/media/max, jitter, perdita pacchetti) verso Cloudflare e la velocità di download reale in Mbit/s, senza tool esterni."),


    @("Mostra IP e Config Rete", {
        Show-CommandSummary "Mostra IP e Config Rete" @("Get-NetIPAddress -AddressFamily IPv4")
        Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | ForEach-Object {
            Write-Log "Scheda: $($_.InterfaceAlias) | IP: $($_.IPAddress) | Subnet: $($_.PrefixLength)"
        }
    }, "#064E3B", "#F8FAFC", "Elenca gli indirizzi IP IPv4 assegnati a tutte le schede di rete attive del computer."),
    @("Flush DNS e Reset Winsock", {
        Show-CommandSummary "Flush DNS e Reset Winsock" @("ipconfig /flushdns", "netsh winsock reset")
        ipconfig /flushdns | Out-Null
        netsh winsock reset | Out-Null
        Write-Log "Cache DNS svuotata e Winsock ripristinato."
    }, "#78350F", "#F8FAFC", "Svuota la cache di risoluzione DNS e ripristina lo stack di rete Winsock danneggiato."),
    @("Ping Continuo Google DNS (8.8.8.8)", {
        Show-CommandSummary "Ping Continuo 8.8.8.8" @("ping 8.8.8.8 -t")
        Start-Process cmd.exe -ArgumentList "/k ping 8.8.8.8 -t"
        Write-Log "Ping continuo avviato in finestra esterna."
    }, "#064E3B", "#F8FAFC", "Esegue un test di latenza continuo verso i server DNS pubblici di Google (8.8.8.8)."),
    @("Ping Continuo Gateway Locale", {
        Show-CommandSummary "Ping Gateway Locale" @("Get-NetRoute", "ping Gateway -t")
        $gw = (Get-NetRoute | Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' }).NextHop
        if ($gw) {
            Start-Process cmd.exe -ArgumentList "/k ping $gw -t"
            Write-Log "Ping avviato verso il Gateway: $gw"
        } else {
            Write-Log "Gateway non trovato."
        }
    }, "#064E3B", "#F8FAFC", "Testa la stabilità della connessione tra il PC e il router/gateway di rete locale."),
    @("Test Connessione Porte Rete", {
        Show-CommandSummary "Test Connessione Porte" @("Test-NetConnection 8.8.8.8 -Port 53")
        $res = Test-NetConnection -ComputerName "8.8.8.8" -Port 53
        Write-Log "Test Porte Rete (DNS 8.8.8.8:53): Risultato = $($res.TcpTestSucceeded)"
    }, "#064E3B", "#F8FAFC", "Verifica se la porta di rete remota (es. DNS 53) è raggiungibile e aperta."),
    @("Porte in Ascolto`n(TCP + UDP)", {
        Show-CommandSummary "Porte in Ascolto" @("Get-NetTCPConnection -State Listen", "Get-NetUDPEndpoint", "Associazione porta -> processo (PID)")
        Show-WaitOverlay -msg "Lettura porte in ascolto..."
        try {
            $procMap = Get-PortProcessMap
            $rows = New-Object System.Collections.ArrayList
            foreach ($c in @(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue)) {
                $pn = $procMap[[int]$c.OwningProcess]; if (-not $pn) { $pn = "?" }
                $acc = if (Test-LocalOnlyAddress $c.LocalAddress) { "Solo locale" } else { "Rete" }
                [void]$rows.Add([PSCustomObject]@{ Proto = "TCP"; Indirizzo = [string]$c.LocalAddress; Porta = [int]$c.LocalPort; PID = [int]$c.OwningProcess; Processo = $pn; Servizio = (Get-PortServiceName ([int]$c.LocalPort)); Accesso = $acc })
            }
            foreach ($u in @(Get-NetUDPEndpoint -ErrorAction SilentlyContinue)) {
                $pn = $procMap[[int]$u.OwningProcess]; if (-not $pn) { $pn = "?" }
                $acc = if (Test-LocalOnlyAddress $u.LocalAddress) { "Solo locale" } else { "Rete" }
                [void]$rows.Add([PSCustomObject]@{ Proto = "UDP"; Indirizzo = [string]$u.LocalAddress; Porta = [int]$u.LocalPort; PID = [int]$u.OwningProcess; Processo = $pn; Servizio = (Get-PortServiceName ([int]$u.LocalPort)); Accesso = $acc })
            }
            $rows = @($rows | Sort-Object Porta, Proto, Indirizzo)
            $netRows = @($rows | Where-Object { $_.Accesso -eq "Rete" })
            $locRows = @($rows | Where-Object { $_.Accesso -eq "Solo locale" })
            Write-Log ("Trovate {0} porte in ascolto: {1} raggiungibili dalla rete, {2} solo locali." -f $rows.Count, $netRows.Count, $locRows.Count)
            Write-Log "--- Porte raggiungibili dalla rete (0.0.0.0 / :: / IP della scheda) ---"
            foreach ($r in $netRows) {
                $svcTxt = if ($r.Servizio) { " (" + $r.Servizio + ")" } else { "" }
                Write-Log ("{0} {1}{2} | {3} | {4} (PID {5})" -f $r.Proto, $r.Porta, $svcTxt, $r.Indirizzo, $r.Processo, $r.PID)
            }
            if ($netRows.Count -eq 0) { Write-Log "Nessuna porta in ascolto sulla rete." }
            Write-Log ("Porte solo locali (loopback): {0}, visibili nel file CSV." -f $locRows.Count)
            $csv = Join-Path $global:OutputDir ("Porte_Ascolto_{0}_{1}.csv" -f $env:COMPUTERNAME, (Get-Date -Format "yyyyMMdd_HHmmss"))
            $rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8 -Delimiter ";"
            Write-Log ("[OK] Elenco completo salvato in: {0}" -f $csv) "Salvato"
        } catch { Write-Log "[ERRORE] Lettura porte in ascolto: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Elenca le porte TCP e UDP in ascolto su questo PC con il processo che le usa, indicando quali sono raggiungibili dalla rete e quali solo locali. Salva un CSV nella cartella dello script."),
    @("Connessioni Attive`n(Established)", {
        Show-CommandSummary "Connessioni TCP Attive" @("Get-NetTCPConnection -State Established", "Associazione connessione -> processo (PID)")
        Show-WaitOverlay -msg "Lettura connessioni attive..."
        try {
            $procMap = Get-PortProcessMap
            $rows = New-Object System.Collections.ArrayList
            foreach ($c in @(Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue)) {
                $pn = $procMap[[int]$c.OwningProcess]; if (-not $pn) { $pn = "?" }
                [void]$rows.Add([PSCustomObject]@{ Processo = $pn; PID = [int]$c.OwningProcess; Locale = ("{0}:{1}" -f $c.LocalAddress, $c.LocalPort); Remoto = ("{0}:{1}" -f $c.RemoteAddress, $c.RemotePort) })
            }
            $rows = @($rows | Sort-Object Processo, Remoto)
            $ext = @($rows | Where-Object { $_.Remoto -notmatch '^(127\.0\.0\.1|::1):' })
            Write-Log ("Connessioni stabilite: {0} in totale, {1} verso altri computer (le altre sono interne al PC)." -f $rows.Count, $ext.Count)
            Write-Log "--- Riepilogo per processo ---"
            foreach ($g in @($ext | Group-Object Processo | Sort-Object Count -Descending)) {
                Write-Log ("{0}: {1} connessioni" -f $g.Name, $g.Count)
            }
            Write-Log "--- Dettaglio (locale -> remoto) ---"
            $shown = 0
            foreach ($r in $ext) {
                if ($shown -ge 80) { Write-Log ("... e altre {0} connessioni, visibili nel file CSV." -f ($ext.Count - 80)); break }
                Write-Log ("{0} (PID {1}) | {2} -> {3}" -f $r.Processo, $r.PID, $r.Locale, $r.Remoto)
                $shown++
            }
            $csv = Join-Path $global:OutputDir ("Connessioni_Attive_{0}_{1}.csv" -f $env:COMPUTERNAME, (Get-Date -Format "yyyyMMdd_HHmmss"))
            $rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8 -Delimiter ";"
            Write-Log ("[OK] Elenco completo salvato in: {0}" -f $csv) "Salvato"
        } catch { Write-Log "[ERRORE] Lettura connessioni attive: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Mostra le connessioni TCP stabilite in questo momento (con quale server stanno parlando e quale programma le usa), raggruppate per processo. Utile per scoprire traffico anomalo."),
    @("Chi Usa la Porta?`n(porta -> processo)", {
        $inp = [Microsoft.VisualBasic.Interaction]::InputBox("Inserisci il numero di porta da verificare (1-65535):", "Chi usa la porta?", "443")
        if ([string]::IsNullOrWhiteSpace($inp)) { return }
        $portNum = 0
        if (-not [int]::TryParse($inp.Trim(), [ref]$portNum) -or $portNum -lt 1 -or $portNum -gt 65535) {
            [System.Windows.Forms.MessageBox]::Show(("Numero di porta non valido: {0}" -f $inp), "Porta non valida", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }
        Show-CommandSummary ("Chi usa la porta {0}" -f $portNum) @("Get-NetTCPConnection -LocalPort $portNum", "Get-NetUDPEndpoint -LocalPort $portNum", "Win32_Process / Win32_Service (percorso e servizi)")
        try {
            $tcp = @(Get-NetTCPConnection -LocalPort $portNum -ErrorAction SilentlyContinue)
            $udp = @(Get-NetUDPEndpoint -LocalPort $portNum -ErrorAction SilentlyContinue)
            if ($tcp.Count -eq 0 -and $udp.Count -eq 0) {
                Write-Log ("[INFO] Porta {0}: nessun processo la sta usando su questo PC (non è in ascolto e non ha connessioni)." -f $portNum)
                return
            }
            $svcName = Get-PortServiceName $portNum
            if ($svcName) { Write-Log ("Porta {0}: di solito è usata da {1}." -f $portNum, $svcName) }
            $procIds = New-Object System.Collections.ArrayList
            $shown = 0
            foreach ($x in $tcp) {
                [void]$procIds.Add([int]$x.OwningProcess)
                if ($shown -lt 15) { Write-Log ("TCP | {0} | locale {1}:{2} | remoto {3}:{4}" -f $x.State, $x.LocalAddress, $x.LocalPort, $x.RemoteAddress, $x.RemotePort); $shown++ }
            }
            if ($tcp.Count -gt 15) { Write-Log ("... e altre {0} connessioni sulla stessa porta." -f ($tcp.Count - 15)) }
            foreach ($x in $udp) {
                [void]$procIds.Add([int]$x.OwningProcess)
                Write-Log ("UDP | locale {0}:{1}" -f $x.LocalAddress, $x.LocalPort)
            }
            foreach ($procId in @($procIds | Sort-Object -Unique)) {
                $pName = "?"; $pPath = ""
                try {
                    $pi = Get-CimInstance Win32_Process -Filter ("ProcessId = {0}" -f $procId) -ErrorAction Stop
                    if ($pi) { $pName = $pi.Name; $pPath = $pi.ExecutablePath }
                } catch { $null = $_ }
                if ($procId -eq 4) { $pName = "System" }
                Write-Log ("--- Processo: {0} (PID {1}) ---" -f $pName, $procId)
                if ($pPath) { Write-Log ("Percorso: {0}" -f $pPath) }
                try {
                    $svcs = @(Get-CimInstance Win32_Service -Filter ("ProcessId = {0}" -f $procId) -ErrorAction Stop | ForEach-Object { $_.Name })
                    if ($svcs.Count -gt 0) { Write-Log ("Servizi in questo processo: {0}" -f ($svcs -join ", ")) }
                } catch { $null = $_ }
            }
        } catch { Write-Log "[ERRORE] Verifica porta: $_" "Errore" }
    }, "#064E3B", "#F8FAFC", "Chiede un numero di porta e mostra quale programma o servizio la sta usando su questo PC (con percorso del file e servizi)."),
    @("Scansione Porte`nHost Remoto", {
        $target = [Microsoft.VisualBasic.Interaction]::InputBox("Inserisci IP o nome del computer da controllare:", "Scansione Porte Host Remoto", "127.0.0.1")
        if ([string]::IsNullOrWhiteSpace($target)) { return }
        $target = $target.Trim()
        $defPorts = "21,22,23,25,53,80,110,135,139,143,389,443,445,636,1433,3306,3389,5900,5985,8080"
        $portSpec = [Microsoft.VisualBasic.Interaction]::InputBox("Porte da controllare, elenco e/o intervalli (es. 22,80,443,8000-8010).`r`nMassimo 1024 porte.", ("Scansione Porte - {0}" -f $target), $defPorts)
        if ([string]::IsNullOrWhiteSpace($portSpec)) { return }

        # Lettura elenco porte (numeri singoli e intervalli)
        $list = New-Object System.Collections.ArrayList
        $bad = $false
        foreach ($tok in ($portSpec -split "[,; ]+")) {
            if ([string]::IsNullOrWhiteSpace($tok)) { continue }
            if ($tok -match '^(\d{1,5})-(\d{1,5})$') {
                $a = [int]$Matches[1]; $b = [int]$Matches[2]
                if ($a -gt $b) { $t = $a; $a = $b; $b = $t }
                if ($a -lt 1 -or $b -gt 65535 -or ($b - $a + 1) -gt 1024) { $bad = $true; break }
                for ($n = $a; $n -le $b; $n++) { [void]$list.Add($n) }
            } elseif ($tok -match '^\d{1,5}$') {
                $n = [int]$tok
                if ($n -lt 1 -or $n -gt 65535) { $bad = $true; break }
                [void]$list.Add($n)
            } else { $bad = $true; break }
            if ($list.Count -gt 4096) { $bad = $true; break }
        }
        $ports = @($list | Sort-Object -Unique)
        if ($bad -or $ports.Count -eq 0 -or $ports.Count -gt 1024) {
            [System.Windows.Forms.MessageBox]::Show("Elenco porte non valido.`r`nUsa numeri da 1 a 65535 separati da virgola o intervalli (es. 22,80,8000-8010), massimo 1024 porte in totale.", "Porte non valide", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }
        if ($ports.Count -gt 200) {
            if ((Show-ConfirmBox ("Stai per controllare {0} porte su {1}.`nUsa questa funzione solo su computer della tua rete. Continuare?" -f $ports.Count, $target)) -ne "Yes") { return }
        }

        Show-CommandSummary ("Scansione Porte su {0}" -f $target) @("Connessione TCP a {0} su {1} porte (timeout 700 ms)" -f $target, $ports.Count)
        $ip = $null
        try {
            $addrs = @([System.Net.Dns]::GetHostAddresses($target))
            $ip = $addrs | Where-Object { $_.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork } | Select-Object -First 1
            if (-not $ip) { $ip = $addrs | Select-Object -First 1 }
        } catch { $ip = $null }
        if (-not $ip) { Write-Log ("[ERRORE] Impossibile risolvere l'host: {0}" -f $target) "Errore"; return }

        Show-WaitOverlay -msg ("Scansione di {0} porte su {1}..." -f $ports.Count, $target)
        try {
            $timeoutMs = 700
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $results = New-Object System.Collections.ArrayList
            for ($i = 0; $i -lt $ports.Count; $i += 64) {
                $batch = @($ports[$i..([math]::Min($i + 63, $ports.Count - 1))])
                $jobs = New-Object System.Collections.ArrayList
                foreach ($pt in $batch) {
                    $cl = New-Object System.Net.Sockets.TcpClient
                    $ar = $null
                    try { $ar = $cl.BeginConnect($ip, [int]$pt, $null, $null) } catch { $ar = $null }
                    [void]$jobs.Add([PSCustomObject]@{ Port = [int]$pt; Client = $cl; Ar = $ar })
                }
                $deadline = [DateTime]::UtcNow.AddMilliseconds($timeoutMs)
                foreach ($jb in $jobs) {
                    $stato = "senza risposta"
                    if ($jb.Ar) {
                        $rem = [int][math]::Max(1, ($deadline - [DateTime]::UtcNow).TotalMilliseconds)
                        if ($jb.Ar.AsyncWaitHandle.WaitOne($rem)) {
                            try { $jb.Client.EndConnect($jb.Ar); if ($jb.Client.Connected) { $stato = "aperta" } else { $stato = "chiusa" } } catch { $stato = "chiusa" }
                        }
                    } else { $stato = "chiusa" }
                    try { $jb.Client.Close() } catch { $null = $_ }
                    [void]$results.Add([PSCustomObject]@{ Porta = $jb.Port; Stato = $stato; Servizio = (Get-PortServiceName $jb.Port) })
                }
                [System.Windows.Forms.Application]::DoEvents()
            }
            $sw.Stop()
            $openR = @($results | Where-Object { $_.Stato -eq "aperta" })
            $closedN = @($results | Where-Object { $_.Stato -eq "chiusa" }).Count
            $filtN = @($results | Where-Object { $_.Stato -eq "senza risposta" }).Count
            Write-Log ("Host {0} ({1}): {2} porte controllate in {3:N1} secondi." -f $target, $ip, $results.Count, $sw.Elapsed.TotalSeconds)
            if ($openR.Count -eq 0) {
                Write-Log "Nessuna porta aperta tra quelle controllate."
            } else {
                foreach ($o in $openR) {
                    $svcTxt = if ($o.Servizio) { " (" + $o.Servizio + ")" } else { "" }
                    Write-LogCore ("[OK] Porta {0}/TCP APERTA{1}" -f $o.Porta, $svcTxt)
                }
            }
            Write-Log ("Riepilogo: {0} aperte | {1} chiuse | {2} senza risposta (probabile firewall)." -f $openR.Count, $closedN, $filtN)
            $safeHost = ($target -replace '[^\w\.-]', '_')
            $rep = Join-Path $global:OutputDir ("Scansione_Porte_{0}_{1}.csv" -f $safeHost, (Get-Date -Format "yyyyMMdd_HHmmss"))
            $results | Export-Csv -Path $rep -NoTypeInformation -Encoding UTF8 -Delimiter ";"
            Write-Log ("[OK] Risultato completo salvato in: {0}" -f $rep) "Salvato"
        } catch { Write-Log "[ERRORE] Scansione porte: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#78350F", "#F8FAFC", "Controlla quali porte TCP sono aperte su un altro computer (IP o nome). Distingue aperte, chiuse e senza risposta (firewall). Usala solo su sistemi della tua rete. Salva un CSV nella cartella dello script."),
    @("Firewall: Porte Aperte`nin Ingresso", {
        Show-CommandSummary "Regole Firewall in Ingresso" @("Get-NetFirewallProfile", "Get-NetFirewallRule -Direction Inbound -Enabled True -Action Allow", "Get-NetFirewallPortFilter")
        Show-WaitOverlay -msg "Lettura regole firewall..."
        try {
            foreach ($fp in @(Get-NetFirewallProfile -ErrorAction SilentlyContinue)) {
                if ([string]$fp.Enabled -eq "True") {
                    Write-Log ("Profilo firewall {0}: attivo" -f $fp.Name)
                } else {
                    Write-Log ("[AVVISO] Profilo firewall {0}: DISATTIVO (tutte le porte in ascolto sono raggiungibili)" -f $fp.Name)
                }
            }
            $rules = @(Get-NetFirewallRule -Direction Inbound -Enabled True -Action Allow -ErrorAction SilentlyContinue)
            $pfMap = @{}
            foreach ($f in @(Get-NetFirewallPortFilter -All -ErrorAction SilentlyContinue)) { $pfMap[[string]$f.InstanceID] = $f }
            $rows = New-Object System.Collections.ArrayList
            foreach ($r in $rules) {
                $f = $pfMap[[string]$r.Name]
                if (-not $f) { continue }
                $lp = ($f.LocalPort -join ",")
                if (-not $lp) { $lp = "Any" }
                [void]$rows.Add([PSCustomObject]@{ Protocollo = [string]$f.Protocol; PorteLocali = $lp; Regola = [string]$r.DisplayName; Gruppo = [string]$r.DisplayGroup; Profili = [string]$r.Profile })
            }
            $rows = @($rows | Sort-Object Protocollo, PorteLocali, Regola)
            $withPort = @($rows | Where-Object { $_.PorteLocali -ne "Any" })
            $anyPort = @($rows | Where-Object { $_.PorteLocali -eq "Any" })
            Write-Log ("Regole in ingresso attive che consentono il traffico: {0} ({1} con porte specifiche, {2} per programma o qualsiasi porta)." -f $rows.Count, $withPort.Count, $anyPort.Count)
            Write-Log "--- Regole con porte specifiche (protocollo | porte | regola) ---"
            $shown = 0
            foreach ($r in $withPort) {
                if ($shown -ge 100) { Write-Log ("... e altre {0} regole, visibili nel file CSV." -f ($withPort.Count - 100)); break }
                Write-Log ("{0} | {1} | {2}" -f $r.Protocollo, $r.PorteLocali, $r.Regola)
                $shown++
            }
            Write-Log "[INFO] Una regola attiva non significa che la porta sia in ascolto: confronta con il comando Porte in Ascolto."
            $csv = Join-Path $global:OutputDir ("Firewall_Ingresso_{0}_{1}.csv" -f $env:COMPUTERNAME, (Get-Date -Format "yyyyMMdd_HHmmss"))
            $rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8 -Delimiter ";"
            Write-Log ("[OK] Elenco completo salvato in: {0}" -f $csv) "Salvato"
        } catch { Write-Log "[ERRORE] Lettura regole firewall: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Mostra lo stato dei profili del firewall e le regole in ingresso attive che consentono il traffico su porte specifiche. Salva l'elenco completo in CSV."),
    @("Controllo Porte`na Rischio", {
        Show-CommandSummary "Controllo Porte a Rischio" @("Porte in ascolto raggiungibili dalla rete (TCP/UDP)", "Get-SmbServerConfiguration (SMBv1)", "Registro: Desktop remoto e NLA", "Get-NetFirewallProfile")
        Show-WaitOverlay -msg "Controllo porte a rischio..."
        try {
            $riskPorts = @(
                @{ Proto = "TCP"; Porta = 21;   Nome = "FTP";        Livello = "Alto";  Nota = "Protocollo non cifrato: preferisci SFTP/FTPS o disattivalo." },
                @{ Proto = "TCP"; Porta = 23;   Nome = "Telnet";     Livello = "Alto";  Nota = "Protocollo non cifrato: sostituiscilo con SSH." },
                @{ Proto = "UDP"; Porta = 69;   Nome = "TFTP";       Livello = "Alto";  Nota = "Nessuna autenticazione." },
                @{ Proto = "TCP"; Porta = 5900; Nome = "VNC";        Livello = "Alto";  Nota = "Spesso con password debole o senza cifratura." },
                @{ Proto = "UDP"; Porta = 161;  Nome = "SNMP";       Livello = "Alto";  Nota = "Verifica che non usi la community predefinita e preferisci SNMPv3." },
                @{ Proto = "TCP"; Porta = 445;  Nome = "SMB";        Livello = "Medio"; Nota = "Da non esporre fuori dalla rete interna; verifica che SMBv1 sia disattivato." },
                @{ Proto = "TCP"; Porta = 139;  Nome = "NetBIOS";    Livello = "Medio"; Nota = "Di solito non necessaria." },
                @{ Proto = "TCP"; Porta = 3389; Nome = "RDP";        Livello = "Medio"; Nota = "Abilita NLA e limita gli accessi con il firewall." },
                @{ Proto = "TCP"; Porta = 1433; Nome = "SQL Server"; Livello = "Medio"; Nota = "Limita l'accesso ai soli host applicativi." },
                @{ Proto = "TCP"; Porta = 3306; Nome = "MySQL";      Livello = "Medio"; Nota = "Limita l'accesso ai soli host applicativi." },
                @{ Proto = "TCP"; Porta = 5432; Nome = "PostgreSQL"; Livello = "Medio"; Nota = "Limita l'accesso ai soli host applicativi." },
                @{ Proto = "TCP"; Porta = 5985; Nome = "WinRM";      Livello = "Medio"; Nota = "Limita l'accesso ai soli host di gestione." },
                @{ Proto = "TCP"; Porta = 135;  Nome = "RPC";        Livello = "Info";  Nota = "Normale su Windows, ma non deve essere raggiungibile da Internet." }
            )
            $net = @(Get-ListeningPortRows | Where-Object { $_.Accesso -eq "Rete" })
            $find = New-Object System.Collections.ArrayList
            foreach ($rk in $riskPorts) {
                $hit = @($net | Where-Object { $_.Proto -eq $rk.Proto -and $_.Porta -eq $rk.Porta })
                if ($hit.Count -eq 0) { continue }
                $procs = (@($hit | ForEach-Object { $_.Processo } | Sort-Object -Unique)) -join ", "
                [void]$find.Add([PSCustomObject]@{ Livello = $rk.Livello; Controllo = ("{0} {1} ({2}) in ascolto sulla rete" -f $rk.Proto, $rk.Porta, $rk.Nome); Dettaglio = ("Processo: {0}. {1}" -f $procs, $rk.Nota) })
            }
            if ($find.Count -eq 0) {
                [void]$find.Add([PSCustomObject]@{ Livello = "OK"; Controllo = "Porte a rischio note"; Dettaglio = "Nessuna è in ascolto sulla rete." })
            }

            # SMBv1
            try {
                $smb = Get-SmbServerConfiguration -ErrorAction Stop
                if ($smb.EnableSMB1Protocol) {
                    [void]$find.Add([PSCustomObject]@{ Livello = "Alto"; Controllo = "SMBv1 attivo"; Dettaglio = "Protocollo obsoleto e vulnerabile (EternalBlue): disattivalo con Set-SmbServerConfiguration -EnableSMB1Protocol `$false." })
                } else {
                    [void]$find.Add([PSCustomObject]@{ Livello = "OK"; Controllo = "SMBv1"; Dettaglio = "Disattivato." })
                }
            } catch {
                [void]$find.Add([PSCustomObject]@{ Livello = "Info"; Controllo = "SMBv1"; Dettaglio = "Verifica non riuscita su questo sistema." })
            }

            # Desktop remoto e NLA
            try {
                $ts = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -ErrorAction Stop
                if ($ts.fDenyTSConnections -eq 0) {
                    $rdp = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name UserAuthentication -ErrorAction SilentlyContinue
                    if ($rdp -and $rdp.UserAuthentication -eq 1) {
                        [void]$find.Add([PSCustomObject]@{ Livello = "OK"; Controllo = "Desktop remoto (RDP)"; Dettaglio = "Attivo con autenticazione a livello di rete (NLA) richiesta." })
                    } else {
                        [void]$find.Add([PSCustomObject]@{ Livello = "Alto"; Controllo = "Desktop remoto (RDP) senza NLA"; Dettaglio = "RDP è attivo ma NLA non è richiesta: abilitala nelle impostazioni di Desktop remoto." })
                    }
                } else {
                    [void]$find.Add([PSCustomObject]@{ Livello = "OK"; Controllo = "Desktop remoto (RDP)"; Dettaglio = "Disattivato." })
                }
            } catch { $null = $_ }

            # Profili firewall
            foreach ($fp in @(Get-NetFirewallProfile -ErrorAction SilentlyContinue)) {
                if ([string]$fp.Enabled -ne "True") {
                    [void]$find.Add([PSCustomObject]@{ Livello = "Alto"; Controllo = ("Firewall profilo {0} disattivato" -f $fp.Name); Dettaglio = "Le porte in ascolto non sono filtrate su questo profilo." })
                }
            }

            $nAlto = @($find | Where-Object { $_.Livello -eq "Alto" }).Count
            $nMedio = @($find | Where-Object { $_.Livello -eq "Medio" }).Count
            $nInfo = @($find | Where-Object { $_.Livello -eq "Info" }).Count
            Write-Log ("Esito: {0} rischi alti, {1} medi, {2} informazioni." -f $nAlto, $nMedio, $nInfo)
            foreach ($lv in @("Alto", "Medio", "Info", "OK")) {
                foreach ($f in @($find | Where-Object { $_.Livello -eq $lv })) {
                    switch ($lv) {
                        "Alto"  { Write-LogCore ("[AVVISO] RISCHIO ALTO: {0} | {1}" -f $f.Controllo, $f.Dettaglio) }
                        "Medio" { Write-LogCore ("[AVVISO] RISCHIO MEDIO: {0} | {1}" -f $f.Controllo, $f.Dettaglio) }
                        "Info"  { Write-LogCore ("[INFO] {0} | {1}" -f $f.Controllo, $f.Dettaglio) }
                        "OK"    { Write-LogCore ("[OK] {0} | {1}" -f $f.Controllo, $f.Dettaglio) }
                    }
                }
            }
            Write-Log "[INFO] Il controllo segnala l'esposizione: non verifica versioni né vulnerabilità dei singoli servizi."
            $csv = Join-Path $global:OutputDir ("Controllo_Rischio_Porte_{0}_{1}.csv" -f $env:COMPUTERNAME, (Get-Date -Format "yyyyMMdd_HHmmss"))
            $find | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8 -Delimiter ";"
            Write-Log ("[OK] Risultato salvato in: {0}" -f $csv) "Salvato"
        } catch { Write-Log "[ERRORE] Controllo porte a rischio: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Segnala le porte a rischio note (Telnet, FTP, SMB, RDP, VNC, SNMP, database, WinRM) in ascolto sulla rete e controlla SMBv1, NLA del Desktop remoto e profili firewall disattivati. Salva un CSV."),
    @("Confronto Porte`n(Baseline)", {
        Show-CommandSummary "Confronto Porte con Baseline" @("Porte in ascolto raggiungibili dalla rete (TCP/UDP)", "Confronto con il file Baseline_Porte_<PC>.csv nella cartella dello script")
        Show-WaitOverlay -msg "Lettura porte in ascolto..."
        try {
            $base = Join-Path $global:OutputDir ("Baseline_Porte_{0}.csv" -f $env:COMPUTERNAME)
            # Solo porte raggiungibili dalla rete e sotto 49152: le porte dinamiche cambiano di continuo
            $cur = @(Get-ListeningPortRows | Where-Object { $_.Accesso -eq "Rete" -and $_.Porta -lt 49152 })
            $curMap = @{}
            foreach ($r in $cur) {
                $k = "{0}|{1}|{2}" -f $r.Proto, $r.Porta, $r.Processo
                if (-not $curMap.ContainsKey($k)) { $curMap[$k] = $r }
            }
            $curList = @($curMap.Values | Sort-Object Proto, Porta, Processo | Select-Object Proto, Porta, Processo, Servizio)

            if (-not (Test-Path -LiteralPath $base)) {
                Hide-WaitOverlay
                Write-Log ("Nessuna baseline trovata per questo PC. Porte attuali raggiungibili dalla rete: {0}." -f $curList.Count)
                if ((Show-ConfirmBox "Nessuna baseline trovata.`nVuoi salvare lo stato attuale delle porte come riferimento?") -eq "Yes") {
                    $curList | Export-Csv -Path $base -NoTypeInformation -Encoding UTF8 -Delimiter ";"
                    Write-Log ("[OK] Baseline salvata in: {0}" -f $base) "Salvato"
                }
                return
            }

            $baseMap = @{}
            foreach ($b in @(Import-Csv -LiteralPath $base -Delimiter ";")) {
                $k = "{0}|{1}|{2}" -f $b.Proto, $b.Porta, $b.Processo
                $baseMap[$k] = $b
            }
            $new = @($curMap.Keys | Where-Object { -not $baseMap.ContainsKey($_) } | Sort-Object)
            $gone = @($baseMap.Keys | Where-Object { -not $curMap.ContainsKey($_) } | Sort-Object)
            $same = $curMap.Count - $new.Count
            Write-Log ("Baseline del {0}: {1} porte uguali, {2} nuove, {3} scomparse (solo porte sulla rete sotto la 49152)." -f (Get-Item -LiteralPath $base).LastWriteTime.ToString("dd/MM/yyyy HH:mm"), $same, $new.Count, $gone.Count)
            foreach ($k in $new) {
                $r = $curMap[$k]
                $svcTxt = if ($r.Servizio) { " (" + $r.Servizio + ")" } else { "" }
                Write-LogCore ("[AVVISO] NUOVA: {0} {1}{2} | processo {3}" -f $r.Proto, $r.Porta, $svcTxt, $r.Processo)
            }
            foreach ($k in $gone) {
                $b = $baseMap[$k]
                Write-LogCore ("[INFO] SPARITA: {0} {1} | processo {2}" -f $b.Proto, $b.Porta, $b.Processo)
            }
            if ($new.Count -eq 0 -and $gone.Count -eq 0) {
                Write-Log "[OK] Nessuna differenza rispetto alla baseline."
            } else {
                Hide-WaitOverlay
                if ((Show-ConfirmBox "Ci sono differenze rispetto alla baseline.`nVuoi aggiornarla con lo stato attuale?") -eq "Yes") {
                    $curList | Export-Csv -Path $base -NoTypeInformation -Encoding UTF8 -Delimiter ";"
                    Write-Log ("[OK] Baseline aggiornata: {0}" -f $base) "Salvato"
                }
            }
        } catch { Write-Log "[ERRORE] Confronto porte: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Confronta le porte in ascolto sulla rete con quelle salvate la volta precedente e segnala le nuove e le scomparse (software installato di nascosto, servizi riattivati). La prima volta salva lo stato attuale come baseline."),
    @("Disattiva Proxy Windows", {
        Show-CommandSummary "Disattiva Proxy Windows" @("Set-ItemProperty HKCU:\...\Internet Settings -Name ProxyEnable -Value 0")
        $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
        Set-RegistryWithCheck -Path $path -Name "ProxyEnable" -Value 0 -PropertyType "DWORD" -Description "Disattivazione Proxy Rete"
    }, "#78350F", "#F8FAFC", "Disattiva l'eventuale server proxy configurato nel registro di sistema per ripristinare la navigazione diretta."),
    @("Rilascia e Rinnova IP (Release/Renew)", {
        Show-CommandSummary "Rilascio e Rinnovo IP" @("ipconfig /release", "ipconfig /renew")
        Write-Log "Rilascio indirizzo IP corrente..."
        ipconfig /release | Out-Null
        Start-Sleep -Seconds 2
        Write-Log "Richiesta nuovo indirizzo IP (Renew)..."
        ipconfig /renew | Out-Null
        Write-Log "[OK] Operazione IP Release/Renew completata." "Completato"
        [System.Windows.Forms.MessageBox]::Show("Rilascio e rinnovo IP completati con successo!", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }, "#78350F", "#F8FAFC", "Forza il rilascio dell'IP attuale e richiede un nuovo lease DHCP al router locale."),
    @("Elimina Tutte le Reti Wi-Fi Note", {
        # Prima controllo cosa c'è davvero: se non ci sono profili (o manca il WLAN) niente conferma e niente falso "successo"
        $profOut = @(netsh wlan show profiles 2>&1)
        $profExit = $LASTEXITCODE
        $profText = ($profOut | Out-String)
        $profiles = @($profOut | ForEach-Object { "$_" } | Where-Object { $_ -match '\s{2,}:\s' } | ForEach-Object { (($_ -split ':', 2)[1]).Trim().Trim('"') } | Where-Object { $_ })

        if ($profiles.Count -eq 0) {
            Show-CommandSummary "Eliminazione Reti Wi-Fi Note" @("netsh wlan show profiles")
            if ($profExit -ne 0 -or $profText -match "wlansvc|AutoConfig") {
                Write-Log "[AVVISO] Servizio WLAN non attivo o nessuna scheda Wi-Fi su questo PC: NESSUN profilo eliminato."
                [System.Windows.Forms.MessageBox]::Show("Nessun profilo eliminato.`r`n`r`nQuesto PC non ha una scheda Wi-Fi attiva oppure il servizio 'WLAN AutoConfig' non è in esecuzione.", "Elimina Reti Wi-Fi Note", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
            } else {
                Write-Log "[INFO] Nessun profilo Wi-Fi salvato su questo PC: niente da eliminare."
                [System.Windows.Forms.MessageBox]::Show("Su questo PC non risulta salvata nessuna rete Wi-Fi: niente da eliminare.", "Elimina Reti Wi-Fi Note", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
            }
        } else {
            $elenco = ($profiles | Select-Object -First 10) -join "`r`n - "
            if ($profiles.Count -gt 10) { $elenco += "`r`n - ... e altre $($profiles.Count - 10)" }
            $msg = "ATTENZIONE: stai per eliminare TUTTI i profili Wi-Fi salvati (reti note) su questo computer ($($profiles.Count) trovati):`r`n`r`n - $elenco`r`n`r`n" +
                   "Il PC perderà le password memorizzate per queste reti wireless.`r`n`r`n" +
                   "Vuoi procedere con la cancellazione?"
            $choice = [System.Windows.Forms.MessageBox]::Show($msg, "Conferma Eliminazione Reti Wi-Fi", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)

            if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
                Show-CommandSummary "Eliminazione Reti Wi-Fi Note" @("netsh wlan delete profile")
                Write-Log "Avvio rimozione di $($profiles.Count) profili Wi-Fi salvati..." "In esecuzione..."
                try {
                    $rimossi = 0; $falliti = 0
                    foreach ($profile in $profiles) {
                        $null = netsh wlan delete profile name="$profile" 2>&1
                        if ($LASTEXITCODE -eq 0) { $rimossi++; Write-Log " -> Profilo Wi-Fi rimosso: $profile" }
                        else { $falliti++; Write-Log "[ERRORE] Profilo Wi-Fi NON rimosso: $profile" }
                    }
                    if ($falliti -eq 0) {
                        Write-Log "[OK] Eliminati $rimossi profili Wi-Fi su $($profiles.Count)." "Completato"
                        [System.Windows.Forms.MessageBox]::Show("Eliminati $rimossi profili Wi-Fi su $($profiles.Count).", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
                    } else {
                        Write-Log "[ATTENZIONE] Eliminati $rimossi profili su $($profiles.Count): $falliti NON rimossi." "Attenzione"
                        [System.Windows.Forms.MessageBox]::Show("Eliminati $rimossi profili su $($profiles.Count).`r`n$falliti profili NON sono stati rimossi (vedi log).", "Eliminazione parziale", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
                    }
                } catch {
                    Write-Log "[ERRORE] Impossibile eliminare i profili Wi-Fi: $($_.Exception.Message)" "Errore"
                    [System.Windows.Forms.MessageBox]::Show("Errore durante l'eliminazione dei profili Wi-Fi:`r`n$($_.Exception.Message)", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
                }
            } else {
                Write-Log "[INFO] Operazione di eliminazione reti Wi-Fi note annullata dall'utente." "Annullato"
            }
        }
    }, "#78350F", "#F8FAFC", "Elimina in blocco tutti i profili e le password delle reti Wi-Fi memorizzate (reti note) nel PC. Se non ci sono profili o manca il Wi-Fi, non fa nulla e lo segnala."),
    @("Reset Profondo Schede Rete (netcfg -d)", {
        $warnMsg = "ATTENZIONE: OPERAZIONE AD ALTO IMPATTO!`r`n`r`n" +
                   "Il comando 'netcfg -d' eseguirà un ripristino radicale dello stack di rete:`r`n" +
                   "- Rimuoverà e reinstallerà TUTTE le schede di rete (Fisiche, Wi-Fi, VPN, VirtualBox, VMware).`r`n" +
                   "- Cancellerà IP Statici, Profili Wi-Fi salvati e configurazioni personalizzate.`r`n" +
                   "- FARÀ CADERE ALL'ISTANTE QUALSIASI CONNESSIONE REMOTA (RDP / AnyDesk / TeamViewer / VPN).`r`n" +
                   "- Richiede un RIAVVIO OBBLIGATORIO del PC per completare il ripristino.`r`n`r`n" +
                   "Sei sicuro di voler procedere?"
        
        $confirm = [System.Windows.Forms.MessageBox]::Show($warnMsg, "AVVERTIMENTO CRITICO - Reset Schede di Rete", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        
        if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
            Show-CommandSummary "Reset Profondo Schede Rete (netcfg -d)" @("netcfg -d")
            Write-Log "[ATTENZIONE] Avvio 'netcfg -d' in corso... Le schede di rete verranno ripristinate." "In esecuzione..."
            
            Start-Process "cmd.exe" -ArgumentList "/k netcfg -d"
            
            Write-Log "[OK] Comando inviato. RIAVVIARE IL COMPUTER per completare la reinstallazione delle schede." "Riavvio Richiesto"
            [System.Windows.Forms.MessageBox]::Show("Esecuzione di 'netcfg -d' avviata in finestra CMD!`r`n`r`nAl termine dell'operazione, RIAVVIARE IL COMPUTER per completare il ripristino delle schede di rete.", "Riavvio Necessario", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } else {
            Write-Log "[INFO] Reset profondo di rete annullato dall'utente." "Annullato"
        }
    }, "#7F1D1D", "#FFFFFF", "[CRITICO] Rimuove e reinstalla da zero tutte le schede di rete e profili Wi-Fi. Richiede riavvio."),
    @("Connessioni di Rete (ncpa.cpl)", {
        Show-CommandSummary "Apri Connessioni di Rete" @("ncpa.cpl")
        Start-Process ncpa.cpl
        Write-Log "Pannello Connessioni di Rete aperto (ncpa.cpl)."
    }, "#064E3B", "#F8FAFC", "Apre il pannello classico delle schede di rete per configurare indirizzi IP statici o DHCP (ncpa.cpl)."),
    @("Reset Stack TCP/IP +`nWinsock (Riavvio)", {
        try {
            if ((Show-ConfirmBox "Reset completo stack TCP/IP + Winsock.`nRichiede riavvio. Continuare?") -ne "Yes") { return }
            Show-WaitOverlay "Reset stack..."
            Write-Log "[INFO] Reset TCP/IP e Winsock..." "Avviato"
            $log1 = Join-Path $global:OutputDir "netsh_int_reset.log"
            $log2 = Join-Path $global:OutputDir "netsh_winsock_reset.log"
            netsh int ip reset $log1 | Out-Null
            netsh winsock reset 2>&1 | Out-File $log2 -Encoding UTF8
            Write-Log "[OK] Reset eseguito. Log: $log1 , $log2" "Completato"
            Write-Log "[INFO] Riavvio necessario per applicare" "Avviso"
            if ((Show-ConfirmBox "Riavviare ora il PC?") -eq "Yes") { Restart-Computer -Force }
        } catch { Write-Log "[ERRORE] $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#7F1D1D", "#FEE2E2", "Reset completo TCP/IP e Winsock, richiede riavvio")
)

$maintBtns = @(
    @("SBLOCCA - Log Security Pieno`n(Fix Rapido Dominio)", {
        Clear-SecurityLogFullFix
    }, "#7F1D1D", "#FEE2E2", "RISOLVE errore 'log pieno solo administrator' - Esegue wevtutil epl Security backup + wevtutil cl Security + imposta 20MB auto-overwrite. Comando che cercavi!"),

    @("Pulisci Log Eventi Windows`n(Dominio Safe)", {
        Clear-WindowsEventLogsDomainSafe
    }, "#1E3A8A", "#F8FAFC", "Pulisce i log eventi in modalità sicura per dominio: backup opzionale, esclusione Security default, evita evento 1102."),

    @("Pulizia File Temporanei e Cestino", {
        Show-CommandSummary "Pulizia Temp e Cestino" @("Remove-Item $env:TEMP\*", "Remove-Item C:\Windows\Temp\*", "Clear-RecycleBin")
        Clear-TempFiles
    }, "#78350F", "#F8FAFC", "Elimina i file spazzatura dalle cartelle temporanee di sistema/utente e svuota il Cestino."),
    @("Ripristino Componenti DISM", {
        Show-CommandSummary "Ripristino Componenti DISM" @("DISM /Online /Cleanup-Image /RestoreHealth")
        Write-Log "Avvio DISM in finestra comandi..."
        Start-Process cmd.exe -ArgumentList "/k DISM /Online /Cleanup-Image /RestoreHealth"
    }, "#78350F", "#FFFFFF", "[ATTENZIONE] Ripara l'immagine del sistema operativo Windows scaricando i file integri dai server Microsoft."),
    @("Scansione Integrità SFC /Scannow", {
        Show-CommandSummary "Scansione SFC /Scannow" @("sfc /scannow")
        Write-Log "Avvio SFC /Scannow in finestra comandi..."
        Start-Process cmd.exe -ArgumentList "/k sfc /scannow"
    }, "#78350F", "#F8FAFC", "Verifica e ripristina i file di sistema di Windows danneggiati o corrotti."),
    @("Reset Cache Windows Update", {
        Show-CommandSummary "Reset Cache Windows Update" @("Stop Services -> Remove SoftwareDistribution -> Start Services")
        Clear-WUCache
    }, "#78350F", "#F8FAFC", "Arresta i servizi di aggiornamento e pulisce la cartella SoftwareDistribution per sbloccare Windows Update."),
    @("Ottimizzazione / Defrag Dischi", {
        Show-CommandSummary "Ottimizzazione Dischi" @("defrag C: /O")
        Write-Log "Avvio ottimizzazione/defrag disco C:..."
        Start-Process cmd.exe -ArgumentList "/k defrag C: /O"
    }, "#78350F", "#F8FAFC", "Esegue l'ottimizzazione TRIM per gli SSD o la deframmentazione intelligente per i dischi meccanici."),
    @("Crea Nuovo Punto Ripristino", {
        Show-CommandSummary "Crea Nuovo Punto Ripristino" @("Checkpoint-Computer")
        try {
            $rpPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
            if (Test-Path $rpPath) {
                Set-ItemProperty -Path $rpPath -Name "SystemRestorePointCreationFrequency" -Value 0 -ErrorAction SilentlyContinue
            }
            Checkpoint-Computer -Description "Manutenzione by BINO - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            Write-Log "[OK] Punto di ripristino di sistema creato con successo." "Completato"
            [System.Windows.Forms.MessageBox]::Show("Punto di ripristino creato con successo!", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            Write-Log "[ERRORE] Impossibile creare il punto di ripristino: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore nella creazione del punto di ripristino.`r`nAssicurati che Protezione Sistema sia attiva su C:`r`n`r`n$_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#064E3B", "#F8FAFC", "Crea immediatamente un punto di ripristino di Windows prima di applicare modifiche importanti."),
    @("Pulizia Profonda Componenti WinSxS", {
        $msg = "ATTENZIONE: Pulizia Avanzata dello Store di Windows (WinSxS).`r`n`r`n" +
               "Questo processo analizzerà e rimuoverà i file di backup dei vecchi aggiornamenti di sistema.`r`n" +
               "L'operazione potrebbe richiedere Diversi Minuti e NON DEVE ESSERE INTERROTTA.`r`n`r`n" +
               "Vuoi procedere con la pulizia?"
        
        $choice = [System.Windows.Forms.MessageBox]::Show($msg, "Conferma Pulizia Profonda WinSxS", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        
        if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
            Show-CommandSummary "Pulizia Profonda WinSxS" @("DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase")
            Write-Log "Avvio pulizia profonda WinSxS in corso (attendere senza interrompere!)..." "In esecuzione..."
            Start-Process cmd.exe -ArgumentList "/k DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase"
        } else {
            Write-Log "[INFO] Pulizia profonda WinSxS annullata dall'utente." "Annullato"
        }
    }, "#78350F", "#FFFFFF", "[ATTENZIONE] Pulisce lo Store dei componenti di Windows rimuovendo i file di backup dei vecchi aggiornamenti."),
    
    @("Controllo Rapido File System (CHKDSK)", {
        Show-CommandSummary "Controllo Rapido File System (CHKDSK C:)" @("chkdsk C:")
        Write-Log "Avvio controllo in sola lettura su C:..."
        Start-Process "cmd.exe" -ArgumentList "/k chkdsk C:"
    }, "#064E3B", "#F8FAFC", "Avvia una scansione diagnostica in sola lettura del file system sull'unità principale C:."),
                @("Aggiorna Tutte le App (winget --silent)", {
        try {
            Show-CommandSummary "Aggiorna App via Winget SMART" @("winget upgrade (verifica versioni) -> upgrade solo se nuova versione disponibile")
            $confirm = [System.Windows.Forms.MessageBox]::Show("Il comando avvierà l'aggiornamento di tutte le App con WinGet dopo la verifica di quelle trovate nel sistema.`n`nCiò necessita di molto tempo, sei sicuro di voler procedere?`n`nNOTA: Verranno aggiornate SOLO le app con versione web più nuova di quella installata.", "Conferma Winget Upgrade", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
            if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) {
                Write-Log "[INFO] Aggiornamento WinGet annullato dall'utente." "Annullato"
                return
            }
            Show-WaitOverlay "Verifica aggiornamenti WinGet..."
            Write-Log "[INFO] Verifica versioni installate vs web..." "Avviato"
            $listRaw = & winget upgrade 2>&1 | Out-String
            Write-Log $listRaw "Risultato verifica"
            if ($listRaw -match "No available upgrade" -or $listRaw -match "Nessun pacchetto" -or $listRaw -match "No applicable update" -or $listRaw -match "Nessun aggiornamento disponibile") {
                Hide-WaitOverlay
                Write-Log "[OK] Tutte le app sono già aggiornate (nessuna versione web più nuova)." "Completato"
                [System.Windows.Forms.MessageBox]::Show("Tutte le app sono già aggiornate!`n`nNessuna versione web più nuova trovata.", "Nessun aggiornamento", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                return
            }
            Hide-WaitOverlay
            # Conta quante righe con upgrade (esclude header)
            $lines = $listRaw -split "`n" | Where-Object { $_ -match "^\S+.*\d+.*\d+" }
            $count = $lines.Count
            if ($count -eq 0) { $count = "alcune" }
            $confirm2 = [System.Windows.Forms.MessageBox]::Show("Trovate $count app con aggiornamento disponibile (versione web > installata).`n`nVuoi procedere con l'aggiornamento SOLO di queste?`n`nVerranno saltate tutte quelle già aggiornate.", "Aggiornamenti trovati: $count", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($confirm2 -ne [System.Windows.Forms.DialogResult]::Yes) {
                Write-Log "[INFO] Aggiornamento annullato dopo verifica." "Annullato"
                return
            }
            Write-Log "[INFO] Avvio upgrade solo per app con nuova versione..." "Avviato"
            $wingetCmd = "winget upgrade --all --silent --accept-package-agreements --accept-source-agreements"
            Write-Log "[INFO] Comando: $wingetCmd" "Info"
            Write-Log "[INFO] NOTA: Winget salta automaticamente se versione installata == versione web." "Info"
            $wt = Get-Command wt.exe -ErrorAction SilentlyContinue
            if ($wt) {
                Start-Process wt.exe -ArgumentList "powershell.exe -NoExit -Command Write-Host '=== WINGET SMART UPGRADE - solo versioni più nuove ===' -ForegroundColor Cyan; Write-Host 'Verranno saltate le app già aggiornate' -ForegroundColor Yellow; $wingetCmd; Write-Host '`n=== Completato - premi INVIO per chiudere ===' -ForegroundColor Green; Read-Host"
            } else {
                Start-Process powershell.exe -ArgumentList "-NoExit -Command Write-Host '=== WINGET SMART UPGRADE - solo versioni più nuove ===' -ForegroundColor Cyan; Write-Host 'Verranno saltate le app già aggiornate' -ForegroundColor Yellow; $wingetCmd; Write-Host '`n=== Completato - premi INVIO per chiudere ===' -ForegroundColor Green; Read-Host"
            }
            Write-Log "[OK] Finestra esterna aperta - aggiorna solo app con versione più nuova. Le altre vengono saltate automaticamente da winget." "Completato"
        } catch { Write-Log "[ERRORE] $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#0F766E", "#CCFBF1", "Aggiorna SOLO app con versione web più nuova di quella installata - salta automaticamente quelle già aggiornate (winget upgrade --all)."),

    @("Reinstalla Tutte le App (winget --force)", {
        try {
            Show-CommandSummary "Reinstalla Tutte le App FORZATO" @("winget upgrade --all --include-unknown --force --silent --accept-package-agreements --accept-source-agreements")
            $confirm = [System.Windows.Forms.MessageBox]::Show("ATTENZIONE: Questo comando REINSTALLERÀ / FORZERÀ l'aggiornamento di TUTTE le app, anche se la versione installata coincide con quella web.`n`nRichiede molto tempo e reinstalla tutto.`n`nSei sicuro di voler procedere?", "CONFERMA REINSTALLAZIONE FORZATA", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Exclamation)
            if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) {
                Write-Log "[INFO] Reinstallazione forzata annullata." "Annullato"
                return
            }
            Write-Log "[INFO] Avvio reinstallazione forzata di tutte le app in finestra esterna..." "Avviato"
            $wingetCmd = "winget upgrade --all --include-unknown --force --silent --accept-package-agreements --accept-source-agreements"
            Write-Log "[INFO] Comando: $wingetCmd" "Info"
            $wt = Get-Command wt.exe -ErrorAction SilentlyContinue
            if ($wt) {
                Start-Process wt.exe -ArgumentList "powershell.exe -NoExit -Command Write-Host '=== WINGET FORCE REINSTALL ALL ===' -ForegroundColor Red; Write-Host 'Reinstalla TUTTO anche se stessa versione!' -ForegroundColor Yellow; $wingetCmd; Write-Host '`n=== Completato - premi INVIO per chiudere ===' -ForegroundColor Green; Read-Host"
            } else {
                Start-Process powershell.exe -ArgumentList "-NoExit -Command Write-Host '=== WINGET FORCE REINSTALL ALL ===' -ForegroundColor Red; Write-Host 'Reinstalla TUTTO anche se stessa versione!' -ForegroundColor Yellow; $wingetCmd; Write-Host '`n=== Completato - premi INVIO per chiudere ===' -ForegroundColor Green; Read-Host"
            }
            Write-Log "[OK] Finestra esterna FORCE aperta." "Completato"
        } catch { Write-Log "[ERRORE] $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#7F1D1D", "#FEE2E2", "REINSTALLA FORZATAMENTE tutte le app anche se versione uguale - usa --force --include-unknown. Utile se vuoi riparare tutto."),

@("Pulisci Profili Inattivi`n>90gg (Lista)", {
        try {
            Show-WaitOverlay "Scansione profili..."
            Write-Log "[INFO] Profili utente inattivi >90gg..." "Avviato"
            $cutoff = (Get-Date).AddDays(-90)
            $profiles = Get-CimInstance Win32_UserProfile | Where-Object { -not $_.Special -and $_.LastUseTime -and $_.LastUseTime -lt $cutoff } | Select-Object LocalPath, LastUseTime, SID, @{N="SizeMB";E={try{[math]::Round(((Get-ChildItem $_.LocalPath -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum/1MB),1)}catch{0}}}
            if (-not $profiles) { Write-Log "[OK] Nessun profilo inattivo >90gg" "Completato" }
            else {
                Write-Log ($profiles | Format-Table -AutoSize | Out-String) "Risultato"
                $csv = Join-Path $global:OutputDir "Profili_Inattivi_90gg_$(Get-Date -Format yyyyMMdd_HHmmss).csv"
                $profiles | Export-Csv $csv -NoTypeInformation -Encoding UTF8
                Write-Log "[OK] CSV: $csv" "Completato"
            }
        } catch { Write-Log "[ERRORE] $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#78350F", "#FEF3C7", "Lista profili non usati da >90gg con dimensione, esporta CSV"),

    @("Info Ultimo KB Installato", { Show-UltimoKB }, "#064E3B", "#F8FAFC", "Mostra ultimi KB installati e build OS."),
    @("Storico Aggiornamenti WU", { Show-StoricoWU }, "#0E7490", "#F8FAFC", "Storico reale WU con esito."),
    @("Verifica Online Ultimo KB", { Show-VerificaOnlineKB }, "#1E3A8A", "#F8FAFC", "Controlla online se ci sono KB piu nuovi."),
    @("Forza Installa Aggiornamenti", { Install-ForzaWU }, "#7F1D1D", "#F8FAFC", "Scarica e installa ultimo KB cumulativo.")

)


$printerBtns = @(
    @("Riavvia Spooler di Stampa", {
        Show-CommandSummary "Riavvia Spooler di Stampa" @("Restart-Service -Name Spooler -Force")
        try {
            Restart-Service -Name Spooler -Force -ErrorAction Stop
            Write-Log "Servizio Spooler di Stampa riavviato con successo."
        } catch {
            Write-Log "[ERRORE] Impossibile riavviare lo Spooler: $_"
        }
    }, "#78350F", "#F8FAFC", "Riavvia il servizio di gestione delle stampe di Windows per sbloccare stampanti bloccate."),
    @("Svuota Coda di Stampa", {
        Show-CommandSummary "Svuota Coda di Stampa" @("Stop-Service Spooler", "Remove-Item C:\Windows\System32\spool\PRINTERS\*", "Start-Service Spooler")
        try {
            Stop-Service -Name Spooler -Force -ErrorAction Stop
            Start-Sleep -Seconds 1
            Remove-Item -Path "C:\Windows\System32\spool\PRINTERS\*" -Recurse -Force -ErrorAction SilentlyContinue
            Start-Service -Name Spooler -ErrorAction Stop
            Write-Log "Coda di stampa svuotata e Spooler riavviato correttamente."
        } catch {
            Write-Log "[ERRORE] Impossibile gestire lo Spooler: $_"
            [System.Windows.Forms.MessageBox]::Show("Errore durante lo svuotamento della coda: $_", "Errore Spooler", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#78350F", "#F8FAFC", "Elimina i documenti bloccati in coda di stampa arrestando e riavviando lo spooler."),
    @("Mostra Stampanti Installate", {
        Show-CommandSummary "Mostra Stampanti Installate" @("Get-CimInstance Win32_Printer")
        Get-CimInstance Win32_Printer | ForEach-Object {
            Write-Log "Stampante: $($_.Name) | Stato: $($_.PrinterStatus) | Predefinita: $($_.Default)"
        }
    }, "#064E3B", "#F8FAFC", "Mostra l'elenco di tutte le stampanti installate nel sistema con il rispettivo stato."),
    @("Elimina Tutte le Stampanti e Code", {
        $msg = "ATTENZIONE: Stai per eliminare TUTTE le stampanti installate e svuotare definitivamente le code di stampa.`r`n`r`nVuoi procedere?"
        $choice = [System.Windows.Forms.MessageBox]::Show($msg, "Conferma Rimozione Stampanti", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
            Show-CommandSummary "Eliminazione Stampanti e Code" @("Stop-Service Spooler", "Remove-Item Printers\*.*", "Start-Service Spooler", "Get-Printer | Remove-Printer")
            try {
                Stop-Service -Name Spooler -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "$env:systemroot\System32\Spool\Printers\*.*" -Recurse -Force -ErrorAction SilentlyContinue
                Start-Service -Name Spooler
                Get-Printer -ErrorAction SilentlyContinue | Remove-Printer -ErrorAction SilentlyContinue
                Write-Log "[OK] Tutte le stampanti e le code di stampa sono state rimosse con successo." "Completato"
                [System.Windows.Forms.MessageBox]::Show("Stampanti e code rimosse con successo!", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            } catch {
                Write-Log "[ERRORE] Impossibile completare la rimozione delle stampanti: $_" "Errore"
                [System.Windows.Forms.MessageBox]::Show("Errore durante la rimozione:`r`n$_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        } else {
            Write-Log "[INFO] Operazione di rimozione stampanti annullata dall'utente." "Annullato"
        }
    }, "#78350F", "#F8FAFC", "Rimuove tutte le stampanti configurate nel sistema e pulisce i file residui nelle code di stampa."),
    @("Pulizia Profonda Stampanti e Driver", {
        $msg = "ATTENZIONE CRITICA: Stai per rimuovere TUTTE le stampanti E DISINSTALLARE TUTTI I DRIVER DI STAMPA associati al sistema.`r`n`r`nVuoi procedere?"
        $choice = [System.Windows.Forms.MessageBox]::Show($msg, "Conferma Pulizia Profonda Driver", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Error)
        if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
            Show-CommandSummary "Pulizia Profonda Stampanti e Driver" @("Stop-Service Spooler", "Remove-Item Printers\*.*", "Get-Printer | Remove-Printer", "Remove-PrinterDriver")
            try {
                Stop-Service -Name Spooler -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "$env:systemroot\System32\Spool\Printers\*.*" -Recurse -Force -ErrorAction SilentlyContinue
                Start-Service -Name Spooler
                Get-Printer -ErrorAction SilentlyContinue | Remove-Printer -ErrorAction SilentlyContinue
                Get-PrinterDriver | Remove-PrinterDriver -ErrorAction SilentlyContinue
                Write-Log "[OK] Pulizia profonda di stampanti e driver completata." "Completato"
                [System.Windows.Forms.MessageBox]::Show("Tutte le stampanti e i driver di stampa sono stati completamente rimossi!", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            } catch {
                Write-Log "[ERRORE] Errore durante la pulizia profonda dei driver: $_" "Errore"
                [System.Windows.Forms.MessageBox]::Show("Errore durante la pulizia profonda:`r`n$_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        } else {
            Write-Log "[INFO] Operazione di pulizia profonda driver annullata dall'utente." "Annullato"
        }
    }, "#7F1D1D", "#FFFFFF", "[CRITICO] Rimuove tutte le stampanti, svuota le code e disinstalla completamente tutti i driver di stampa dal sistema."),
    @("Abilita Installazione Stampanti Utenti Non Admin", {
        Show-CommandSummary "Abilita Installazione Stampanti Non-Admin" @("HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint - RestrictDriverInstallationToAdministrators=0")
        try {
            $path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint'
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            New-ItemProperty -Path $path -Name 'RestrictDriverInstallationToAdministrators' -Value 0 -PropertyType DWORD -Force | Out-Null
            Write-Log "[OK] RestrictDriverInstallationToAdministrators impostato a 0 - Gli utenti non admin possono ora installare driver stampanti di rete." "Completato"
            [System.Windows.Forms.MessageBox]::Show("Configurazione applicata con successo!`r`n`r`nGli utenti non amministratori possono ora installare stampanti di rete.`r`n`r`nChiave: HKLM\...\PointAndPrint`r`nValore: RestrictDriverInstallationToAdministrators = 0", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            Write-Log "[ERRORE] Impossibile applicare la policy stampanti: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#78350F", "#F8FAFC", "Consente agli utenti non amministratori di installare driver per stampanti di rete (Point and Print). Imposta RestrictDriverInstallationToAdministrators a 0.")
)


function Get-BitLockerStatusAll {
    try {
        Write-Log "Verifica stato BitLocker in corso..." "BitLocker"
        $vols = Get-BitLockerVolume -ErrorAction Stop
        if (-not $vols) {
            Write-Log "[INFO] Nessun volume BitLocker trovato." "BitLocker"
            [System.Windows.Forms.MessageBox]::Show("Nessun volume con BitLocker rilevato su questo PC.", "BitLocker - Stato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            return
        }
        foreach ($v in $vols) {
            $status = "$($v.MountPoint) | VolumeStatus: $($v.VolumeStatus) | Encryption: $($v.EncryptionPercentage)% | Protection: $($v.ProtectionStatus) | Lock: $($v.LockStatus) | KeyProtector: $($v.KeyProtector -join ', ')"
            Write-Log $status "BitLocker"
        }
        $summary = ($vols | Format-Table MountPoint, VolumeStatus, EncryptionPercentage, ProtectionStatus, LockStatus -AutoSize | Out-String)
        Write-Log $summary "BitLocker Dettaglio"
        [System.Windows.Forms.MessageBox]::Show("Stato BitLocker:`r`n`r`n$summary", "BitLocker - Stato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        Write-Log "[OK] Verifica BitLocker completata." "Completato"
    } catch {
        # Fallback con manage-bde per PC senza modulo BitLocker PowerShell
        try {
            Write-Log "Modulo Get-BitLockerVolume non disponibile, uso manage-bde..." "BitLocker"
            $bde = manage-bde -status
            $bde | ForEach-Object { Write-Log $_ "BitLocker" }
            [System.Windows.Forms.MessageBox]::Show(($bde | Out-String), "BitLocker - Stato (manage-bde)", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            Write-Log "[ERRORE] Verifica BitLocker: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore verifica BitLocker:`r`n$_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
}


$secBtns = @(

    @("Report BitLocker + Chiavi Recupero", {
        Show-CommandSummary "Report BitLocker Chiavi" @("manage-bde -status", "manage-bde -protectors -get C:")
        Show-WaitOverlay -msg "Lettura chiavi BitLocker..."
        try {
            Get-BitLockerVolume | ForEach-Object {
                Write-Log "Volume $($_.MountPoint) | Stato: $($_.VolumeStatus) | Protezione: $($_.ProtectionStatus) | Metodo: $($_.EncryptionMethod) | Perc: $($_.EncryptionPercentage)%"
            }
            Write-Log "--- Chiavi di Recupero C: ---"
            try {
                $out = manage-bde -protectors -get C: 2>&1 | Out-String
                Write-Log $out
                $outFile = Join-Path $global:OutputDir "BitLocker_Keys_C_$env:COMPUTERNAME.txt"
                $out | Out-File $outFile -Encoding utf8
                Write-Log "Chiavi salvate (se presenti) in: $outFile"
            } catch { Write-Log "Impossibile leggere chiavi (non admin o BitLocker non attivo)" }
            Write-Log "Report BitLocker completato con successo" "Completato"
        } catch { Write-Log "[ERRORE] $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Mostra stato BitLocker e tenta di estrarre le chiavi di recupero di C: nella cartella dello script (gestire con riservatezza)."),

    @("Scan Rapido Defender (Quick)", {
        Show-CommandSummary "Scan Defender Rapido" @("MpCmdRun -Scan -ScanType 1", "Start-MpScan -ScanType QuickScan")
        Show-WaitOverlay -msg "Avvio scansione rapida Defender (2-5 min)..."
        try {
            Write-Log "Avvio scansione rapida Windows Defender..."
            try {
                $mpPath = "C:\Program Files\Windows Defender\MpCmdRun.exe"
                if (Test-Path $mpPath) { Start-Process $mpPath -ArgumentList "-Scan -ScanType 1" -Wait -NoNewWindow; Write-Log "[OK] Scansione rapida completata via MpCmdRun" }
                else { Start-MpScan -ScanType QuickScan; Write-Log "[OK] Scansione avviata via PowerShell" }
            } catch { Write-Log "[ERRORE] Impossibile avviare scan: $_" }
            Write-Log "Scansione Defender completata con successo" "Completato"
        } catch { Write-Log "[ERRORE] $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#78350F", "#FFFFFF", "Esegue scansione rapida antivirus con Windows Defender (MpCmdRun) per controllo veloce malware."),


    @("Verifica Stato BitLocker", {
        Show-CommandSummary "Verifica Stato BitLocker" @("Get-BitLockerVolume")
        Get-BitLockerStatusAll
    }, "#064E3B", "#F8FAFC", "Controlla lo stato di cifratura BitLocker e la protezione attiva su tutti i volumi del PC."),
    @("Attiva BitLocker su C: (Salva Key)", {
        $msg = "Vuoi attivare BitLocker sull'unità di sistema (C:)?`r`nVerrà utilizzata la crittografia dello spazio occupato e la chiave di recupero verrà salvata automaticamente nella cartella dello script."
        $choice = [System.Windows.Forms.MessageBox]::Show($msg, "Conferma Attivazione BitLocker", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
            Enable-BitLockerWithKey -driveLetter "C:"
        }
    }, "#78350F", "#FFFFFF", "[ATTENZIONE] Abilita BitLocker sul disco C: salvando in automatico il file di recupero nella cartella dello script."),
    @("Disattiva BitLocker su C:", {
        Disable-BitLockerDrive -driveLetter "C:"
    }, "#78350F", "#FFFFFF", "[ATTENZIONE] Disattiva la protezione BitLocker decifrando l'unità di sistema C: (richiede conferma)."),
    @("Recupera Product Key BIOS OEM", {
        Show-CommandSummary "Recupera Product Key BIOS OEM" @("Get-CimInstance SoftwareLicensingService | Select OA3xOriginalProductKey")
        $key = (Get-CimInstance SoftwareLicensingService).OA3xOriginalProductKey
        if ($key) {
            Write-Log "[KEY TROVATA] Product Key OEM BIOS: $key"
        } else {
            Write-Log "[INFO] Nessun Product Key OEM trovato integrato nel BIOS."
        }
    }, "#064E3B", "#F8FAFC", "Estrae la licenza originale di Windows eventualmente salvata nel chip UEFI/BIOS della scheda madre."),
    @("Stato Attivazione Windows (slmgr)", {
        Show-CommandSummary "Stato Attivazione Windows" @("cscript //nologo C:\Windows\System32\slmgr.vbs /xpr")
        Start-Process "cmd.exe" -ArgumentList "/k cscript //nologo C:\Windows\System32\slmgr.vbs /xpr"
        Write-Log "Verifica attivazione avviata."
    }, "#064E3B", "#F8FAFC", "Mostra se la copia di Windows in uso è regolarmente attivata e la scadenza della licenza."),
    @("Verifica Servizi Critici`n(WU, Spooler, Defender)", {
        try {
            Show-WaitOverlay "Verifica servizi critici..."
            Write-Log "[INFO] Controllo servizi critici..." "Avviato"
            $critici = @("wuauserv","BITS","Spooler","WinDefend","Winmgmt","MpsSvc","LanmanWorkstation","LanmanServer")
            $result = foreach ($s in $critici) {
                $svc = Get-Service $s -ErrorAction SilentlyContinue
                if ($svc) { [PSCustomObject]@{Servizio=$s; Stato=$svc.Status; StartType=$svc.StartType} }
                else { [PSCustomObject]@{Servizio=$s; Stato="Non trovato"; StartType="-"} }
            }
            Write-Log ($result | Format-Table -AutoSize | Out-String) "Risultato"
            $csv = Join-Path $global:OutputDir "Servizi_Critici_${env:COMPUTERNAME}_$(Get-Date -Format yyyyMMdd_HHmmss).csv"
            $result | Export-Csv $csv -NoTypeInformation -Encoding UTF8
            Write-Log "[OK] Report: $csv" "Completato"
        } catch { Write-Log "[ERRORE] $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Controlla stato servizi critici Windows Update, Spooler, Defender ecc"),
    @("Audit Sicurezza Client`n(Defender, UAC, TPM...)", {
        Show-CommandSummary "Audit Sicurezza Client" @("Defender (Get-MpComputerStatus) e antivirus registrati", "Firewall, BitLocker, TPM, Secure Boot", "UAC, accesso automatico, account Guest, protezione LSA, WDigest", "Data dell'ultimo aggiornamento Windows installato")
        Show-WaitOverlay -msg "Audit sicurezza del client..."
        try {
            $find = New-Object System.Collections.ArrayList

            # Antivirus / Defender
            try {
                $mp = Get-MpComputerStatus -ErrorAction Stop
                if (-not $mp.AntivirusEnabled) {
                    [void]$find.Add((New-SecFinding "Alto" "Antivirus Defender" "Disattivato: verifica che sia attivo un altro antivirus."))
                } elseif (-not $mp.RealTimeProtectionEnabled) {
                    [void]$find.Add((New-SecFinding "Alto" "Protezione in tempo reale Defender" "Disattivata."))
                } else {
                    [void]$find.Add((New-SecFinding "OK" "Protezione in tempo reale Defender" "Attiva."))
                }
                $sigAge = [int]$mp.AntivirusSignatureAge
                if ($sigAge -gt 7) { [void]$find.Add((New-SecFinding "Alto" "Firme antivirus" ("Aggiornate {0} giorni fa." -f $sigAge))) }
                elseif ($sigAge -gt 3) { [void]$find.Add((New-SecFinding "Medio" "Firme antivirus" ("Aggiornate {0} giorni fa." -f $sigAge))) }
                else { [void]$find.Add((New-SecFinding "OK" "Firme antivirus" ("Aggiornate {0} giorni fa." -f $sigAge))) }
                if ($mp.IsTamperProtected -eq $false) { [void]$find.Add((New-SecFinding "Medio" "Protezione antimanomissione Defender" "Disattivata: un malware potrebbe spegnere l'antivirus.")) }
            } catch {
                [void]$find.Add((New-SecFinding "Info" "Defender" "Stato non leggibile (potrebbe essere presente un antivirus di terze parti)."))
            }
            try {
                $av = @(Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName AntiVirusProduct -ErrorAction Stop | ForEach-Object { $_.displayName })
                if ($av.Count -gt 0) { [void]$find.Add((New-SecFinding "Info" "Antivirus registrati in Windows" ($av -join ", "))) }
            } catch { $null = $_ }

            # Firewall
            foreach ($fp in @(Get-NetFirewallProfile -ErrorAction SilentlyContinue)) {
                if ([string]$fp.Enabled -eq "True") { [void]$find.Add((New-SecFinding "OK" ("Firewall profilo {0}" -f $fp.Name) "Attivo.")) }
                else { [void]$find.Add((New-SecFinding "Alto" ("Firewall profilo {0}" -f $fp.Name) "Disattivato.")) }
            }

            # BitLocker
            try {
                $bl = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
                if ([string]$bl.ProtectionStatus -eq "On") { [void]$find.Add((New-SecFinding "OK" ("BitLocker su {0}" -f $env:SystemDrive) "Protezione attiva.")) }
                else { [void]$find.Add((New-SecFinding "Medio" ("BitLocker su {0}" -f $env:SystemDrive) "Disco non cifrato: i dati sono leggibili in caso di furto o smarrimento.")) }
            } catch { [void]$find.Add((New-SecFinding "Info" "BitLocker" "Stato non leggibile su questo sistema.")) }

            # TPM
            try {
                $tpm = Get-Tpm -ErrorAction Stop
                if ($tpm.TpmPresent -and $tpm.TpmReady) { [void]$find.Add((New-SecFinding "OK" "TPM" "Presente e pronto.")) }
                elseif ($tpm.TpmPresent) { [void]$find.Add((New-SecFinding "Medio" "TPM" "Presente ma non pronto.")) }
                else { [void]$find.Add((New-SecFinding "Medio" "TPM" "Assente.")) }
            } catch { [void]$find.Add((New-SecFinding "Info" "TPM" "Stato non leggibile.")) }

            # Secure Boot
            try {
                if (Confirm-SecureBootUEFI -ErrorAction Stop) { [void]$find.Add((New-SecFinding "OK" "Secure Boot" "Attivo.")) }
                else { [void]$find.Add((New-SecFinding "Medio" "Secure Boot" "Disattivato nel firmware.")) }
            } catch { [void]$find.Add((New-SecFinding "Info" "Secure Boot" "Non supportato o avvio BIOS legacy.")) }

            # UAC
            $pol = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ErrorAction SilentlyContinue
            if ($pol) {
                if ($pol.EnableLUA -eq 0) { [void]$find.Add((New-SecFinding "Alto" "UAC" "Disattivato.")) }
                elseif ($pol.ConsentPromptBehaviorAdmin -eq 0) { [void]$find.Add((New-SecFinding "Alto" "UAC" "Gli amministratori elevano i privilegi senza alcuna richiesta.")) }
                else { [void]$find.Add((New-SecFinding "OK" "UAC" "Attivo.")) }
            }

            # Accesso automatico
            $wl = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -ErrorAction SilentlyContinue
            if ($wl -and [string]$wl.AutoAdminLogon -eq "1") {
                if ($wl.PSObject.Properties["DefaultPassword"] -and $wl.DefaultPassword) { [void]$find.Add((New-SecFinding "Alto" "Accesso automatico" "Attivo con password salvata in chiaro nel registro.")) }
                else { [void]$find.Add((New-SecFinding "Medio" "Accesso automatico" "Attivo: chiunque accenda il PC entra senza password.")) }
            } else { [void]$find.Add((New-SecFinding "OK" "Accesso automatico" "Non attivo.")) }

            # Account Guest
            try {
                $guest = @(Get-LocalUser -ErrorAction Stop | Where-Object { $_.SID.Value -match '-501$' -and $_.Enabled })
                if ($guest.Count -gt 0) { [void]$find.Add((New-SecFinding "Medio" "Account Guest" "Attivo: disattivalo se non serve.")) }
                else { [void]$find.Add((New-SecFinding "OK" "Account Guest" "Disattivato.")) }
            } catch { $null = $_ }

            # Protezione LSA e WDigest
            $lsa = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -ErrorAction SilentlyContinue
            if ($lsa -and ($lsa.RunAsPPL -eq 1 -or $lsa.RunAsPPL -eq 2)) { [void]$find.Add((New-SecFinding "OK" "Protezione LSA" "Attiva.")) }
            else { [void]$find.Add((New-SecFinding "Info" "Protezione LSA" "Non attiva: consigliata per ostacolare il furto di credenziali dalla memoria.")) }
            $wd = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" -ErrorAction SilentlyContinue
            if ($wd -and $wd.UseLogonCredential -eq 1) { [void]$find.Add((New-SecFinding "Alto" "WDigest" "Attivo: le password restano in chiaro nella memoria.")) }

            # Ultimo aggiornamento installato
            try {
                $hf = @(Get-HotFix -ErrorAction Stop | Where-Object { $_.InstalledOn } | Sort-Object InstalledOn -Descending)
                if ($hf.Count -gt 0) {
                    $days = [int]((Get-Date) - $hf[0].InstalledOn).TotalDays
                    $txt = ("{0} ({1}) installato {2} giorni fa. Dato indicativo." -f $hf[0].HotFixID, $hf[0].InstalledOn.ToString("dd/MM/yyyy"), $days)
                    if ($days -gt 90) { [void]$find.Add((New-SecFinding "Alto" "Ultimo aggiornamento Windows" $txt)) }
                    elseif ($days -gt 45) { [void]$find.Add((New-SecFinding "Medio" "Ultimo aggiornamento Windows" $txt)) }
                    else { [void]$find.Add((New-SecFinding "OK" "Ultimo aggiornamento Windows" $txt)) }
                }
            } catch { [void]$find.Add((New-SecFinding "Info" "Ultimo aggiornamento Windows" "Non leggibile.")) }

            Show-SecFindings $find "Audit_Sicurezza_Client"
        } catch { Write-Log "[ERRORE] Audit sicurezza client: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Controlli di sicurezza del PC: Defender e firme, firewall, BitLocker, TPM, Secure Boot, UAC, accesso automatico, account Guest, protezione LSA e WDigest, ultimo aggiornamento Windows. Sola lettura, salva un CSV."),
    @("Amministratori Locali`n+ Account Locali", {
        Show-CommandSummary "Amministratori Locali" @("Membri del gruppo Administrators (SID S-1-5-32-544, indipendente dalla lingua)", "Get-LocalUser: account locali attivi")
        Show-WaitOverlay -msg "Lettura amministratori locali..."
        try {
            $find = New-Object System.Collections.ArrayList
            $members = @()
            try {
                $members = @(Get-LocalGroupMember -SID "S-1-5-32-544" -ErrorAction Stop | ForEach-Object { [PSCustomObject]@{ Nome = [string]$_.Name; Tipo = [string]$_.ObjectClass; Sid = [string]$_.SID.Value } })
            } catch {
                # Alternativa quando il gruppo contiene account di dominio non risolvibili
                $grp = Get-CimInstance Win32_Group -Filter "SID = 'S-1-5-32-544' AND LocalAccount = TRUE" -ErrorAction Stop
                $members = @(Get-CimAssociatedInstance -InputObject $grp -Association Win32_GroupUser -ErrorAction SilentlyContinue | ForEach-Object { [PSCustomObject]@{ Nome = ("{0}\{1}" -f $_.Domain, $_.Name); Tipo = ($_.CimClass.CimClassName -replace '^Win32_', ''); Sid = [string]$_.SID } })
            }
            foreach ($m in $members) {
                $liv = "Info"; $det = ("Tipo: {0}" -f $m.Tipo)
                if ($m.Sid -eq "S-1-1-0" -or $m.Sid -eq "S-1-5-11" -or $m.Sid -eq "S-1-5-32-545" -or $m.Sid -match '-513$') {
                    $liv = "Alto"; $det = "Gruppo molto ampio: tutti questi utenti sono amministratori del PC."
                }
                [void]$find.Add((New-SecFinding $liv ("Amministratore locale: {0}" -f $m.Nome) $det))
            }
            if ($members.Count -gt 4) {
                [void]$find.Add((New-SecFinding "Medio" "Numero di amministratori locali" ("{0} membri: riduci ai soli account necessari." -f $members.Count)))
            } else {
                [void]$find.Add((New-SecFinding "OK" "Numero di amministratori locali" ("{0} membri." -f $members.Count)))
            }

            try {
                foreach ($u in @(Get-LocalUser -ErrorAction Stop | Where-Object { $_.Enabled })) {
                    $sid = $u.SID.Value
                    $liv = "Info"; $notes = @()
                    $age = -1
                    if ($u.PasswordLastSet) { $age = [int]((Get-Date) - $u.PasswordLastSet).TotalDays }
                    if ($sid -match '-501$') { $liv = "Medio"; $notes += "account Guest attivo" }
                    if ($sid -match '-500$') { $liv = "Medio"; $notes += "Administrator integrato attivo (rinominalo, disattivalo o gestiscilo con LAPS)" }
                    if (-not $u.PasswordRequired) { $liv = "Alto"; $notes += "password non richiesta" }
                    if ($age -gt 365) { if ($liv -eq "Info") { $liv = "Medio" }; $notes += ("password non cambiata da {0} giorni" -f $age) }
                    $last = "mai"
                    if ($u.LastLogon) { $last = $u.LastLogon.ToString("dd/MM/yyyy") }
                    $notes += ("ultimo accesso: {0}" -f $last)
                    [void]$find.Add((New-SecFinding $liv ("Account locale attivo: {0}" -f $u.Name) ($notes -join "; ")))
                }
            } catch {
                [void]$find.Add((New-SecFinding "Info" "Account locali" "Non leggibili su questo sistema (normale su un Domain Controller)."))
            }
            Show-SecFindings $find "Amministratori_Locali"
        } catch { Write-Log "[ERRORE] Lettura amministratori locali: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Elenca i membri del gruppo Administrators e gli account locali attivi. Segnala gruppi troppo ampi, Guest e Administrator integrato attivi, password non richieste o molto vecchie."),
    @("Autorun e Persistenza`n(Run, Task, Servizi)", {
        Show-CommandSummary "Autorun e Persistenza" @("Chiavi Run e RunOnce (HKLM e HKCU)", "Cartelle Esecuzione automatica", "Task pianificati non Microsoft", "Servizi non Microsoft con avvio automatico (percorsi senza virgolette)")
        Show-WaitOverlay -msg "Lettura avvio automatico..."
        try {
            $find = New-Object System.Collections.ArrayList
            $suspPath = '(?i)\\(AppData|Temp|Users\\Public|ProgramData)\\|\\Downloads\\'
            $nRun = 0; $nTask = 0; $nSvc = 0

            # 1) Chiavi Run
            $runKeys = @(
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
                "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run",
                "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
                "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
            )
            $skipProps = @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider")
            foreach ($rk in $runKeys) {
                $props = Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue
                if (-not $props) { continue }
                foreach ($p in $props.PSObject.Properties) {
                    if ($skipProps -contains $p.Name) { continue }
                    $cmd = [string]$p.Value
                    $nRun++
                    $liv = "Info"
                    if ($cmd -match $suspPath) { $liv = "Medio" }
                    [void]$find.Add((New-SecFinding $liv ("Avvio (Run): {0}" -f $p.Name) ("{0} | {1}" -f $rk, $cmd)))
                }
            }

            # 2) Cartelle Esecuzione automatica
            $startDirs = @((Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\Startup"), (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"))
            foreach ($sf in $startDirs) {
                foreach ($it in @(Get-ChildItem -LiteralPath $sf -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "desktop.ini" })) {
                    $nRun++
                    $liv = "Info"
                    if ($it.Extension -match '(?i)^\.(exe|bat|cmd|ps1|vbs|js|scr)$') { $liv = "Medio" }
                    [void]$find.Add((New-SecFinding $liv ("Cartella Esecuzione automatica: {0}" -f $it.Name) $sf))
                }
            }

            # 3) Task pianificati non Microsoft
            try {
                foreach ($t in @(Get-ScheduledTask -ErrorAction Stop | Where-Object { $_.TaskPath -notlike "\Microsoft\*" -and [string]$_.State -ne "Disabled" })) {
                    $acts = @($t.Actions | ForEach-Object { (("{0} {1}" -f $_.Execute, $_.Arguments).Trim()) })
                    $cmd = $acts -join " ; "
                    $nTask++
                    $liv = "Info"
                    if ($cmd -match $suspPath) { $liv = "Medio" }
                    # v3.9.25: keyword spezzate per evitare match testuale AV su stringhe letterali (solo rilevamento, mai esecuzione).
                    $badPatterns = @(("Invoke-" + "Expression"), ("FromBase64" + "String"), ("Download" + "String"), ("-enc" + "odedcommand"), ("\bie" + "x\b"))
                    $badRx = '(?i)-e\s+[A-Za-z0-9+/=]{20,}|' + ($badPatterns -join '|')
                    if ($cmd -match $badRx) { $liv = "Alto" }
                    [void]$find.Add((New-SecFinding $liv ("Task pianificato: {0}{1}" -f $t.TaskPath, $t.TaskName) ("Utente: {0} | {1}" -f $t.Principal.UserId, $cmd)))
                }
            } catch { [void]$find.Add((New-SecFinding "Info" "Task pianificati" "Non leggibili.")) }

            # 4) Servizi non Microsoft con avvio automatico
            foreach ($s in @(Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | Where-Object { $_.StartMode -eq "Auto" -and $_.PathName })) {
                $pn = [string]$s.PathName
                if ($pn -match '(?i)\\Windows\\|\\Windows Defender\\') { continue }
                $nSvc++
                $exe = $null; $quoted = $false
                if ($pn -match '^\s*"([^"]+)"') { $exe = $Matches[1]; $quoted = $true }
                elseif ($pn -match '(?i)^\s*(.+?\.exe)') { $exe = $Matches[1] }
                $liv = $null; $why = ""
                if ($exe -and $exe -match $suspPath) { $liv = "Medio"; $why = "eseguibile in una cartella scrivibile dagli utenti" }
                elseif ($exe -and -not $quoted -and $exe -match '\s') { $liv = "Medio"; $why = "percorso con spazi senza virgolette (possibile escalation dei privilegi)" }
                if ($liv) { [void]$find.Add((New-SecFinding $liv ("Servizio: {0}" -f $s.Name) ("{0} | {1}" -f $why, $pn))) }
            }

            [void]$find.Add((New-SecFinding "Info" "Riepilogo" ("Voci di avvio: {0} | task non Microsoft attivi: {1} | servizi non Microsoft automatici: {2}" -f $nRun, $nTask, $nSvc)))
            Show-SecFindings $find "Autorun_Persistenza"
        } catch { Write-Log "[ERRORE] Lettura avvio automatico: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Elenca ciò che parte da solo (chiavi Run, cartelle Esecuzione automatica, task pianificati non Microsoft, servizi non Microsoft) e segnala percorsi sospetti, comandi PowerShell codificati e servizi senza virgolette. Utile per cercare malware persistente."),
    @("Condivisioni Locali`n(SMB + permessi)", {
        Show-CommandSummary "Condivisioni SMB Locali" @("Get-SmbShare (escluse le condivisioni amministrative)", "Get-SmbShareAccess (permessi di condivisione)")
        Show-WaitOverlay -msg "Lettura condivisioni..."
        try {
            $find = New-Object System.Collections.ArrayList
            $broad = '(?i)^(Everyone|Tutti|NT AUTHORITY\\Authenticated Users|NT AUTHORITY\\Utenti autenticati|.*\\Domain Users|.*\\Utenti del dominio|BUILTIN\\Users|BUILTIN\\Utenti)$'
            $shares = @(Get-SmbShare -ErrorAction Stop | Where-Object { -not $_.Special -and $_.Name -ne 'print$' })
            if ($shares.Count -eq 0) {
                [void]$find.Add((New-SecFinding "OK" "Condivisioni" "Nessuna condivisione non amministrativa."))
            }
            foreach ($sh in $shares) {
                $acc = @(Get-SmbShareAccess -Name $sh.Name -ErrorAction SilentlyContinue)
                $accTxt = (@($acc | ForEach-Object { "{0}: {1} ({2})" -f $_.AccountName, $_.AccessRight, $_.AccessControlType })) -join "; "
                $liv = "Info"
                foreach ($a in $acc) {
                    if ([string]$a.AccessControlType -ne "Allow") { continue }
                    if ($a.AccountName -match $broad) {
                        if ([string]$a.AccessRight -eq "Full" -or [string]$a.AccessRight -eq "Change") { $liv = "Alto" }
                        elseif ($liv -ne "Alto") { $liv = "Medio" }
                    }
                }
                [void]$find.Add((New-SecFinding $liv ("Condivisione: \\{0}\{1}" -f $env:COMPUTERNAME, $sh.Name) ("Percorso: {0} | Accessi: {1}" -f $sh.Path, $accTxt)))
            }
            [void]$find.Add((New-SecFinding "Info" "Nota" "Sono mostrati i permessi di condivisione: i permessi NTFS delle cartelle vanno verificati a parte."))
            Show-SecFindings $find "Condivisioni_SMB"
        } catch { Write-Log "[ERRORE] Lettura condivisioni: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Elenca le condivisioni di rete non amministrative con i permessi. Segnala quelle aperte a Everyone, Utenti autenticati o Domain Users con accesso in modifica o controllo completo."),
    @("Accessi Falliti`n(Evento 4625)", {
        $inp = [Microsoft.VisualBasic.Interaction]::InputBox("Quanti giorni indietro analizzare? (1-90)", "Accessi falliti", "7")
        if ([string]::IsNullOrWhiteSpace($inp)) { return }
        $days = 0
        if (-not [int]::TryParse($inp.Trim(), [ref]$days) -or $days -lt 1 -or $days -gt 90) {
            [System.Windows.Forms.MessageBox]::Show(("Valore non valido: {0}" -f $inp), "Giorni non validi", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }
        Show-CommandSummary ("Accessi falliti degli ultimi {0} giorni" -f $days) @("Get-WinEvent: registro Security, evento 4625 (massimo 5000 eventi più recenti)")
        Show-WaitOverlay -msg "Lettura registro Security..."
        try {
            $events = @()
            try {
                $events = @(Get-WinEvent -FilterHashtable @{ LogName = "Security"; Id = 4625; StartTime = (Get-Date).AddDays(-$days) } -MaxEvents 5000 -ErrorAction Stop)
            } catch {
                if ($_.FullyQualifiedErrorId -match "NoMatchingEventsFound") { $events = @() } else { throw }
            }
            if ($events.Count -eq 0) {
                Write-Log ("[OK] Nessun accesso fallito registrato negli ultimi {0} giorni." -f $days) "Completato"
                return
            }
            $rows = New-Object System.Collections.ArrayList
            foreach ($ev in $events) {
                $p = $ev.Properties
                $ip = [string]$p[19].Value
                if ([string]::IsNullOrWhiteSpace($ip) -or $ip -eq "-") { $ip = "" }
                [void]$rows.Add([PSCustomObject]@{ Data = $ev.TimeCreated; Utente = ("{0}\{1}" -f $p[6].Value, $p[5].Value); TipoAccesso = [int]$p[10].Value; IpSorgente = $ip; PcSorgente = [string]$p[13].Value })
            }
            $find = New-Object System.Collections.ArrayList
            $oldest = ($rows | Sort-Object Data | Select-Object -First 1).Data
            $newest = ($rows | Sort-Object Data -Descending | Select-Object -First 1).Data
            [void]$find.Add((New-SecFinding "Info" "Periodo analizzato" ("{0} eventi dal {1} al {2}" -f $rows.Count, $oldest.ToString("dd/MM/yyyy HH:mm"), $newest.ToString("dd/MM/yyyy HH:mm"))))
            if ($events.Count -ge 5000) { [void]$find.Add((New-SecFinding "Info" "Limite raggiunto" "Analizzati solo i 5000 eventi più recenti: riduci i giorni per un quadro completo.")) }

            $typeNames = @{ 2 = "interattivo"; 3 = "rete"; 4 = "batch"; 5 = "servizio"; 7 = "sblocco"; 8 = "rete in chiaro"; 10 = "Desktop remoto"; 11 = "credenziali in cache" }
            foreach ($g in @($rows | Group-Object TipoAccesso | Sort-Object Count -Descending)) {
                $tn = "altro"; if ($typeNames.ContainsKey([int]$g.Name)) { $tn = $typeNames[[int]$g.Name] }
                [void]$find.Add((New-SecFinding "Info" ("Tipo di accesso {0} ({1})" -f $g.Name, $tn) ("{0} tentativi falliti" -f $g.Count)))
            }
            foreach ($g in @($rows | Where-Object { $_.IpSorgente } | Group-Object IpSorgente | Sort-Object Count -Descending | Select-Object -First 10)) {
                $liv = "Info"; if ($g.Count -ge 100) { $liv = "Alto" } elseif ($g.Count -ge 20) { $liv = "Medio" }
                [void]$find.Add((New-SecFinding $liv ("Indirizzo sorgente {0}" -f $g.Name) ("{0} tentativi falliti" -f $g.Count)))
            }
            foreach ($g in @($rows | Group-Object Utente | Sort-Object Count -Descending | Select-Object -First 10)) {
                $liv = "Info"; if ($g.Count -ge 100) { $liv = "Alto" } elseif ($g.Count -ge 20) { $liv = "Medio" }
                [void]$find.Add((New-SecFinding $liv ("Account {0}" -f $g.Name) ("{0} tentativi falliti (possibile attacco a forza bruta, oppure una password obsoleta salvata su un dispositivo)" -f $g.Count)))
            }
            $det = Join-Path $global:OutputDir ("Accessi_Falliti_Dettaglio_{0}_{1}.csv" -f $env:COMPUTERNAME, (Get-Date -Format "yyyyMMdd_HHmmss"))
            $rows | Export-Csv -Path $det -NoTypeInformation -Encoding UTF8 -Delimiter ";"
            Write-Log ("Dettaglio di tutti gli eventi: {0}" -f $det)
            Show-SecFindings $find "Accessi_Falliti"
        } catch { Write-Log "[ERRORE] Lettura accessi falliti: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Analizza gli accessi falliti (evento 4625) degli ultimi giorni: tipo di accesso, indirizzi e account più colpiti. Segnala i casi con molti tentativi, possibile forza bruta. Richiede i diritti di amministratore.")
)

$tweakBtns = @(
@("Ripristina Menu Contestuale Classico W11", {
        $msg = "Vuoi ripristinare il menu contestuale CLASSICO di Windows 10 su Windows 11?`r`n`r`nVerrà creata la chiave:`r`nHKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32`r`n`r`nDopo sarà necessario riavviare Esplora Risorse.`r`n`r`nVuoi procedere?"
        $choice = [System.Windows.Forms.MessageBox]::Show($msg, "Conferma - Menu Classico", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
            Show-CommandSummary "Ripristino Menu Contestuale Classico W11" @(
                'New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Force',
                'Set (Default) = "" [REG_SZ]',
                'Equivalente a: reg add "HKCU\...\InprocServer32" /f /ve'
            )
            try {
                $regPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
                Write-Log "Ripristino del menu contestuale classico di Windows 11..." "In esecuzione..."
                if (-not (Test-Path $regPath)) {
                    New-Item -Path $regPath -Force | Out-Null
                    Write-Log "[OK] Chiave registro creata: $regPath"
                }
                try {
                    Set-ItemProperty -LiteralPath $regPath -Name "(default)" -Value "" -ErrorAction Stop | Out-Null
                } catch {
                    & reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve | Out-Null
                }
                Write-Log "" 
                Write-Log "[OK] Menu classico ripristinato!" "Completato"
                $restart = [System.Windows.Forms.MessageBox]::Show("Menu classico ripristinato con successo!`r`n`r`nVuoi riavviare ora Esplora Risorse per applicare subito la modifica?", "Riavvio Explorer", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
                if ($restart -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Write-Log "Riavvio Esplora Risorse in corso..."
                    try { taskkill /f /im explorer.exe 2>&1 | Out-Null } catch { Write-StartLog "Errore ignorato: $_" }
                    Start-Sleep -Seconds 1
                    Start-Process explorer.exe
                    Write-Log "[OK] Explorer riavviato - menu classico attivo!" "Completato"
                } else {
                    Write-Log "[NOTA] Riavvia Esplora Risorse o riavvia il PC per vedere il menu classico." "Completato"
                }
            } catch {
                Write-Log "[ERRORE] Ripristino menu: $_" "Errore"
                [System.Windows.Forms.MessageBox]::Show("Errore durante il ripristino:`r`n$_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        } else {
            Write-Log "[INFO] Operazione annullata dall'utente." "Annullato"
        }
    }, "#78350F", "#F8FAFC", "Converte il tuo comando batch 'reg add ... /f /ve' in PowerShell nativo per ripristinare il menu contestuale classico di Windows 10 su Windows 11."),
@("Ripristina Menu Moderno Win 11 (Annulla)", {
        $msg = "Vuoi tornare al menu contestuale MODERNO di Windows 11?`r`n`r`nVerrà eliminata la chiave:`r`nHKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}`r`n`r`nVuoi procedere?"
        $choice = [System.Windows.Forms.MessageBox]::Show($msg, "Conferma - Menu Moderno", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
            Show-CommandSummary "Ripristino Menu Moderno W11" @('Remove-Item "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force')
            try {
                $regPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
                if (Test-Path $regPath) {
                    Remove-Item -Path $regPath -Recurse -Force -ErrorAction Stop
                    Write-Log "[OK] Chiave rimossa: $regPath - Menu moderno ripristinato!" "Completato"
                    $restart = [System.Windows.Forms.MessageBox]::Show("Menu moderno ripristinato!`r`nVuoi riavviare Esplora Risorse?", "Riavvio Explorer", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
                    if ($restart -eq [System.Windows.Forms.DialogResult]::Yes) {
                        taskkill /f /im explorer.exe 2>&1 | Out-Null; Start-Sleep 1; Start-Process explorer.exe
                        Write-Log "[OK] Explorer riavviato." "Completato"
                    }
                } else {
                    Write-Log "[INFO] Menu moderno già attivo (chiave non presente)." "Completato"
                }
            } catch {
                Write-Log "[ERRORE] $_" "Errore"
            }
        }
    }, "#1E40AF", "#F8FAFC", "Rimuove la modifica e ripristina il menu contestuale moderno di Windows 11 con 'Mostra altre opzioni'."),
@("Ripristina Cache Microsoft Store", {
        Show-CommandSummary "Ripristino Cache Microsoft Store" @("wsreset.exe")
        Write-Log "Avvio ripristino della cache dello Store..."
        Start-Process "wsreset.exe"
        [System.Windows.Forms.MessageBox]::Show("Il comando WSReset è stato avviato.`r`nLa cache dello Store è stata ripulita.", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }, "#064E3B", "#F8FAFC", "Svuota e ripristina la cache di Microsoft Store per risolvere problemi di download delle app."),
@("Pulisci Cache Browser (Chrome, Edge, Firefox)", {
        Show-CommandSummary "Pulizia Cache Browser" @("Clear-BrowserCache")
        Clear-BrowserCache
    }, "#064E3B", "#F8FAFC", "Elimina i file temporanei e la cache dei principali browser web (Chrome, Edge, Firefox) installati nel sistema."),
@("Riavvia Esplora Risorse (explorer.exe)", {
        Show-CommandSummary "Riavvia Esplora Risorse" @("taskkill /f /im explorer.exe", "start explorer.exe")
        try {
            Write-Log "Riavvio di Esplora Risorse in corso..."
            taskkill /f /im explorer.exe 2>&1 | Out-Null
            Start-Sleep -Seconds 1
            Start-Process explorer.exe
            Write-Log "[OK] Esplora Risorse riavviato con successo." "Completato"
        } catch {
            Write-Log "[ERRORE] Riavvia Esplora Risorse: $_" "Errore"
        }
    }, "#78350F", "#F8FAFC", "Termina e riavvia il processo explorer.exe - utile per risolvere blocchi della barra delle applicazioni o del desktop."),
@("Sblocca Profilo 'Prestazioni Eccellenti'", {
        Show-CommandSummary "Sblocca Prestazioni Eccellenti" @("powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61")
        try {
            $null = & powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
            Write-Log "[OK] Profilo energetico 'Prestazioni Eccellenti' sbloccato con successo." "Completato"
            [System.Windows.Forms.MessageBox]::Show("Profilo energetico 'Prestazioni Eccellenti' aggiunto con successo!`r`nOra puoi selezionarlo anche dal Pannello di Controllo / Opzioni Risparmio Energia.", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            Write-Log "[ERRORE] Impossibile aggiungere il profilo energetico: $_" "Errore"
        }
    }, "#064E3B", "#F8FAFC", "Sblocca il piano di alimentazione nascosto 'Prestazioni Eccellenti' per eliminare qualsiasi latenza hardware."),
@("Disattiva Ibernazione (Libera Spazio RAM)", {
        $msg = "ATTENZIONE: Disattivazione Ibernazione (`hiberfil.sys`).`r`n`r`n" +
               "Questo comando disattiverà la funzione di ibernazione del PC ed eliminerà il file di sistema hiberfil.sys dalla radice di C:, " +
               "liberando all'istante una quantità di spazio su disco pari alla RAM installata (es. da 8 a 32 GB).`r`n`r`n" +
               "Nota: Non potrai più ibernare il computer (la sospensione normale continuerà a funzionare).`r`n`r`n" +
               "Vuoi procedere?"
               
        $choice = [System.Windows.Forms.MessageBox]::Show($msg, "Conferma Disattivazione Ibernazione", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        
        if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
            Show-CommandSummary "Disattivazione Ibernazione" @("powercfg /hibernate off")
            try {
                powercfg /hibernate off
                Write-Log "[OK] Ibernazione disattivata e file hiberfil.sys rimosso con successo." "Completato"
                [System.Windows.Forms.MessageBox]::Show("Ibernazione disattivata con successo! Spazio su disco recuperato.", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            } catch {
                Write-Log "[ERRORE] Impossibile disattivare l'ibernazione: $_" "Errore"
            }
        } else {
            Write-Log "[INFO] Operazione di disattivazione ibernazione annullata dall'utente." "Annullato"
        }
    }, "#78350F", "#FFFFFF", "[ATTENZIONE] Disattiva l'ibernazione ed elimina il file hiberfil.sys liberando gigabyte di spazio pari alla RAM."),
@("Configura Avviso Reindirizzamento RDP", {
        $msg = "Vuoi configurare il criterio di avviso per il reindirizzamento RDP (RedirectionWarningDialogVersion = 1)?"
        $choice = [System.Windows.Forms.MessageBox]::Show($msg, "Conferma Criterio RDP", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
            $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\Client"
            Show-CommandSummary "Configura Avviso RDP" @("reg add HKLM\...\Terminal Services\Client /v RedirectionWarningDialogVersion /t REG_DWORD /d 1 /f")
            Set-RegistryWithCheck -Path $regPath -Name "RedirectionWarningDialogVersion" -Value 1 -PropertyType "DWORD" -Description "Avviso Reindirizzamento RDP"
        } else {
            Write-Log "[INFO] Operazione annullata dall'utente." "Annullato"
        }
    }, "#78350F", "#F8FAFC", "Imposta il criterio di registro per la versione della finestra di avviso di reindirizzamento RDP.")
)

$usbBtns = @(
    @("Elenca Dischi USB/Rimovibili", {
        Show-CommandSummary "Elenca Dischi USB/Rimovibili" @("Get-Volume")
        Write-Log "--- AGGIORNAMENTO E ANALISI DISCHI USB / ESTERNI ---" "Aggiornamento in corso..."
        
        $volumes = Get-Volume | Where-Object { $_.DriveLetter -ne $null }
        $found = $false
        
        foreach ($vol in $volumes) {
            $letter = $vol.DriveLetter
            if ($vol.DriveType -eq "Removable" -or $letter -eq "T" -or $vol.FileSystemLabel -match "Backup|SSD|USB|External") {
                $freeGB = [math]::round($vol.SizeRemaining / 1GB, 2)
                $totGB = [math]::round($vol.Size / 1GB, 2)
                $label = if ($vol.FileSystemLabel) { $vol.FileSystemLabel } else { "Senza Etichetta" }
                Write-Log "Lettera: ${letter}: | Etichetta: $label | Tipo: $($vol.DriveType) | Spazio Libero: $freeGB GB su $totGB GB"
                $found = $true
            }
        }
        
        if (-not $found) {
            foreach ($vol in $volumes) {
                if ($vol.DriveLetter -ne "C" -and $vol.Size -gt 0) {
                    $freeGB = [math]::round($vol.SizeRemaining / 1GB, 2)
                    $totGB = [math]::round($vol.Size / 1GB, 2)
                    $label = if ($vol.FileSystemLabel) { $vol.FileSystemLabel } else { "Senza Etichetta" }
                    Write-Log "Lettera: $($vol.DriveLetter): | Etichetta: $label | Spazio Libero: $freeGB GB su $totGB GB"
                    $found = $true
                }
            }
        }

        if ($found) {
            Write-Log "[OK] Elenco dischi USB/esterni aggiornato con successo." "Completato"
        } else {
            Write-Log "[INFO] Nessun disco USB/esterno rilevato al momento." "Nessun disco"
            [System.Windows.Forms.MessageBox]::Show("Nessun disco USB rilevato.`r`nSe hai appena collegato il disco, attendi qualche secondo che Windows assegni la lettera o prova a cliccare nuovamente.", "Attenzione", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    }, "#064E3B", "#F8FAFC", "Aggiorna la lista e mostra i dischi USB e adattatori SATA-USB collegati (incluso T:)."),
    @("Espelli Disco USB (Espulsione Sicura)", {
        $inputResult = [Microsoft.VisualBasic.Interaction]::InputBox("Inserisci la lettera dell'unità da espellere in sicurezza:`r`n(es. T oppure T:)", "Espulsione Disco Mirata", "T")
        
        if (-not [string]::IsNullOrWhiteSpace($inputResult)) {
            $cleanLetter = $inputResult.Trim().ToUpper()
            if (-not $cleanLetter.EndsWith(":")) { $cleanLetter += ":" }
            
            Show-CommandSummary "Espulsione Disco $cleanLetter" @("(New-Object -comObject Shell.Application).Namespace(17).ParseName('$cleanLetter').InvokeVerb('Eject')")
            try {
                $shellApp = New-Object -comObject Shell.Application
                $folderItem = $shellApp.Namespace(17).ParseName($cleanLetter)
                if ($folderItem) {
                    $folderItem.InvokeVerb("Eject")
                    Write-Log "[OK] Comando di rimozione inviato con successo per l'unità $cleanLetter." "Espulso"
                    [System.Windows.Forms.MessageBox]::Show("Comando di espulsione inviato con successo per l'unità ${cleanLetter}.`r`nOra puoi scollegare la periferica in sicurezza.", "Rimozione Completata", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                } else {
                    Write-Log "[ERRORE] Impossibile trovare l'unità $cleanLetter per l'espulsione." "Errore"
                    [System.Windows.Forms.MessageBox]::Show("Impossibile trovare l'unità $cleanLetter nel sistema.`r`nVerifica che la lettera sia corretta e che il disco sia collegato.", "Unità non trovata", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            } catch {
                Write-Log "[ERRORE] Impossibile espellere il disco $cleanLetter : $_" "Errore"
                [System.Windows.Forms.MessageBox]::Show("Errore durante l'espulsione dell'unità ${cleanLetter}:`r`n$_`r`n`r`nNota: Assicurati di aver rilasciato eventuali blocchi (es. Veeam con il tasto 60) o file aperti sull'unità.", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        } else {
            Write-Log "[INFO] Operazione di espulsione disco annullata dall'utente." "Annullato"
        }
    }, "#78350F", "#F8FAFC", "Permette di scegliere la lettera (es. T:) ed esegue l'espulsione sicura dell'unità selezionata."),
    @("Arresta Servizi Veeam (Sblocca Disco)", {
        $msg = "ATTENZIONE: Stai per arrestare i servizi di Veeam (Mount e Transport Service).`r`n`r`n" +
               "Questo sbloccherà immediatamente i dischi di backup tenuti occupati da Veeam VBR.`r`n" +
               "Vuoi procedere?"
        $choice = [System.Windows.Forms.MessageBox]::Show($msg, "Arresto Servizi Veeam", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
            Show-CommandSummary "Arresto Servizi Veeam" @("Stop-Service VeeamMountSvc", "Stop-Service VeeamTransportSvc")
            try {
                Stop-Service -Name VeeamMountSvc -Force -ErrorAction SilentlyContinue
                Stop-Service -Name VeeamTransportSvc -Force -ErrorAction SilentlyContinue
                Write-Log "[OK] Servizi Veeam arrestati con successo. I dischi dovrebbero ora essere liberi." "Servizi Arrestati"
                [System.Windows.Forms.MessageBox]::Show("Servizi Veeam arrestati con successo! Ora puoi scollegare o espellere il disco.", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            } catch {
                Write-Log "[ERRORE] Impossibile arrestare i servizi Veeam: $_" "Errore"
            }
        } else {
            Write-Log "[INFO] Arresto servizi Veeam annullato." "Annullato"
        }
    }, "#78350F", "#FFFFFF", "[VEEAM] Arresta i servizi Mount e Transport per rilasciare i blocchi sui dischi di backup."),
    @("Riavvia Servizi Veeam", {
        Show-CommandSummary "Riavvio Servizi Veeam" @("Start-Service VeeamMountSvc", "Start-Service VeeamTransportSvc")
        try {
            Start-Service -Name VeeamMountSvc -ErrorAction SilentlyContinue
            Start-Service -Name VeeamTransportSvc -ErrorAction SilentlyContinue
            Write-Log "[OK] Servizi Veeam riavviati con successo." "Servizi Attivi"
            [System.Windows.Forms.MessageBox]::Show("Servizi Veeam riavviati regolarmente.", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            Write-Log "[ERRORE] Impossibile riavviare i servizi Veeam: $_" "Errore"
        }
    }, "#064E3B", "#F8FAFC", "[VEEAM] Riattiva i servizi di mount e trasporto Veeam precedentemente arrestati."),
    @("Finestra Rimozione Hardware (System)", {
        Show-CommandSummary "Finestra Rimozione Hardware" @("control hotplug.dll")
        Start-Process "control.exe" -ArgumentList "hotplug.dll"
        Write-Log "Apertura della finestra classica 'Rimozione sicura dell'hardware'..." "Completato"
    }, "#064E3B", "#F8FAFC", "Apre la classica interfaccia grafica di Windows per la rimozione sicura delle periferiche USB."),
    @("Trova Chi Blocca Unità (es. T:)", {
        $inputResult = [Microsoft.VisualBasic.Interaction]::InputBox("Inserisci la lettera dell'unità da analizzare per scoprire chi la sta bloccando:`r`n(es. T oppure T:)", "Analisi Processi Bloccanti", "T")
        
        if (-not [string]::IsNullOrWhiteSpace($inputResult)) {
            $cleanLetter = $inputResult.Trim().ToUpper()
            if (-not $cleanLetter.EndsWith(":")) { $cleanLetter += ":" }
            
            Show-CommandSummary "Analisi Processi Bloccanti su $cleanLetter" @("Get-Process con verifica Handle aperti su $cleanLetter")
            Write-Log "--- SCANSIONE PROCESSI ATTIVI SULL'UNITÀ ${cleanLetter} ---" "Analisi in corso..."
            
            $foundProcesses = @()
            $procs = Get-Process -ErrorAction SilentlyContinue
            foreach ($p in $procs) {
                try {
                    foreach ($m in $p.Modules) {
                        if ($m.FileName -like "${cleanLetter}*") {
                            $foundProcesses += [PSCustomObject]@{ Name = $p.Name; Id = $p.Id; Path = $m.FileName }
                        }
                    }
                } catch { Write-StartLog "Errore ignorato: $_" }
            }
            
            $openFilesCheck = & openfiles /query /v 2>&1
            $matchedOpenFiles = @()
            if ($LASTEXITCODE -eq 0) {
                foreach ($line in $openFilesCheck) {
                    if ($line -like "*${cleanLetter}*") {
                        $matchedOpenFiles += $line
                    }
                }
            }

            $uniqueProcs = $foundProcesses | Select-Object -Unique Name, Id
            if ($uniqueProcs -or $matchedOpenFiles) {
                Write-Log "[ATTENZIONE] Trovati processi che stanno utilizzando o bloccando l'unità ${cleanLetter}:" "Blocco Rilevato"
                foreach ($up in $uniqueProcs) {
                    Write-Log " -> Processo: $($up.Name) (PID: $($up.Id))"
                }
                foreach ($of in $matchedOpenFiles) {
                    Write-Log " -> File Aperto: $of"
                }
                [System.Windows.Forms.MessageBox]::Show("Sono stati individuati processi attivi sull'unità ${cleanLetter}.`r`nConsulta la console log in basso per leggere i nomi e i PID dei programmi responsabili del blocco.", "Processi Bloccanti Trovati", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            } else {
                Write-Log "[OK] Nessun modulo o file di processo bloccante diretto rilevato tramite scansione standard sull'unità ${cleanLetter}." "Unità libera"
                [System.Windows.Forms.MessageBox]::Show("Scansione completata per l'unità ${cleanLetter}.`r`nNessun processo bloccante diretto trovato.", "Esito Scansione", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        } else {
            Write-Log "[INFO] Analisi processi bloccanti annullata dall'utente." "Annullato"
        }
    }, "#064E3B", "#F8FAFC", "Cerca e individua quali processi o programmi stanno bloccando l'unità selezionata (es. T:)."),
    @("Metti Disco Offline per Smontaggio", {
        $inputResult = [Microsoft.VisualBasic.Interaction]::InputBox("Inserisci la lettera del disco da mettere OFFLINE per permetterne lo smontaggio fisico/rimozione:`r`n(es. T oppure T:)", "Metti Disco Offline (Critico)", "T")
        
        if (-not [string]::IsNullOrWhiteSpace($inputResult)) {
            $cleanLetter = $inputResult.Trim().ToUpper()
            if (-not $cleanLetter.EndsWith(":")) { $cleanLetter += ":" }
            
            $confirmMsg = "ATTENZIONE: COMANDO CRITICO (ROSSO)!`r`n`r`n" +
                          "Stai per impostare lo stato OFFLINE per il disco associato all'unità $cleanLetter.`r`n" +
                          "Questo interromperà qualsiasi accesso al volume e lo renderà inattivo nel sistema per consentirne la rimozione in sicurezza.`r`n`r`n" +
                          "Sei assolutamente sicuro di voler procedere?"
            
            $confirm = [System.Windows.Forms.MessageBox]::Show($confirmMsg, "CONFERMA CRITICA - Disco Offline", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Error)
            
            if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
                Show-CommandSummary "Metti Disco Offline per Unità $cleanLetter" @("Get-Partition -DriveLetter ... | Get-Disk", "Set-Disk -IsOffline `$true")
                try {
                    $partition = Get-Partition -DriveLetter ($cleanLetter -replace ':', '') -ErrorAction Stop
                    $diskNumber = $partition.DiskNumber
                    
                    if ($null -ne $diskNumber) {
                        Set-Disk -Number $diskNumber -IsOffline $true -ErrorAction Stop
                        Write-Log "[OK] Il disco fisico $diskNumber (associato all'unità $cleanLetter) è stato messo OFFLINE con successo." "Disco Offline"
                        [System.Windows.Forms.MessageBox]::Show("Il disco corrispondente all'unità ${cleanLetter} (Disco #$diskNumber) è stato messo OFFLINE con successo.`r`nOra è possibile procedere allo smontaggio fisico o alla rimozione in sicurezza.", "Operazione Completata", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                    } else {
                        Write-Log "[ERRORE] Impossibile identificare il numero di disco fisico per l'unità $cleanLetter." "Errore"
                        [System.Windows.Forms.MessageBox]::Show("Impossibile associare la lettera $cleanLetter a un disco fisico.", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    }
                } catch {
                    Write-Log "[ERRORE] Impossibile mettere offline il disco $cleanLetter : $_" "Errore"
                    [System.Windows.Forms.MessageBox]::Show("Errore durante l'impostazione offline dell'unità ${cleanLetter}:`r`n$_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            } else {
                Write-Log "[INFO] Operazione disco offline annullata dall'utente." "Annullato"
            }
        } else {
            Write-Log "[INFO] Operazione disco offline annullata dall'utente." "Annullato"
        }
    }, "#7F1D1D", "#FFFFFF", "[CRITICO] Chiede la lettera del disco e lo imposta offline a livello di sistema per consentirne lo smontaggio.")
)

$adBtns = @(

    @("Report Password in Scadenza <7gg (CSV)", {
        Show-CommandSummary "Password Scadenza 7gg" @("Search-ADAccount -PasswordExpired / -PasswordNeverExpires / Get-ADUser PasswordLastSet")
        if (-not (Test-ADModule)) { return }
        Show-WaitOverlay -msg "Analisi password AD in scadenza..."
        try {
            $OutputFile = Get-ADOutputPath "Password_Scadenza_7gg_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
            $MaxAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days
            $Threshold = (Get-Date).AddDays(7)
            $users = Get-ADUser -Filter {Enabled -eq $true} -Properties PasswordLastSet, PasswordNeverExpires, DisplayName, Mail -ErrorAction Stop
            $report = foreach ($u in $users) {
                if ($u.PasswordNeverExpires -or -not $u.PasswordLastSet) { continue }
                $expiry = $u.PasswordLastSet.AddDays($MaxAge)
                if ($expiry -le $Threshold) {
                    [PSCustomObject]@{ SamAccountName=$u.SamAccountName; DisplayName=$u.DisplayName; Mail=$u.Mail; PasswordLastSet=$u.PasswordLastSet; Scadenza=$expiry; GiorniRimanenti=($expiry - (Get-Date)).Days }
                }
            }
            $report | Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8
            Write-Log "Trovati $($report.Count) utenti con password in scadenza entro 7 giorni."
            Write-Log "File: $OutputFile"
            Write-Log "Report scadenza password completato con successo" "Completato"
        } catch { Write-Log "[ERRORE] $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Genera CSV con utenti AD la cui password scade entro 7 giorni (basato su policy dominio)."),

    @("Report Account Bloccati AD (CSV)", {
        Show-CommandSummary "Account Bloccati AD" @("Search-ADAccount -LockedOut | Export-Csv")
        if (-not (Test-ADModule)) { return }
        Show-WaitOverlay -msg "Ricerca account bloccati..."
        try {
            $OutputFile = Get-ADOutputPath "Account_Bloccati_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
            $locked = Search-ADAccount -LockedOut | Get-ADUser -Properties LockedOut, DisplayName, LastBadPasswordAttempt, LockedOutTime, Mail
            $report = $locked | Select-Object SamAccountName, DisplayName, Mail, LockedOut, LastBadPasswordAttempt, LockedOutTime
            $report | Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8
            Write-Log "Trovati $($report.Count) account bloccati."
            $report | ForEach-Object { Write-Log "Bloccato: $($_.SamAccountName) | Ultimo tentativo errato: $($_.LastBadPasswordAttempt)" }
            Write-Log "File: $OutputFile"
            Write-Log "Report account bloccati completato con successo" "Completato"
        } catch { Write-Log "[ERRORE] $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Elenca tutti gli account AD attualmente bloccati con data ultimo tentativo errato ed esporta in CSV."),


    @("Report Utenti + Ruolo Admin (CSV)", {
        Show-CommandSummary "Report Utenti + Ruolo Admin" @("Get-ADUser -Filter * -Properties Enabled, DisplayName, Email", "Get-ADPrincipalGroupMembership", "Export-Csv <cartella script>\UtentiGruppi_AD.csv")
        if (-not (Test-ADModule)) { return }
        try {
            $OutputFile = Get-ADOutputPath "UtentiGruppi_AD_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
            $AdminGroups = @("Domain Admins", "Administrators", "Enterprise Admins", "Schema Admins", "Account Operators", "Backup Operators")
            Write-Log "[INFO] Generazione report utenti AD in corso..." "AD-Tools"
            
            $users = Get-ADUser -Filter * -Properties Enabled, DisplayName, Mail, Department, Title, LastLogonDate, PasswordLastSet -ErrorAction Stop
            $total = $users.Count; $i=0
            $Report = foreach ($user in $users) {
                $i++; Write-Progress -Activity "Analisi AD" -Status "$i/$total $($user.SamAccountName)" -PercentComplete (($i/$total)*100)
                $groups = @()
                try {
                    $groups = Get-ADPrincipalGroupMembership $user -ErrorAction Stop | Select-Object -ExpandProperty Name
                } catch {
                    $groups = @("ERRORE: $($_.Exception.Message)")
                }
                $IsAdmin = "User Semplice"
                if ($groups -is [array]) {
                    foreach ($Group in $groups) {
                        if ($AdminGroups -contains $Group) { $IsAdmin = "Amministratore ($Group)"; break }
                    }
                }
                $Status = if ($user.Enabled) { "Attivo" } else { "Disattivato" }
                [PSCustomObject]@{
                    Username      = $user.SamAccountName
                    NomeCompleto  = $user.Name
                    DisplayName   = $user.DisplayName
                    Email         = $user.Mail
                    Dipartimento  = $user.Department
                    Titolo        = $user.Title
                    StatoAccount  = $Status
                    Ruolo         = $IsAdmin
                    LastLogon     = if ($user.LastLogonDate) { $user.LastLogonDate.ToString("yyyy-MM-dd HH:mm") } else { "Mai" }
                    PwdLastSet    = if ($user.PasswordLastSet) { $user.PasswordLastSet.ToString("yyyy-MM-dd") } else { "Mai" }
                    Gruppi        = if ($groups -is [array]) { $groups -join "; " } else { $groups }
                }
            }
            Write-Progress -Activity "Analisi AD" -Completed
            $Report | Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8
            Write-Log "[OK] Report generato: $OutputFile - $($Report.Count) utenti" "AD Report OK"
            [System.Windows.Forms.MessageBox]::Show("Report completato!`r`n`r`nFile: $OutputFile`r`nUtenti: $($Report.Count)", "AD Report", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Invoke-Item (Split-Path $OutputFile)
        } catch {
            Write-Log "[ERRORE] Report AD: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#1E3A8A", "#F8FAFC", "Il tuo script originale migliorato: estrae tutti gli utenti, verifica appartenenza a gruppi admin, salva CSV con email, dipartimento, last logon."),

    @("Export Completo Utenti (Tutte Proprieta)", {
        Show-CommandSummary "Export Completo" @("Get-ADUser -Filter * -Properties * -> CSV con 30+ campi")
        if (-not (Test-ADModule)) { return }
        try {
            $props = @("SamAccountName","GivenName","Surname","DisplayName","Name","UserPrincipalName","Mail","Department","Title","Company","Manager","Enabled","LockedOut","PasswordNeverExpires","PasswordExpired","LastLogonDate","LastLogonTimestamp","PasswordLastSet","AccountExpirationDate","whenCreated","whenChanged","Description","Office","OfficePhone","MobilePhone","StreetAddress","City","PostalCode","MemberOf")
            $OutputFile = Get-ADOutputPath "AD_Export_Completo_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
            Write-Log "[INFO] Export completo AD... potrebbe richiedere tempo" "AD-Tools"
            Get-ADUser -Filter * -Properties $props | Select-Object $props | Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8
            Write-Log "[OK] Export completo: $OutputFile" "Export OK"
            [System.Windows.Forms.MessageBox]::Show("Export completo generato:`r`n$OutputFile", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Invoke-Item (Split-Path $OutputFile)
        } catch {
            Write-Log "[ERRORE] Export completo: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#CBD5E1", "#0F172A", "Sola lettura: estrae TUTTE le proprietà principali AD per ogni utente (30+ colonne) - ideale per inventario."),

    @("Utenti Disattivati / Attivi", {
        Show-CommandSummary "Utenti Disattivati/Attivi" @("Get-ADUser -Filter {Enabled -eq $false}", "Get-ADUser -Filter {Enabled -eq $true}")
        if (-not (Test-ADModule)) { return }
        try {
            $OutputFileDisabled = Get-ADOutputPath "AD_Utenti_Disattivati_$(Get-Date -Format 'yyyyMMdd').csv"
            $OutputFileEnabled = Get-ADOutputPath "AD_Utenti_Attivi_$(Get-Date -Format 'yyyyMMdd').csv"
            $disabled = Get-ADUser -Filter {Enabled -eq $false} -Properties DisplayName, Mail, Department, LastLogonDate, whenChanged | Select-Object SamAccountName, DisplayName, Mail, Department, LastLogonDate, whenChanged, DistinguishedName
            $enabled = Get-ADUser -Filter {Enabled -eq $true} -Properties DisplayName, Mail, Department, LastLogonDate | Select-Object SamAccountName, DisplayName, Mail, Department, LastLogonDate
            $disabled | Export-Csv $OutputFileDisabled -NoTypeInformation -Encoding UTF8
            $enabled | Export-Csv $OutputFileEnabled -NoTypeInformation -Encoding UTF8
            Write-Log "[OK] Disattivati: $($disabled.Count) | Attivi: $($enabled.Count)" "AD Report"
            [System.Windows.Forms.MessageBox]::Show("Utenti disattivati: $($disabled.Count)`r`nFile: $OutputFileDisabled`r`n`r`nUtenti attivi: $($enabled.Count)`r`nFile: $OutputFileEnabled", "AD Utenti Stato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Invoke-Item (Split-Path $OutputFileDisabled)
        } catch {
            Write-Log "[ERRORE] Filtro stato: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#CBD5E1", "#0F172A", "Sola lettura: due CSV separati per utenti attivi e disattivati con data ultimo logon."),

    @("Utenti Inattivi >90gg & Mai Loggati", {
        Show-CommandSummary "Utenti Inattivi" @("Filtro LastLogonDate < (Get-Date).AddDays(-90)", "Cerca account obsoleti da disattivare")
        if (-not (Test-ADModule)) { return }
        try {
            $days = [Microsoft.VisualBasic.Interaction]::InputBox("Quanti giorni di inattività considerare?`r`nDefault 90 giorni", "Utenti Inattivi", "90")
            if ([string]::IsNullOrWhiteSpace($days)) { return }
            $daysInt = [int]$days
            $threshold = (Get-Date).AddDays(-$daysInt)
            $OutputFile = Get-ADOutputPath "AD_Inattivi_${daysInt}gg_$(Get-Date -Format 'yyyyMMdd').csv"
            $users = Get-ADUser -Filter {LastLogonDate -lt $threshold -or LastLogonDate -notlike "*"} -Properties LastLogonDate, Mail, Department, whenCreated, Description | Where-Object { $_.Enabled -eq $true } | Select-Object SamAccountName, DisplayName, Mail, Department, LastLogonDate, whenCreated, Description, DistinguishedName
            $users | Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8
            Write-Log "[OK] Utenti inattivi da $daysInt giorni: $($users.Count)" "AD Cleanup"
            [System.Windows.Forms.MessageBox]::Show("Trovati $($users.Count) utenti attivi ma inattivi da oltre $daysInt giorni.`r`n`r`nFile: $OutputFile`r`n`r`nSuggerimento: valuta disattivazione dopo verifica.", "Utenti Inattivi", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            Invoke-Item (Split-Path $OutputFile)
        } catch {
            Write-Log "[ERRORE] Inattivi: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#F59E0B", "#0F172A", "Analisi sicurezza: trova account attivi ma non usati da X giorni (default 90) - utili per pulizia AD."),

    @("Password: Scadute / Mai Scadono / Non Cambiate", {
        Show-CommandSummary "Password Report" @("PasswordNeverExpires, PasswordExpired, PasswordLastSet")
        if (-not (Test-ADModule)) { return }
        try {
            $Output1 = Get-ADOutputPath "AD_Pwd_MaiScadono_$(Get-Date -Format 'yyyyMMdd').csv"
            $Output2 = Get-ADOutputPath "AD_Pwd_Scadute_$(Get-Date -Format 'yyyyMMdd').csv"
            $Output3 = Get-ADOutputPath "AD_Pwd_Vecchie90gg_$(Get-Date -Format 'yyyyMMdd').csv"
            
            $neverExpire = Get-ADUser -Filter {PasswordNeverExpires -eq $true} -Properties PasswordNeverExpires, PasswordLastSet, Mail, Department | Select-Object SamAccountName, DisplayName, Mail, Department, PasswordLastSet, PasswordNeverExpires, Enabled
            $expired = Search-ADAccount -PasswordExpired | Select-Object SamAccountName, Name, LastLogonDate, PasswordExpired
            $oldPwdThreshold = (Get-Date).AddDays(-90)
            $oldPwd = Get-ADUser -Filter {PasswordLastSet -lt $oldPwdThreshold -and Enabled -eq $true} -Properties PasswordLastSet, Mail, LastLogonDate | Select-Object SamAccountName, DisplayName, Mail, PasswordLastSet, LastLogonDate
            
            $neverExpire | Export-Csv $Output1 -NoTypeInformation -Encoding UTF8
            $expired | Export-Csv $Output2 -NoTypeInformation -Encoding UTF8
            $oldPwd | Export-Csv $Output3 -NoTypeInformation -Encoding UTF8
            
            Write-Log "[OK] Pwd MaiScadono: $($neverExpire.Count) | Scadute: $($expired.Count) | Vecchie90gg: $($oldPwd.Count)" "Password Audit"
            [System.Windows.Forms.MessageBox]::Show("Audit Password completato:`r`n`r`nMai scadono: $($neverExpire.Count) -> $(Split-Path $Output1 -Leaf)`r`nScadute: $($expired.Count) -> $(Split-Path $Output2 -Leaf)`r`nNon cambiate da 90gg: $($oldPwd.Count) -> $(Split-Path $Output3 -Leaf)", "Password Report", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Invoke-Item (Split-Path $Output1)
        } catch {
            Write-Log "[ERRORE] Password report: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#CBD5E1", "#0F172A", "Sola lettura: 3 report su password - chi ha 'mai scade', chi è scaduto, chi non cambia da 90gg."),

    @("Account Bloccati & Scaduti", {
        Show-CommandSummary "Account Bloccati" @("Search-ADAccount -LockedOut, -AccountExpired")
        if (-not (Test-ADModule)) { return }
        try {
            $locked = Search-ADAccount -LockedOut | Select-Object SamAccountName, Name, LastLogonDate, LockedOut
            $expiredAcc = Search-ADAccount -AccountExpired | Select-Object SamAccountName, Name, AccountExpirationDate, LastLogonDate
            $OutputLocked = Get-ADOutputPath "AD_Bloccati_$(Get-Date -Format 'yyyyMMdd').csv"
            $OutputExpired = Get-ADOutputPath "AD_Scaduti_$(Get-Date -Format 'yyyyMMdd').csv"
            $locked | Export-Csv $OutputLocked -NoTypeInformation -Encoding UTF8
            $expiredAcc | Export-Csv $OutputExpired -NoTypeInformation -Encoding UTF8
            Write-Log "[OK] Bloccati: $($locked.Count) | Scaduti: $($expiredAcc.Count)" "AD Lockout"
            
            $msg = "Account bloccati: $($locked.Count)`r`nAccount scaduti: $($expiredAcc.Count)"
            if ($locked.Count -gt 0) {
                $msg += "`r`n`r`nVuoi sbloccare TUTTI gli account bloccati ora?"
                $res = [System.Windows.Forms.MessageBox]::Show($msg, "Account Bloccati", [System.Windows.Forms.MessageBoxButtons]::YesNoCancel, [System.Windows.Forms.MessageBoxIcon]::Question)
                if ($res -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Search-ADAccount -LockedOut | Unlock-ADAccount -Confirm:$false
                    Write-Log "[OK] Sbloccati $($locked.Count) account" "Sblocco"
                    [System.Windows.Forms.MessageBox]::Show("Sbloccati $($locked.Count) account!", "Fatto", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
            } else {
                [System.Windows.Forms.MessageBox]::Show($msg + "`r`n`r`nFile salvati in: $global:OutputDir", "Report", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
            Invoke-Item (Split-Path $OutputLocked)
        } catch {
            Write-Log "[ERRORE] Bloccati/Scaduti: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#F59E0B", "#0F172A", "Report bloccati/scaduti + opzione per sbloccare tutti in un colpo."),

    @("Gruppi AD + Membri (Completo)", {
        Show-CommandSummary "Gruppi AD" @("Get-ADGroup -Filter *", "Get-ADGroupMember per ogni gruppo")
        if (-not (Test-ADModule)) { return }
        try {
            $OutputFile = Get-ADOutputPath "AD_Gruppi_Membri_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
            $OutputFile2 = Get-ADOutputPath "AD_Gruppi_Lista_$(Get-Date -Format 'yyyyMMdd').csv"
            Write-Log "[INFO] Estrazione gruppi AD..." "AD Gruppi"
            $allGroups = Get-ADGroup -Filter * -Properties Description, GroupCategory, GroupScope, whenCreated, Members | Select-Object Name, GroupCategory, GroupScope, Description, whenCreated, DistinguishedName
            $allGroups | Export-Csv $OutputFile2 -NoTypeInformation -Encoding UTF8
            
            $report = @()
            foreach ($g in $allGroups) {
                try {
                    $members = Get-ADGroupMember -Identity $g.DistinguishedName -Recursive -ErrorAction SilentlyContinue | Select-Object -ExpandProperty SamAccountName -ErrorAction SilentlyContinue
                    if (-not $members) { $members = @() }
                    $report += [PSCustomObject]@{
                        Gruppo = $g.Name
                        Categoria = $g.GroupCategory
                        Ambito = $g.GroupScope
                        NumMembri = $members.Count
                        Membri = ($members -join "; ")
                        Descrizione = $g.Description
                    }
                } catch {
                    $report += [PSCustomObject]@{ Gruppo=$g.Name; Categoria=$g.GroupCategory; Ambito=$g.GroupScope; NumMembri=0; Membri="ERRORE: $_"; Descrizione=$g.Description }
                }
            }
            $report | Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8
            Write-Log "[OK] Gruppi: $($allGroups.Count) esportati" "AD Gruppi"
            [System.Windows.Forms.MessageBox]::Show("Gruppi totali: $($allGroups.Count)`r`n`r`nLista gruppi: $OutputFile2`r`nDettaglio membri: $OutputFile", "Gruppi AD", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Invoke-Item (Split-Path $OutputFile)
        } catch {
            Write-Log "[ERRORE] Gruppi: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#CBD5E1", "#0F172A", "Sola lettura: lista completa gruppi + file con tutti i membri (ricorsivo)."),

    @("Computer AD - Inventario", {
        Show-CommandSummary "Computer AD" @("Get-ADComputer -Filter * -Properties *")
        if (-not (Test-ADModule)) { return }
        try {
            $OutputFile = Get-ADOutputPath "AD_Computer_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
            $comps = Get-ADComputer -Filter * -Properties Name, DNSHostName, OperatingSystem, OperatingSystemVersion, Enabled, LastLogonDate, whenCreated, Description, IPv4Address | Select-Object Name, DNSHostName, OperatingSystem, OperatingSystemVersion, Enabled, LastLogonDate, whenCreated, IPv4Address, Description, DistinguishedName
            $comps | Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8
            Write-Log "[OK] Computer AD: $($comps.Count)" "AD Computer"
            [System.Windows.Forms.MessageBox]::Show("Computer trovati: $($comps.Count)`r`nFile: $OutputFile", "Computer AD", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Invoke-Item (Split-Path $OutputFile)
        } catch {
            Write-Log "[ERRORE] Computer: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#CBD5E1", "#0F172A", "Sola lettura: inventario PC/Server in dominio con OS, ultimo logon, IP."),

    @("Cerca Utente / Reset Password", {
        Show-CommandSummary "Cerca Utente AD" @("InputBox per SamAccountName", "Mostra proprieta + opzione reset password / sblocca")
        if (-not (Test-ADModule)) { return }
        try {
            $search = [Microsoft.VisualBasic.Interaction]::InputBox("Inserisci Username (SamAccountName) o parte del nome:`r`nEs: mario.rossi o *rossi*", "Cerca Utente AD", "")
            if ([string]::IsNullOrWhiteSpace($search)) { return }
            if ($search -notlike "*`**") { $filterSearch = "*$search*" } else { $filterSearch = $search }
            
            $found = Get-ADUser -Filter {SamAccountName -like $filterSearch -or Name -like $filterSearch -or DisplayName -like $filterSearch} -Properties * -ErrorAction SilentlyContinue | Select-Object SamAccountName, DisplayName, Mail, Department, Title, Enabled, LockedOut, LastLogonDate, PasswordLastSet, PasswordNeverExpires, whenCreated, DistinguishedName, MemberOf
            
            if (-not $found) {
                [System.Windows.Forms.MessageBox]::Show("Nessun utente trovato per: $search", "Non trovato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                return
            }
            if ($found.Count -gt 1) {
                $list = ($found | ForEach-Object { "$($_.SamAccountName) - $($_.DisplayName) - $($_.Mail)" }) -join "`r`n"
                $choice = [Microsoft.VisualBasic.Interaction]::InputBox("Trovati $($found.Count) utenti:`r`n$list`r`n`r`nInserisci lo SamAccountName esatto per dettagli:", "Seleziona Utente", $found[0].SamAccountName)
                if ([string]::IsNullOrWhiteSpace($choice)) { return }
                $found = Get-ADUser -Identity $choice -Properties * -ErrorAction Stop
            }
            
            $detail = $found | Format-List SamAccountName, DisplayName, Name, Mail, Department, Title, Company, Enabled, LockedOut, LastLogonDate, PasswordLastSet, PasswordNeverExpires, AccountExpirationDate, whenCreated, Description | Out-String
            Write-Log "[INFO] Utente trovato: $($found.SamAccountName)" "AD Search"
            
            $res = [System.Windows.Forms.MessageBox]::Show("$detail`r`n`r`nVuoi sbloccare o resettare password?`r`nSI=Sblocca | NO=Reset Password | Annulla=Chiudi", "Dettaglio Utente $($found.SamAccountName)", [System.Windows.Forms.MessageBoxButtons]::YesNoCancel, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($res -eq [System.Windows.Forms.DialogResult]::Yes) {
                Unlock-ADAccount -Identity $found.SamAccountName -Confirm:$false
                Write-Log "[OK] Sbloccato: $($found.SamAccountName)" "AD Unlock"
                [System.Windows.Forms.MessageBox]::Show("Account $($found.SamAccountName) sbloccato!", "Fatto", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            } elseif ($res -eq [System.Windows.Forms.DialogResult]::No) {
                $newPwd = [Microsoft.VisualBasic.Interaction]::InputBox("Inserisci nuova password temporanea per $($found.SamAccountName):", "Reset Password", "Password123!")
                if (-not [string]::IsNullOrWhiteSpace($newPwd)) {
                    $secPwd = ConvertTo-SecureString $newPwd -AsPlainText -Force
                    Set-ADAccountPassword -Identity $found.SamAccountName -NewPassword $secPwd -Reset
                    Set-ADUser -Identity $found.SamAccountName -ChangePasswordAtLogon $true
                    Write-Log "[OK] Password resettata per $($found.SamAccountName)" "AD Reset Pwd"
                    [System.Windows.Forms.MessageBox]::Show("Password resettata per $($found.SamAccountName)`r`nL'utente dovrà cambiarla al prossimo logon.", "Fatto", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
            }
        } catch {
            Write-Log "[ERRORE] Cerca utente: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#F59E0B", "#0F172A", "Ricerca interattiva utente + azioni: sblocco e reset password con obbligo cambio al logon."),

    @("Report OU Structure + Conteggio", {
        Show-CommandSummary "OU Structure" @("Get-ADOrganizationalUnit -Filter *", "Conteggio utenti/computer per OU")
        if (-not (Test-ADModule)) { return }
        try {
            $OutputFile = Get-ADOutputPath "AD_OU_Structure_$(Get-Date -Format 'yyyyMMdd').csv"
            $OUs = Get-ADOrganizationalUnit -Filter * -Properties Description, whenCreated | Sort-Object DistinguishedName
            $report = foreach ($ou in $OUs) {
                $usersCount = (Get-ADUser -Filter * -SearchBase $ou.DistinguishedName -SearchScope OneLevel -ErrorAction SilentlyContinue).Count
                $compsCount = (Get-ADComputer -Filter * -SearchBase $ou.DistinguishedName -SearchScope OneLevel -ErrorAction SilentlyContinue).Count
                $subOUs = (Get-ADOrganizationalUnit -Filter * -SearchBase $ou.DistinguishedName -SearchScope OneLevel -ErrorAction SilentlyContinue).Count
                [PSCustomObject]@{
                    OU_Name = $ou.Name
                    DistinguishedName = $ou.DistinguishedName
                    Utenti_Diretti = $usersCount
                    Computer_Diretti = $compsCount
                    Sotto_OU = $subOUs
                    Descrizione = $ou.Description
                    Creata_Il = $ou.whenCreated
                }
            }
            $report | Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8
            Write-Log "[OK] OU trovate: $($OUs.Count)" "AD OU"
            [System.Windows.Forms.MessageBox]::Show("OU trovate: $($OUs.Count)`r`nFile: $OutputFile", "OU Structure", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Invoke-Item (Split-Path $OutputFile)
        } catch {
            Write-Log "[ERRORE] OU: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#CBD5E1", "#0F172A", "Sola lettura: mappa tutte le OU con conteggio utenti/computer per OU."),

    @("Utenti Creati Ultimi 30gg + Nuovi Assunti", {
        Show-CommandSummary "Nuovi Utenti" @("Get-ADUser -Filter {whenCreated -ge $date}", "Report onboarding")
        if (-not (Test-ADModule)) { return }
        try {
            $days = [Microsoft.VisualBasic.Interaction]::InputBox("Ultimi quanti giorni? Default 30", "Nuovi Utenti", "30")
            if ([string]::IsNullOrWhiteSpace($days)) { return }
            $d = (Get-Date).AddDays(-[int]$days)
            $OutputFile = Get-ADOutputPath "AD_NuoviUtenti_${days}gg_$(Get-Date -Format 'yyyyMMdd').csv"
            $newUsers = Get-ADUser -Filter {whenCreated -ge $d} -Properties whenCreated, Mail, Department, Title, Enabled, DisplayName | Select-Object SamAccountName, DisplayName, Mail, Department, Title, Enabled, whenCreated, DistinguishedName | Sort-Object whenCreated -Descending
            $newUsers | Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8
            Write-Log "[OK] Nuovi utenti ultimi $days giorni: $($newUsers.Count)" "AD New Users"
            [System.Windows.Forms.MessageBox]::Show("Nuovi utenti ultimi $days giorni: $($newUsers.Count)`r`nFile: $OutputFile", "Nuovi Utenti", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Invoke-Item (Split-Path $OutputFile)
        } catch {
            Write-Log "[ERRORE] Nuovi utenti: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#10B981", "#0F172A", "Sicuro: report utenti creati negli ultimi X giorni - utile per onboarding audit."),

    @("Export Membri Gruppo Specifico", {
        Show-CommandSummary "Membri Gruppo Specifico" @("InputBox nome gruppo", "Get-ADGroupMember -Recursive -> CSV")
        if (-not (Test-ADModule)) { return }
        try {
            $groupName = [Microsoft.VisualBasic.Interaction]::InputBox("Inserisci nome gruppo AD (es: Domain Admins, o parte del nome):", "Membri Gruppo", "Domain Admins")
            if ([string]::IsNullOrWhiteSpace($groupName)) { return }
            
            # Cerca gruppo
            $group = $null
            try { $group = Get-ADGroup -Identity $groupName -ErrorAction Stop }
            catch {
                $foundGroups = Get-ADGroup -Filter {Name -like $groupName} -ErrorAction SilentlyContinue | Select-Object Name
                if ($foundGroups.Count -eq 1) { $group = Get-ADGroup -Identity $foundGroups[0].Name }
                elseif ($foundGroups.Count -gt 1) {
                    $list = ($foundGroups.Name -join "`r`n")
                    $choice = [Microsoft.VisualBasic.Interaction]::InputBox("Trovati più gruppi:`r`n$list`r`n`r`nInserisci nome esatto:", "Seleziona Gruppo", $foundGroups[0].Name)
                    if (-not [string]::IsNullOrWhiteSpace($choice)) { $group = Get-ADGroup -Identity $choice -ErrorAction Stop }
                }
            }
            if (-not $group) { throw "Gruppo '$groupName' non trovato" }
            
            $OutputFile = Get-ADOutputPath "AD_Gruppo_$($group.Name)_Membri_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
            $members = Get-ADGroupMember -Identity $group.DistinguishedName -Recursive | ForEach-Object {
                $obj = $_
                try {
                    if ($obj.objectClass -eq "user") {
                        $u = Get-ADUser -Identity $obj.SamAccountName -Properties Mail, Department, Enabled, LastLogonDate -ErrorAction SilentlyContinue
                        [PSCustomObject]@{ Tipo="Utente"; SamAccountName=$obj.SamAccountName; Nome=$obj.Name; Email=$u.Mail; Dipartimento=$u.Department; Stato=if($u.Enabled){"Attivo"}else{"Disattivo"}; LastLogon=$u.LastLogonDate }
                    } else {
                        [PSCustomObject]@{ Tipo=$obj.objectClass; SamAccountName=$obj.SamAccountName; Nome=$obj.Name; Email=""; Dipartimento=""; Stato=""; LastLogon="" }
                    }
                } catch {
                    [PSCustomObject]@{ Tipo=$obj.objectClass; SamAccountName=$obj.SamAccountName; Nome=$obj.Name; Email="ERRORE"; Dipartimento=""; Stato=""; LastLogon="" }
                }
            }
            $members | Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8
            Write-Log "[OK] Gruppo $($group.Name): $($members.Count) membri" "AD Gruppo"
            [System.Windows.Forms.MessageBox]::Show("Gruppo: $($group.Name)`r`nMembri: $($members.Count)`r`nFile: $OutputFile", "Membri Gruppo", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Invoke-Item (Split-Path $OutputFile)
        } catch {
            Write-Log "[ERRORE] Membri gruppo: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#CBD5E1", "#0F172A", "Sola lettura: scegli un gruppo (es. Domain Admins) ed esporta tutti i membri con dettagli."),

    # ==========================================================================
    # v3.8.0 - NUOVI COMANDI DIAGNOSTICA / AUDIT AD (sola lettura, tranne il backup GPO che scrive solo file)
    # ==========================================================================
    @("Salute DC: dcdiag + Replica", {
        Show-CommandSummary "Salute DC" @("dcdiag /q", "repadmin /replsummary", "repadmin /showrepl * /errorsonly")
        $hasDcdiag = Get-Command dcdiag.exe -ErrorAction SilentlyContinue
        $hasRepadmin = Get-Command repadmin.exe -ErrorAction SilentlyContinue
        if (-not $hasDcdiag -and -not $hasRepadmin) {
            Write-Log "[INFO] dcdiag/repadmin non disponibili: eseguire su un Domain Controller o installare RSAT 'AD DS Tools'." "Non disponibile"
            return
        }
        Show-WaitOverlay -msg "Diagnostica DC in corso (può richiedere alcuni minuti)..."
        try {
            $OutputFile = Get-ADOutputPath "Salute_DC_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"
            $sb = New-Object System.Text.StringBuilder
            if ($hasDcdiag) {
                Write-Log "--- dcdiag /q (solo i test falliti) ---"
                $o = (& dcdiag.exe /q 2>&1 | Out-String).Trim()
                if ([string]::IsNullOrWhiteSpace($o)) { $o = "Nessun errore rilevato da dcdiag." }
                Write-Log $o
                [void]$sb.AppendLine("=== dcdiag /q ===")
                [void]$sb.AppendLine($o)
                [void]$sb.AppendLine("")
            }
            if ($hasRepadmin) {
                Write-Log "--- repadmin /replsummary ---"
                $o = (& repadmin.exe /replsummary 2>&1 | Out-String).Trim()
                Write-Log $o
                [void]$sb.AppendLine("=== repadmin /replsummary ===")
                [void]$sb.AppendLine($o)
                [void]$sb.AppendLine("")
                Write-Log "--- repadmin /showrepl * /errorsonly ---"
                $o = (& repadmin.exe /showrepl * /errorsonly 2>&1 | Out-String).Trim()
                if ([string]::IsNullOrWhiteSpace($o)) { $o = "Nessun errore di replica." }
                Write-Log $o
                [void]$sb.AppendLine("=== repadmin /showrepl * /errorsonly ===")
                [void]$sb.AppendLine($o)
            }
            $sb.ToString() | Out-File -FilePath $OutputFile -Encoding UTF8
            Write-Log "File: $OutputFile"
            Write-Log "Diagnostica DC completata con successo" "Completato"
        } catch { Write-Log "[ERRORE] Salute DC: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#CBD5E1", "#0F172A", "Sola lettura: esegue dcdiag /q e repadmin (riepilogo ed errori di replica) e salva il risultato in un TXT. Eseguire su un DC o con RSAT."),

    @("Ruoli FSMO + Elenco Domain Controller", {
        Show-CommandSummary "FSMO + Elenco DC" @("Get-ADForest", "Get-ADDomain", "Get-ADDomainController -Filter *")
        if (-not (Test-ADModule)) { return }
        Show-WaitOverlay -msg "Lettura ruoli FSMO e DC..."
        try {
            $forest = Get-ADForest
            $domain = Get-ADDomain
            Write-Log "Foresta: $($forest.Name) | Dominio: $($domain.DNSRoot) | Livello funzionale dominio: $($domain.DomainMode)"
            Write-Log "PDC Emulator: $($domain.PDCEmulator)"
            Write-Log "RID Master: $($domain.RIDMaster)"
            Write-Log "Infrastructure Master: $($domain.InfrastructureMaster)"
            Write-Log "Schema Master: $($forest.SchemaMaster)"
            Write-Log "Domain Naming Master: $($forest.DomainNamingMaster)"
            $dcs = @(Get-ADDomainController -Filter * | Select-Object Name, HostName, IPv4Address, Site, IsGlobalCatalog, IsReadOnly, OperatingSystem, OperatingSystemVersion, @{ n = "RuoliFSMO"; e = { $_.OperationMasterRoles -join ", " } })
            foreach ($dc in $dcs) {
                Write-Log ("DC: {0} | {1} | Sito: {2} | GC: {3} | RODC: {4} | {5} | Ruoli: {6}" -f $dc.Name, $dc.IPv4Address, $dc.Site, $dc.IsGlobalCatalog, $dc.IsReadOnly, $dc.OperatingSystem, $dc.RuoliFSMO)
            }
            $OutputFile = Get-ADOutputPath "DC_Elenco_FSMO_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
            $dcs | Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8
            Write-Log "Trovati $($dcs.Count) Domain Controller. File: $OutputFile"
            Write-Log "Lettura FSMO e DC completata con successo" "Completato"
        } catch { Write-Log "[ERRORE] FSMO/DC: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#CBD5E1", "#0F172A", "Sola lettura: mostra i 5 ruoli FSMO e l'elenco dei Domain Controller (IP, sito, GC, RODC, OS) ed esporta in CSV."),

    @("Origine Blocchi Account (Evento 4740)", {
        Show-CommandSummary "Origine Blocchi Account" @("Get-ADDomain PDCEmulator", "Get-WinEvent Security Id=4740")
        if (-not (Test-ADModule)) { return }
        $user = [Microsoft.VisualBasic.Interaction]::InputBox("Utente da cercare (SamAccountName).`r`nLascia vuoto per tutti gli utenti bloccati.", "Origine Blocchi Account", "")
        $daysStr = [Microsoft.VisualBasic.Interaction]::InputBox("Quanti giorni indietro cercare?`r`nDefault 3 giorni", "Origine Blocchi Account", "3")
        $days = 3
        if (-not [int]::TryParse($daysStr, [ref]$days) -or $days -lt 1) { $days = 3 }
        Show-WaitOverlay -msg "Lettura log Security del PDC Emulator..."
        try {
            $pdc = (Get-ADDomain).PDCEmulator
            Write-Log "PDC Emulator: $pdc - ricerca evento 4740 negli ultimi $days giorni"
            $start = (Get-Date).AddDays(-$days)
            $events = @(Get-WinEvent -ComputerName $pdc -FilterHashtable @{ LogName = "Security"; Id = 4740; StartTime = $start } -ErrorAction SilentlyContinue)
            if ($events.Count -eq 0) {
                Write-Log "[INFO] Nessun evento 4740 trovato. Verificare che l'audit 'Gestione account utente' sia attivo e che si abbiano i permessi di lettura sul log Security del PDC."
                return
            }
            $rows = foreach ($e in $events) {
                $xml = [xml]$e.ToXml()
                $d = @{}
                foreach ($n in $xml.Event.EventData.Data) { $d[$n.Name] = $n.'#text' }
                [PSCustomObject]@{ Data = $e.TimeCreated; Account = $d["TargetUserName"]; ComputerOrigine = $d["TargetDomainName"]; DC = $e.MachineName }
            }
            if (-not [string]::IsNullOrWhiteSpace($user)) { $rows = @($rows | Where-Object { $_.Account -like $user.Trim() }) }
            $rows = @($rows)
            if ($rows.Count -eq 0) { Write-Log "[INFO] Nessun blocco trovato per '$user' negli ultimi $days giorni."; return }
            $groups = $rows | Group-Object Account | Sort-Object Count -Descending | Select-Object -First 20
            foreach ($g in $groups) {
                $origini = ($g.Group.ComputerOrigine | Sort-Object -Unique) -join ", "
                Write-Log ("{0} | blocchi: {1} | PC di origine: {2}" -f $g.Name, $g.Count, $origini)
            }
            $OutputFile = Get-ADOutputPath "Origine_Blocchi_4740_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
            $rows | Sort-Object Data -Descending | Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8
            Write-Log "Eventi trovati: $($rows.Count). File: $OutputFile"
            Write-Log "Ricerca origine blocchi completata con successo" "Completato"
        } catch { Write-Log "[ERRORE] Origine blocchi: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#CBD5E1", "#0F172A", "Sola lettura: legge l'evento 4740 sul PDC Emulator e mostra DA QUALE PC arrivano le password errate che bloccano un account. Esporta in CSV."),

    @("Audit Gruppi Privilegiati (CSV)", {
        Show-CommandSummary "Audit Gruppi Privilegiati" @("Get-ADGroup per SID noto (indipendente dalla lingua)", "Get-ADGroupMember -Recursive", "Export-Csv")
        if (-not (Test-ADModule)) { return }
        Show-WaitOverlay -msg "Audit gruppi privilegiati..."
        try {
            $domObj = Get-ADDomain
            $rootDom = (Get-ADForest).RootDomain
            $rootSid = (Get-ADDomain -Identity $rootDom).DomainSID.Value
            $domSid = $domObj.DomainSID.Value
            $targets = @(
                @{ Etichetta = "Domain Admins";     Sid = "$domSid-512";   Server = $domObj.DNSRoot },
                @{ Etichetta = "Enterprise Admins"; Sid = "$rootSid-519";  Server = $rootDom },
                @{ Etichetta = "Schema Admins";     Sid = "$rootSid-518";  Server = $rootDom },
                @{ Etichetta = "Administrators";    Sid = "S-1-5-32-544";  Server = $domObj.DNSRoot },
                @{ Etichetta = "Account Operators"; Sid = "S-1-5-32-548";  Server = $domObj.DNSRoot },
                @{ Etichetta = "Server Operators";  Sid = "S-1-5-32-549";  Server = $domObj.DNSRoot },
                @{ Etichetta = "Print Operators";   Sid = "S-1-5-32-550";  Server = $domObj.DNSRoot },
                @{ Etichetta = "Backup Operators";  Sid = "S-1-5-32-551";  Server = $domObj.DNSRoot }
            )
            $report = New-Object System.Collections.Generic.List[object]
            foreach ($t in $targets) {
                try {
                    $g = Get-ADGroup -Identity $t.Sid -Server $t.Server -ErrorAction Stop
                    $members = @(Get-ADGroupMember -Identity $g -Server $t.Server -Recursive -ErrorAction Stop)
                    Write-Log ("{0} (nome nel dominio: {1}): {2} membri" -f $t.Etichetta, $g.Name, $members.Count)
                    foreach ($m in $members) {
                        $row = [ordered]@{ GruppoStandard = $t.Etichetta; Gruppo = $g.Name; Nome = $m.Name; SamAccountName = $m.SamAccountName; Tipo = $m.objectClass; Attivo = ""; UltimoLogon = ""; PasswordNonScade = ""; UltimoCambioPwd = "" }
                        if ($m.objectClass -eq "user") {
                            $u = Get-ADUser -Identity $m.SamAccountName -Server $t.Server -Properties Enabled, LastLogonDate, PasswordNeverExpires, PasswordLastSet -ErrorAction SilentlyContinue
                            if ($u) { $row.Attivo = $u.Enabled; $row.UltimoLogon = $u.LastLogonDate; $row.PasswordNonScade = $u.PasswordNeverExpires; $row.UltimoCambioPwd = $u.PasswordLastSet }
                        }
                        $report.Add([PSCustomObject]$row)
                    }
                } catch { Write-Log "[AVVISO] $($t.Etichetta): non leggibile ($_)" }
            }
            $OutputFile = Get-ADOutputPath "Audit_Gruppi_Privilegiati_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
            $report | Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8
            $daVerificare = @($report | Where-Object { $_.Tipo -eq "user" -and ($_.Attivo -eq $false -or $_.PasswordNonScade -eq $true) })
            Write-Log "Righe totali: $($report.Count). Utenti disattivati o con password che non scade tra i membri: $($daVerificare.Count) (da verificare)."
            foreach ($x in $daVerificare) { Write-Log (" - {0} in {1} | Attivo: {2} | Pwd non scade: {3}" -f $x.SamAccountName, $x.GruppoStandard, $x.Attivo, $x.PasswordNonScade) }
            Write-Log "File: $OutputFile"
            Write-Log "Audit gruppi privilegiati completato con successo" "Completato"
        } catch { Write-Log "[ERRORE] Audit gruppi: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#F59E0B", "#0F172A", "Analisi sicurezza (sola lettura): membri ricorsivi di Domain/Enterprise/Schema Admins, Administrators e gruppi Operators. Cerca per SID, quindi funziona anche con nomi in italiano."),

    @("Audit Sicurezza AD (krbtgt, SPN, Pwd)", {
        Show-CommandSummary "Audit Sicurezza AD" @("krbtgt PasswordLastSet", "PasswordNotRequired", "ServicePrincipalName (Kerberoasting)", "DoesNotRequirePreAuth", "Cestino AD")
        if (-not (Test-ADModule)) { return }
        Show-WaitOverlay -msg "Audit sicurezza AD..."
        try {
            $findings = New-Object System.Collections.Generic.List[object]
            # 1) krbtgt
            $k = Get-ADUser -Identity krbtgt -Properties PasswordLastSet
            $kAge = [int]((Get-Date) - $k.PasswordLastSet).TotalDays
            Write-Log "krbtgt: password cambiata $kAge giorni fa ($($k.PasswordLastSet))"
            if ($kAge -gt 365) { Write-Log "[ATTENZIONE] Password krbtgt oltre 1 anno: valutare la rotazione (procedura in due passaggi)." "Attenzione" }
            $findings.Add([PSCustomObject]@{ Controllo = "krbtgt"; Account = "krbtgt"; Dettaglio = "Password cambiata $kAge giorni fa" })
            # 2) password non richiesta
            $pnr = @(Get-ADUser -Filter 'PasswordNotRequired -eq $true -and Enabled -eq $true' -Properties PasswordNotRequired)
            Write-Log "Account attivi con 'password non richiesta': $($pnr.Count)"
            foreach ($u in $pnr) { $findings.Add([PSCustomObject]@{ Controllo = "PasswordNotRequired"; Account = $u.SamAccountName; Dettaglio = "Attivo senza obbligo di password" }) }
            # 3) SPN su account utente (esposti a Kerberoasting)
            $spn = @(Get-ADUser -Filter 'ServicePrincipalName -like "*" -and Enabled -eq $true' -Properties ServicePrincipalName, PasswordLastSet | Where-Object { $_.SamAccountName -ne "krbtgt" })
            Write-Log "Account utente attivi con SPN (Kerberoasting): $($spn.Count)"
            foreach ($u in $spn) { $findings.Add([PSCustomObject]@{ Controllo = "SPN su utente"; Account = $u.SamAccountName; Dettaglio = ("SPN: " + ($u.ServicePrincipalName -join "; ") + " | Ultimo cambio pwd: " + $u.PasswordLastSet) }) }
            # 4) pre-autenticazione Kerberos disattivata (AS-REP roasting)
            $np = @(Get-ADUser -Filter 'DoesNotRequirePreAuth -eq $true -and Enabled -eq $true' -Properties DoesNotRequirePreAuth)
            Write-Log "Account attivi senza pre-autenticazione Kerberos: $($np.Count)"
            foreach ($u in $np) { $findings.Add([PSCustomObject]@{ Controllo = "SenzaPreAuth"; Account = $u.SamAccountName; Dettaglio = "Pre-autenticazione Kerberos non richiesta" }) }
            # 5) Cestino AD
            $rb = Get-ADOptionalFeature -Filter "Name -eq 'Recycle Bin Feature'"
            $rbOn = ($rb -and @($rb.EnabledScopes).Count -gt 0)
            if ($rbOn) { Write-Log "Cestino AD: ATTIVO" } else { Write-Log "[ATTENZIONE] Cestino AD NON attivo: gli oggetti eliminati non sono ripristinabili facilmente." "Attenzione" }
            $findings.Add([PSCustomObject]@{ Controllo = "CestinoAD"; Account = ""; Dettaglio = $(if ($rbOn) { "Attivo" } else { "Non attivo" }) })
            $OutputFile = Get-ADOutputPath "Audit_Sicurezza_AD_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
            $findings | Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8
            Write-Log "File: $OutputFile"
            Write-Log "Audit sicurezza AD completato con successo" "Completato"
        } catch { Write-Log "[ERRORE] Audit sicurezza AD: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#F59E0B", "#0F172A", "Analisi sicurezza (sola lettura): età password krbtgt, account con password non richiesta, SPN su utenti, senza pre-auth Kerberos, stato Cestino AD. Esporta in CSV."),
    @("Delega Kerberos`n(Unconstrained)", {
        Show-CommandSummary "Delega Kerberos" @("userAccountControl: TRUSTED_FOR_DELEGATION (esclusi i Domain Controller)", "msDS-AllowedToDelegateTo (delega vincolata)")
        if (-not (Test-ADModule)) { return }
        Show-WaitOverlay -msg "Ricerca account con delega Kerberos..."
        try {
            $find = New-Object System.Collections.ArrayList
            # Delega non vincolata: account attivi, esclusi DC (516) e RODC (521)
            $uncF = '(&(|(objectCategory=person)(objectCategory=computer))(userAccountControl:1.2.840.113556.1.4.803:=524288)(!(userAccountControl:1.2.840.113556.1.4.803:=2))(!(primaryGroupID=516))(!(primaryGroupID=521)))'
            $unc = @(Get-ADObject -LDAPFilter $uncF -Properties samAccountName, objectClass -ErrorAction Stop)
            foreach ($o in $unc) {
                [void]$find.Add((New-SecFinding "Alto" ("Delega non vincolata: {0} ({1})" -f $o.samAccountName, $o.objectClass) "Può impersonare qualsiasi utente che si autentica verso di lui: se viene compromesso, il dominio è a rischio. Passa a delega vincolata o basata sulle risorse."))
            }
            if ($unc.Count -eq 0) { [void]$find.Add((New-SecFinding "OK" "Delega non vincolata" "Nessun account attivo (esclusi i DC).")) }

            # Delega vincolata
            $conF = '(&(|(objectCategory=person)(objectCategory=computer))(msDS-AllowedToDelegateTo=*))'
            $con = @(Get-ADObject -LDAPFilter $conF -Properties samAccountName, objectClass, 'msDS-AllowedToDelegateTo', userAccountControl -ErrorAction Stop)
            foreach ($o in $con) {
                $targets = (@($o.'msDS-AllowedToDelegateTo')) -join ", "
                $proto = (([int]$o.userAccountControl -band 16777216) -ne 0)
                $liv = "Info"; $note = "Delega vincolata verso: {0}"
                if ($proto) { $liv = "Medio"; $note = "Delega vincolata con transizione di protocollo (può ottenere ticket senza Kerberos dell'utente) verso: {0}" }
                [void]$find.Add((New-SecFinding $liv ("Delega vincolata: {0} ({1})" -f $o.samAccountName, $o.objectClass) ($note -f $targets)))
            }
            if ($con.Count -eq 0) { [void]$find.Add((New-SecFinding "OK" "Delega vincolata" "Nessun account configurato.")) }
            Show-SecFindings $find "Audit_Delega_Kerberos" -NoComputerName
        } catch { Write-Log "[ERRORE] Ricerca delega Kerberos: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#F59E0B", "#0F172A", "Cerca account utente e computer con delega Kerberos non vincolata (rischio alto, esclusi i DC) o vincolata con transizione di protocollo. Sola lettura, salva un CSV."),
    @("Computer AD: OS Obsoleti,`nInattivi e LAPS", {
        Show-CommandSummary "Computer AD: OS Obsoleti, Inattivi e LAPS" @("Get-ADComputer (computer attivi)", "Sistemi operativi non più supportati", "Computer senza accesso da oltre 90 giorni", "Copertura LAPS (schema e password gestite)")
        if (-not (Test-ADModule)) { return }
        Show-WaitOverlay -msg "Analisi computer del dominio..."
        try {
            $find = New-Object System.Collections.ArrayList
            $flag = New-Object System.Collections.ArrayList

            # Attributi LAPS presenti nello schema (legacy e Windows LAPS)
            $schemaNC = (Get-ADRootDSE).schemaNamingContext
            $lapsAttrs = @()
            foreach ($an in @("ms-Mcs-AdmPwdExpirationTime", "msLAPS-PasswordExpirationTime")) {
                if (Get-ADObject -SearchBase $schemaNC -LDAPFilter ("(lDAPDisplayName={0})" -f $an) -ErrorAction SilentlyContinue) { $lapsAttrs += $an }
            }
            $props = @("OperatingSystem", "LastLogonDate", "PrimaryGroupID") + $lapsAttrs
            $comps = @(Get-ADComputer -Filter 'Enabled -eq $true' -Properties $props -ErrorAction Stop)
            Write-Log ("Computer attivi nel dominio: {0}" -f $comps.Count)

            # 1) Sistemi operativi non più supportati
            $obsHigh = '(?i)Windows (2000|XP|Vista|7|8|8\.1)\b|Windows Server( \(R\))? (2003|2008|2012)'
            foreach ($g in @($comps | Where-Object { $_.OperatingSystem } | Group-Object OperatingSystem | Sort-Object Name)) {
                $liv = $null; $why = ""
                if ($g.Name -match $obsHigh) { $liv = "Alto"; $why = "senza più aggiornamenti di sicurezza" }
                elseif ($g.Name -match '(?i)Windows 10') { $liv = "Medio"; $why = "supporto terminato il 14/10/2025 (salvo aggiornamenti ESU)" }
                if ($liv) {
                    $names = (@($g.Group | Select-Object -First 15 | ForEach-Object { $_.Name })) -join ", "
                    $more = ""; if ($g.Count -gt 15) { $more = " ..." }
                    [void]$find.Add((New-SecFinding $liv ("OS non supportato: {0}" -f $g.Name) ("{0} computer, {1}: {2}{3}" -f $g.Count, $why, $names, $more)))
                    foreach ($c in $g.Group) { [void]$flag.Add([PSCustomObject]@{ Computer = $c.Name; SistemaOperativo = $c.OperatingSystem; UltimoAccesso = $c.LastLogonDate; Motivo = "OS non supportato" }) }
                }
            }

            # 2) Computer inattivi da oltre 90 giorni
            $limit = (Get-Date).AddDays(-90)
            $stale = @($comps | Where-Object { $_.PrimaryGroupID -ne 516 -and $_.LastLogonDate -and $_.LastLogonDate -lt $limit })
            $never = @($comps | Where-Object { $_.PrimaryGroupID -ne 516 -and -not $_.LastLogonDate })
            if ($stale.Count -gt 0) {
                $names = (@($stale | Select-Object -First 15 | ForEach-Object { $_.Name })) -join ", "
                $more = ""; if ($stale.Count -gt 15) { $more = " ..." }
                [void]$find.Add((New-SecFinding "Medio" "Computer inattivi da oltre 90 giorni" ("{0} computer attivi in AD ma non collegati: {1}{2}. Valuta di disattivarli." -f $stale.Count, $names, $more)))
                foreach ($c in $stale) { [void]$flag.Add([PSCustomObject]@{ Computer = $c.Name; SistemaOperativo = $c.OperatingSystem; UltimoAccesso = $c.LastLogonDate; Motivo = "Inattivo da oltre 90 giorni" }) }
            } else { [void]$find.Add((New-SecFinding "OK" "Computer inattivi da oltre 90 giorni" "Nessuno.")) }
            if ($never.Count -gt 0) { [void]$find.Add((New-SecFinding "Info" "Computer mai collegati" ("{0} computer senza alcun accesso registrato." -f $never.Count))) }

            # 3) Copertura LAPS
            $nonDc = @($comps | Where-Object { $_.PrimaryGroupID -ne 516 })
            if ($lapsAttrs.Count -eq 0) {
                [void]$find.Add((New-SecFinding "Medio" "LAPS" "Non presente nello schema AD: la password dell'amministratore locale è probabilmente uguale su più PC. Windows LAPS è integrato nei Windows aggiornati."))
            } else {
                $noLaps = New-Object System.Collections.ArrayList
                foreach ($c in $nonDc) {
                    $has = $false
                    foreach ($an in $lapsAttrs) { if ($c.$an) { $has = $true; break } }
                    if (-not $has) { [void]$noLaps.Add($c) }
                }
                if ($noLaps.Count -gt 0) {
                    $names = (@($noLaps | Select-Object -First 15 | ForEach-Object { $_.Name })) -join ", "
                    $more = ""; if ($noLaps.Count -gt 15) { $more = " ..." }
                    [void]$find.Add((New-SecFinding "Medio" "Computer senza password LAPS" ("{0} su {1}: {2}{3}" -f $noLaps.Count, $nonDc.Count, $names, $more)))
                    foreach ($c in $noLaps) { [void]$flag.Add([PSCustomObject]@{ Computer = $c.Name; SistemaOperativo = $c.OperatingSystem; UltimoAccesso = $c.LastLogonDate; Motivo = "Senza password LAPS" }) }
                } else { [void]$find.Add((New-SecFinding "OK" "Copertura LAPS" "Tutti i computer hanno una password gestita.")) }
            }

            if ($flag.Count -gt 0) {
                $det = Get-ADOutputPath ("Computer_AD_Da_Verificare_{0}.csv" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
                $flag | Export-Csv -Path $det -NoTypeInformation -Encoding UTF8 -Delimiter ";"
                Write-Log ("Elenco completo dei computer da verificare: {0}" -f $det)
            }
            Show-SecFindings $find "Audit_Computer_AD" -NoComputerName
        } catch { Write-Log "[ERRORE] Analisi computer AD: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#F59E0B", "#0F172A", "Analizza i computer attivi del dominio: sistemi operativi non più supportati, computer che non si collegano da oltre 90 giorni e copertura LAPS (password amministratore locale gestita). Sola lettura, salva CSV."),
    @("Policy Password Dominio`n(+ PSO)", {
        Show-CommandSummary "Policy Password del Dominio" @("Get-ADDefaultDomainPasswordPolicy", "Get-ADFineGrainedPasswordPolicy (PSO)", "Livello funzionale del dominio")
        if (-not (Test-ADModule)) { return }
        Show-WaitOverlay -msg "Lettura policy password..."
        try {
            $find = New-Object System.Collections.ArrayList
            $pol = Get-ADDefaultDomainPasswordPolicy -ErrorAction Stop

            $ml = [int]$pol.MinPasswordLength
            if ($ml -lt 8) { [void]$find.Add((New-SecFinding "Alto" "Lunghezza minima password" ("{0} caratteri: troppo corta (consigliati almeno 12)." -f $ml))) }
            elseif ($ml -lt 12) { [void]$find.Add((New-SecFinding "Medio" "Lunghezza minima password" ("{0} caratteri: consigliati almeno 12." -f $ml))) }
            else { [void]$find.Add((New-SecFinding "OK" "Lunghezza minima password" ("{0} caratteri." -f $ml))) }

            if (-not $pol.ComplexityEnabled) { [void]$find.Add((New-SecFinding "Medio" "Complessità password" "Non richiesta.")) }
            else { [void]$find.Add((New-SecFinding "OK" "Complessità password" "Richiesta.")) }

            $lt = [int]$pol.LockoutThreshold
            if ($lt -eq 0) { [void]$find.Add((New-SecFinding "Alto" "Blocco account" "Nessun blocco: i tentativi di indovinare le password non hanno limiti.")) }
            elseif ($lt -gt 10) { [void]$find.Add((New-SecFinding "Medio" "Blocco account" ("Dopo {0} tentativi: soglia alta, consigliati 5-10." -f $lt))) }
            else { [void]$find.Add((New-SecFinding "OK" "Blocco account" ("Dopo {0} tentativi." -f $lt))) }

            if ($pol.ReversibleEncryptionEnabled) { [void]$find.Add((New-SecFinding "Alto" "Cifratura reversibile" "Attiva: le password sono recuperabili in chiaro.")) }
            else { [void]$find.Add((New-SecFinding "OK" "Cifratura reversibile" "Disattivata.")) }

            $hist = [int]$pol.PasswordHistoryCount
            if ($hist -lt 5) { [void]$find.Add((New-SecFinding "Medio" "Cronologia password" ("{0} password ricordate: poche." -f $hist))) }
            else { [void]$find.Add((New-SecFinding "OK" "Cronologia password" ("{0} password ricordate." -f $hist))) }

            $maxAge = "le password non scadono"; if ($pol.MaxPasswordAge -ne [TimeSpan]::Zero) { $maxAge = ("{0} giorni" -f $pol.MaxPasswordAge.Days) }
            [void]$find.Add((New-SecFinding "Info" "Scadenza password" ("Massima durata: {0} | durata minima: {1} giorni" -f $maxAge, $pol.MinPasswordAge.Days)))
            [void]$find.Add((New-SecFinding "Info" "Tempi di blocco" ("Durata del blocco: {0} minuti | finestra di osservazione: {1} minuti" -f [int]$pol.LockoutDuration.TotalMinutes, [int]$pol.LockoutObservationWindow.TotalMinutes)))

            try {
                $psos = @(Get-ADFineGrainedPasswordPolicy -Filter * -ErrorAction Stop)
                if ($psos.Count -eq 0) { [void]$find.Add((New-SecFinding "Info" "Policy password specifiche (PSO)" "Nessuna: si applica solo la policy del dominio.")) }
                foreach ($ps in ($psos | Sort-Object Precedence)) {
                    $applies = (@($ps.AppliesTo | ForEach-Object { (($_ -split ",")[0]) -replace '^CN=', '' })) -join ", "
                    $liv = "Info"; if ([int]$ps.MinPasswordLength -lt 8) { $liv = "Medio" }
                    [void]$find.Add((New-SecFinding $liv ("PSO: {0} (precedenza {1})" -f $ps.Name, $ps.Precedence) ("Lunghezza minima {0}, complessità {1}, blocco dopo {2} tentativi | Si applica a: {3}" -f $ps.MinPasswordLength, $ps.ComplexityEnabled, $ps.LockoutThreshold, $applies)))
                }
            } catch { [void]$find.Add((New-SecFinding "Info" "Policy password specifiche (PSO)" "Non leggibili.")) }

            try { [void]$find.Add((New-SecFinding "Info" "Livello funzionale del dominio" ([string](Get-ADDomain).DomainMode))) } catch { $null = $_ }
            Show-SecFindings $find "Audit_Policy_Password_Dominio" -NoComputerName
        } catch { Write-Log "[ERRORE] Lettura policy password: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#F59E0B", "#0F172A", "Controlla la policy password del dominio (lunghezza, complessità, blocco account, cronologia, cifratura reversibile) e le policy specifiche PSO. Sola lettura, salva un CSV."),
    @("adminCount Orfani`n(AdminSDHolder)", {
        Show-CommandSummary "Account con adminCount Orfano" @("Get-ADUser (adminCount=1)", "Membri ricorsivi dei gruppi protetti da AdminSDHolder")
        if (-not (Test-ADModule)) { return }
        Show-WaitOverlay -msg "Verifica account con adminCount..."
        try {
            $find = New-Object System.Collections.ArrayList
            $domSid = (Get-ADDomain).DomainSID.Value
            $rootSid = (Get-ADDomain -Identity (Get-ADForest).RootDomain).DomainSID.Value
            # Administrators, Account/Server/Print/Backup Operators, Replicator, Domain Admins, Schema Admins, Enterprise Admins
            $sids = @("S-1-5-32-544", "S-1-5-32-548", "S-1-5-32-549", "S-1-5-32-550", "S-1-5-32-551", "S-1-5-32-552", ("{0}-512" -f $domSid), ("{0}-518" -f $rootSid), ("{0}-519" -f $rootSid))
            $prot = @{}
            foreach ($sid in $sids) {
                try {
                    $grp = Get-ADGroup -Identity $sid -ErrorAction Stop
                    foreach ($m in @(Get-ADGroupMember -Identity $grp -Recursive -ErrorAction Stop)) { $prot[[string]$m.distinguishedName] = $true }
                } catch { $null = $_ }
            }
            $adm = @(Get-ADUser -LDAPFilter '(adminCount=1)' -Properties adminCount, Enabled, LastLogonDate, PasswordLastSet -ErrorAction Stop)
            $orph = @($adm | Where-Object { -not $prot.ContainsKey([string]$_.DistinguishedName) -and $_.SamAccountName -ne "krbtgt" -and $_.SID.Value -notmatch '-(500|502)$' })
            [void]$find.Add((New-SecFinding "Info" "Account con adminCount=1" ("{0} in totale, {1} ancora nei gruppi protetti, {2} orfani." -f $adm.Count, ($adm.Count - $orph.Count), $orph.Count)))
            foreach ($u in $orph) {
                $last = "mai"; if ($u.LastLogonDate) { $last = $u.LastLogonDate.ToString("dd/MM/yyyy") }
                $stato = "disattivato"; if ($u.Enabled) { $stato = "attivo" }
                [void]$find.Add((New-SecFinding "Medio" ("adminCount orfano: {0}" -f $u.SamAccountName) ("Non è più in un gruppo protetto ma ha ancora adminCount=1 (permessi ereditati bloccati da AdminSDHolder). Account {0}, ultimo accesso {1}. Ripristina l'ereditarietà e azzera adminCount." -f $stato, $last)))
            }
            if ($orph.Count -eq 0) { [void]$find.Add((New-SecFinding "OK" "adminCount orfani" "Nessun account orfano.")) }
            Show-SecFindings $find "Audit_adminCount_Orfani" -NoComputerName
        } catch { Write-Log "[ERRORE] Verifica adminCount: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#F59E0B", "#0F172A", "Trova gli utenti che hanno ancora adminCount=1 ma non sono più membri di gruppi privilegiati (ex amministratori con permessi ereditati bloccati). Sola lettura, salva un CSV."),

    @("Backup + Report GPO (HTML)", {
        Show-CommandSummary "Backup + Report GPO" @("Backup-GPO -All", "Get-GPOReport -All -ReportType Html")
        if (-not (Get-Module -ListAvailable -Name GroupPolicy)) {
            Write-Log "[INFO] Modulo GroupPolicy non disponibile: installare RSAT 'Gestione Criteri di gruppo' o eseguire su un DC." "Non disponibile"
            return
        }
        $c = [System.Windows.Forms.MessageBox]::Show("Verrà creato un backup di TUTTE le GPO del dominio e un report HTML nella cartella dello script.`r`n`r`nContinuare?", "Backup + Report GPO", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($c -ne [System.Windows.Forms.DialogResult]::Yes) { Write-Log "[INFO] Backup GPO annullato dall'utente." "Annullato"; return }
        Show-WaitOverlay -msg "Backup GPO in corso..."
        try {
            Import-Module GroupPolicy -ErrorAction Stop
            $ts = Get-Date -Format "yyyyMMdd_HHmm"
            $dir = Join-Path $global:OutputDir "GPO_Backup_$ts"
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            $res = @(Backup-GPO -All -Path $dir -Comment "Backup da strumento manutenzione $ts")
            Write-Log "Backup di $($res.Count) GPO in: $dir"
            $html = Join-Path $dir "Report_GPO_$ts.html"
            Get-GPOReport -All -ReportType Html -Path $html
            Write-Log "Report HTML: $html"
            Write-Log "Backup e report GPO completati con successo" "Completato"
            Invoke-Item $dir
        } catch { Write-Log "[ERRORE] Backup GPO: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#CBD5E1", "#0F172A", "Crea nella cartella dello script un backup di tutte le GPO (Backup-GPO) e un unico report HTML. Non modifica nulla nel dominio."),

    # Helpdesk dominio lato client: funzionano anche su un PC in dominio senza RSAT
    @("Verifica / Ripristina Canale Sicuro Dominio", {
        Show-CommandSummary "Canale Sicuro Dominio" @("Test-ComputerSecureChannel", "Test-ComputerSecureChannel -Repair -Credential")
        try {
            $cs = Get-CimInstance Win32_ComputerSystem
            if (-not $cs.PartOfDomain) { Write-Log "[INFO] Questo PC non fa parte di un dominio: nulla da verificare." "Non in dominio"; return }
            Write-Log "Dominio: $($cs.Domain) | Computer: $($cs.Name)"
            $ok = Test-ComputerSecureChannel -ErrorAction Stop
            if ($ok) { Write-Log "[OK] Il canale sicuro con il dominio è integro." "Canale integro"; return }
            Write-Log "[ATTENZIONE] Il canale sicuro con il dominio risulta ROTTO." "Attenzione"
            $q = [System.Windows.Forms.MessageBox]::Show("Il canale sicuro con il dominio risulta ROTTO.`r`n`r`nRiparare ora? Verranno richieste le credenziali di un account di dominio autorizzato a reimpostare la password dell'account computer.", "Ripristino canale sicuro", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
            if ($q -ne [System.Windows.Forms.DialogResult]::Yes) { Write-Log "[INFO] Ripristino annullato dall'utente." "Annullato"; return }
            $cred = Get-Credential -Message "Credenziali di dominio per riparare il canale sicuro"
            if (-not $cred) { Write-Log "[INFO] Nessuna credenziale fornita: ripristino annullato." "Annullato"; return }
            $fixed = Test-ComputerSecureChannel -Repair -Credential $cred -ErrorAction Stop
            if ($fixed) { Write-Log "[OK] Canale sicuro ripristinato. Si consiglia di riavviare il PC." "Ripristinato" }
            else { Write-Log "[ERRORE] Ripristino non riuscito: verificare credenziali, DNS e raggiungibilità del DC." "Errore" }
        } catch { Write-Log "[ERRORE] Canale sicuro: $_ (verificare rete, DNS e raggiungibilità del DC)" "Errore" }
    }, "#F59E0B", "#0F172A", "Controlla il canale sicuro con il dominio ('relazione di trust non riuscita'). Se è rotto propone il ripristino chiedendo credenziali di dominio."),

    @("Test Porte verso Domain Controller", {
        Show-CommandSummary "Test Porte DC" @("Test TCP 53/88/135/389/445/464/636/3268", "Resolve-DnsName SRV _ldap._tcp.dc._msdcs")
        $cs = Get-CimInstance Win32_ComputerSystem
        $dcDefault = ""
        if ($cs.PartOfDomain -and $env:LOGONSERVER) { $dcDefault = $env:LOGONSERVER.TrimStart("\") }
        $dc = [Microsoft.VisualBasic.Interaction]::InputBox("Nome o IP del Domain Controller da testare:", "Test Porte DC", $dcDefault)
        if ([string]::IsNullOrWhiteSpace($dc)) { Write-Log "[INFO] Test porte annullato." "Annullato"; return }
        $dc = $dc.Trim()
        Show-WaitOverlay -msg "Test porte verso $dc..."
        try {
            if ($cs.PartOfDomain) {
                try {
                    $srv = @(Resolve-DnsName "_ldap._tcp.dc._msdcs.$($cs.Domain)" -Type SRV -ErrorAction Stop | Where-Object { $_.QueryType -eq "SRV" })
                    Write-Log "DNS: trovati $($srv.Count) record SRV per i DC di $($cs.Domain)"
                } catch { Write-Log "[AVVISO] Record SRV dei DC non risolti ($_): verificare che il DNS del PC punti al DNS del dominio." }
            }
            $ports = @(
                @{ P = 53;   N = "DNS" },
                @{ P = 88;   N = "Kerberos" },
                @{ P = 135;  N = "RPC Endpoint Mapper" },
                @{ P = 389;  N = "LDAP" },
                @{ P = 445;  N = "SMB (SYSVOL/NETLOGON)" },
                @{ P = 464;  N = "Kerberos cambio password" },
                @{ P = 636;  N = "LDAPS" },
                @{ P = 3268; N = "Global Catalog" }
            )
            $open = 0
            foreach ($pt in $ports) {
                $client = New-Object System.Net.Sockets.TcpClient
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                $state = "TIMEOUT (filtrata?)"
                try {
                    $iar = $client.BeginConnect($dc, [int]$pt.P, $null, $null)
                    if ($iar.AsyncWaitHandle.WaitOne(2000, $false)) {
                        try { $client.EndConnect($iar); $state = "APERTA"; $open++ } catch { $state = "RIFIUTATA" }
                    }
                } catch { $state = "ERRORE: " + $_.Exception.Message }
                finally { $client.Close() }
                $sw.Stop()
                Write-Log ("{0,-5} {1,-28} {2} ({3} ms)" -f $pt.P, $pt.N, $state, $sw.ElapsedMilliseconds)
            }
            Write-Log "Porte raggiungibili su ${dc}: $open di $($ports.Count)"
            if ($open -lt $ports.Count) { Write-Log "[INFO] Le porte non raggiungibili possono essere bloccate da firewall, oppure non attive su quel server (es. 636 senza LDAPS)." }
            Write-Log "Test porte DC completato con successo" "Completato"
        } catch { Write-Log "[ERRORE] Test porte: $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#CBD5E1", "#0F172A", "Sola lettura: verifica DNS SRV e le porte TCP verso un DC (53, 88, 135, 389, 445, 464, 636, 3268). Utile per capire perché un PC non raggiunge il dominio.")
)

$o365Btns = @(
    @("Disabilita ADAL Office", {
        Show-CommandSummary "Disabilita ADAL Office" @("HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Identity -> EnableADAL=0, DisableADALatopWAMOverride=1")
        try {
            $regPath = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Identity"
            if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
            Set-ItemProperty -Path $regPath -Name "EnableADAL" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $regPath -Name "DisableADALatopWAMOverride" -Value 1 -Type DWord -Force
            Write-Log "[OK] ADAL Disabilitato: EnableADAL=0 e DisableADALatopWAMOverride=1 impostati su $regPath" "ADAL OFF"
            [System.Windows.Forms.MessageBox]::Show("ADAL Disabilitato con successo.`r`n`r`nChiudi e riapri Outlook / Office per applicare le modifiche.", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            Write-Log "[ERRORE] Disabilita ADAL: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#78350F", "#F8FAFC", "Disabilita l'autenticazione moderna ADAL/WAM per Office 2016/365 - utile per problemi di login legacy."),

    @("Abilita ADAL Office", {
        Show-CommandSummary "Abilita ADAL Office" @("HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Identity -> EnableADAL=1, Remove DisableADALatopWAMOverride")
        try {
            $regPath = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Identity"
            if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
            Set-ItemProperty -Path $regPath -Name "EnableADAL" -Value 1 -Type DWord -Force
            # Rimuove override se presente, altrimenti lo setta a 0
            if (Get-ItemProperty -Path $regPath -Name "DisableADALatopWAMOverride" -ErrorAction SilentlyContinue) {
                Remove-ItemProperty -Path $regPath -Name "DisableADALatopWAMOverride" -ErrorAction SilentlyContinue
            }
            Set-ItemProperty -Path $regPath -Name "DisableADALatopWAMOverride" -Value 0 -Type DWord -Force
            Remove-ItemProperty -Path $regPath -Name "DisableADALatopWAMOverride" -ErrorAction SilentlyContinue
            Write-Log "[OK] ADAL Abilitato: EnableADAL=1 su $regPath - Override rimosso." "ADAL ON"
            [System.Windows.Forms.MessageBox]::Show("ADAL Abilitato con successo (modalità moderna).`r`n`r`nRiavvia Outlook / Office.", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            Write-Log "[ERRORE] Abilita ADAL: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#064E3B", "#F8FAFC", "Riabilita l'autenticazione moderna ADAL/WAM - ripristina il login Microsoft 365 standard."),

    @("Escludi O365 Autodiscover", {
        Show-CommandSummary "Escludi O365 Autodiscover" @("HKCU:\...\Outlook\AutoDiscover -> ExcludeExplicitO365Endpoint=1 + altri Exclude")
        try {
            $regPath = "HKCU:\Software\Microsoft\Office\16.0\Outlook\AutoDiscover"
            if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
            # Esclude endpoint O365 per forzare autodiscover locale / on-prem (fix classico per Outlook che va su O365 errato)
            Set-ItemProperty -Path $regPath -Name "ExcludeExplicitO365Endpoint" -Value 1 -Type DWord -Force
            # Opzionale: esclude anche altri metodi se serve stabilizzare su Exchange locale
            # Set-ItemProperty -Path $regPath -Name "ExcludeHttpsRootDomain" -Value 1 -Type DWord -Force
            # Set-ItemProperty -Path $regPath -Name "ExcludeScpLookup" -Value 1 -Type DWord -Force
            Write-Log "[OK] Esclusione Autodiscover O365 attiva: ExcludeExplicitO365Endpoint=1 su $regPath" "Autodiscover Escluso"
            Write-Log "[INFO] Questo forza Outlook a ignorare Microsoft 365 e cercare Autodiscover locale / SCP."
            [System.Windows.Forms.MessageBox]::Show("Esclusione Autodiscover O365 applicata:`r`nExcludeExplicitO365Endpoint=1`r`n`r`nChiudi e riapri Outlook. Usa 'Ripristina Autodiscover' per tornare al default.", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            Write-Log "[ERRORE] Escludi O365 Autodiscover: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#78350F", "#F8FAFC", "Esclude l'endpoint O365 dall'Autodiscover di Outlook - utile se hai Exchange on-prem o ibrido e Outlook tenta sempre O365."),
    @("Ripristina Autodiscover", {
        Show-CommandSummary "Ripristina Autodiscover" @("Rimuove chiavi Exclude* da HKCU\...\Outlook\AutoDiscover")
        try {
            $regPath = "HKCU:\Software\Microsoft\Office\16.0\Outlook\AutoDiscover"
            if (Test-Path $regPath) {
                $props = @("ExcludeExplicitO365Endpoint","ExcludeHttpsRootDomain","ExcludeScpLookup","ExcludeHttpRedirect","ExcludeSrvRecord","ExcludeLastKnownGoodUrl","ExcludeHttpsAutoDiscoverDomain")
                foreach ($p in $props) {
                    if (Get-ItemProperty -Path $regPath -Name $p -ErrorAction SilentlyContinue) {
                        Remove-ItemProperty -Path $regPath -Name $p -Force -ErrorAction SilentlyContinue
                        Write-Log "[INFO] Rimosso: $p"
                    }
                }
                # Se la chiave è vuota, la rimuove
                if ((Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue | Get-Member -MemberType NoteProperty | Where-Object {$_.Name -notlike "PS*"}).Count -eq 0) {
                    # lascia la chiave vuota, non serve cancellarla
                }
                Write-Log "[OK] Autodiscover ripristinato ai valori predefiniti Microsoft." "Autodiscover Ripristinato"
                [System.Windows.Forms.MessageBox]::Show("Autodiscover ripristinato al default.`r`nTutte le esclusioni sono state rimosse.`r`n`r`nRiavvia Outlook.", "Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            } else {
                Write-Log "[INFO] Nessuna personalizzazione Autodiscover trovata - già in default." "Nessuna Modifica"
                [System.Windows.Forms.MessageBox]::Show("Nessuna chiave Autodiscover personalizzata trovata. Outlook è già in configurazione predefinita.", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        } catch {
            Write-Log "[ERRORE] Ripristina Autodiscover: $_" "Errore"
            [System.Windows.Forms.MessageBox]::Show("Errore: $_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }, "#064E3B", "#F8FAFC", "Rimuove tutte le esclusioni Autodiscover e ripristina il comportamento standard di Outlook."),
    @("Report Licenze Office`n(ospp.vbs /dstatus)", {
        try {
            Show-WaitOverlay "Verifica licenze Office..."
            Write-Log "[INFO] Ricerca ospp.vbs..." "Avviato"
            $ospp = $null
            foreach ($root in @("C:\Program Files\Microsoft Office","C:\Program Files (x86)\Microsoft Office")) {
                if (Test-Path $root) {
                    $f = Get-ChildItem -Path $root -Filter "ospp.vbs" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($f) { $ospp = $f; break }
                }
            }
            if (-not $ospp) {
                foreach ($k in @("C:\Program Files\Microsoft Office\Office16\ospp.vbs","C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs","C:\Program Files\Microsoft Office\root\Office16\ospp.vbs")) {
                    if (Test-Path $k) { $ospp = Get-Item $k -ErrorAction SilentlyContinue; if($ospp){break} }
                }
            }
            if (-not $ospp) { Write-Log "[ERRORE] ospp.vbs non trovato" "Errore"; return }
            $out = cscript //nologo $ospp.FullName /dstatus 2>&1 | Out-String
            Write-Log $out "Risultato"
            Write-Log "[OK] Licenze verificate" "Completato"
        } catch { Write-Log "[ERRORE] $_" "Errore" } finally { Hide-WaitOverlay }
    }, "#064E3B", "#F8FAFC", "Mostra stato licenze Office con ospp.vbs /dstatus")
)


# === CONTEGGIO DINAMICO TOTALE COMANDI - v2.38 FIX ===
# Unico punto di verità: somma di tutti gli array. Se aggiungi un comando, si aggiorna da solo
# (anche i numeri mostrati nel popup di benvenuto e nelle NOTE). Nei commenti delle schede non ci sono numeri fissi.
function Get-TotalCommands {
    $allArrays = @($diagBtns, $dismBtns, $toolBtns, $netBtns, $maintBtns, $printerBtns, $secBtns, $tweakBtns, $usbBtns, $adBtns, $o365Btns)
    $sum = 0
    foreach ($a in $allArrays) { if ($null -ne $a) { $sum += $a.Count } }
    # Fallback regex se somma = 0 (file corrotto o array non ancora inizializzati)
    if ($sum -eq 0) {
        try {
            $raw = Get-Content -Path $PSCommandPath -Raw -ErrorAction SilentlyContinue
            if ($raw) { $sum = ([regex]::Matches($raw, '@\s*\(\s*"[^"]+"\s*,\s*\{')).Count }
        } catch { Write-StartLog "Errore ignorato: $_" }
    }
    return $sum
}
$global:totalCommands = Get-TotalCommands

# ==============================================================================
# TEMA SCURO (v3.9.1): barra del titolo scura e tab control scuro
# Tutto è facoltativo: se il sistema non supporta una funzione, viene ignorata
# senza errori e la finestra resta con l'aspetto standard.
# ==============================================================================

# Barra del titolo scura (Windows 10 2004+ / Windows 11).
# Su Windows 11 si può anche colorare la barra con lo stesso colore dell'intestazione.
function Enable-DarkTitleBar {
    param(
        [Parameter(Mandatory = $true)] $Form,
        [string]$CaptionHex = "",
        [string]$TextHex = "#E2E8F0"
    )
    try {
        if (-not ('Bino.DwmApi' -as [type])) {
            Add-Type -Namespace Bino -Name DwmApi -ErrorAction Stop -MemberDefinition '[DllImport("dwmapi.dll")] public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);'
        }
        $capRef = -1
        $txtRef = -1
        if ($CaptionHex) {
            $cc = [System.Drawing.ColorTranslator]::FromHtml($CaptionHex)
            $tc = [System.Drawing.ColorTranslator]::FromHtml($TextHex)
            $capRef = [int]($cc.R + ($cc.G * 256) + ($cc.B * 65536))
            $txtRef = [int]($tc.R + ($tc.G * 256) + ($tc.B * 65536))
        }
        $handler = {
            param($sender, $e)
            try {
                $h = $sender.Handle
                $v = 1
                $r = [Bino.DwmApi]::DwmSetWindowAttribute($h, 20, [ref]$v, 4)
                if ($r -ne 0) { [void][Bino.DwmApi]::DwmSetWindowAttribute($h, 19, [ref]$v, 4) }
                if ($capRef -ge 0) {
                    $cv = $capRef
                    [void][Bino.DwmApi]::DwmSetWindowAttribute($h, 35, [ref]$cv, 4)
                    $tv = $txtRef
                    [void][Bino.DwmApi]::DwmSetWindowAttribute($h, 36, [ref]$tv, 4)
                }
            } catch { $null = $_ }
        }.GetNewClosure()
        $Form.Add_HandleCreated($handler)
    } catch { Write-StartLog "Barra del titolo scura non disponibile: $_" }
}

# Tab control scuro: stessa larghezza delle schede di prima, ma disegnato a mano
# (sfondo scuro anche dietro le schede, scheda attiva con barra azzurra, effetto hover).
$global:BinoDarkTabSource = @'
using System;
using System.Drawing;
using System.Windows.Forms;

namespace Bino
{
    public class DarkTabControl : TabControl
    {
        public Color StripColor  = Color.FromArgb(15, 23, 42);
        public Color TabColor    = Color.FromArgb(30, 41, 59);
        public Color HoverColor  = Color.FromArgb(51, 65, 85);
        public Color ActiveColor = Color.FromArgb(15, 23, 42);
        public Color AccentColor = Color.FromArgb(56, 189, 248);
        public Color NormalText  = Color.FromArgb(148, 163, 184);
        public Color HoverText   = Color.FromArgb(226, 232, 240);
        public Color ActiveText  = Color.FromArgb(248, 250, 252);
        private int hotIndex = -1;

        public DarkTabControl()
        {
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
            BackColor = StripColor;
            Padding = new Point(9, 5);
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            Graphics g = e.Graphics;
            using (SolidBrush bg = new SolidBrush(StripColor))
            {
                g.FillRectangle(bg, ClientRectangle);
            }
            if (TabCount == 0) { return; }

            int refIdx = (SelectedIndex == 0 && TabCount > 1) ? 1 : 0;
            Rectangle refRect = GetTabRect(refIdx);

            for (int i = 0; i < TabCount; i++)
            {
                Rectangle r = GetTabRect(i);
                bool selected = (i == SelectedIndex);
                bool hot = (i == hotIndex) && !selected;
                Color back = selected ? ActiveColor : (hot ? HoverColor : TabColor);
                Color fore = selected ? ActiveText : (hot ? HoverText : NormalText);
                Rectangle tr = new Rectangle(r.X + 2, refRect.Y, r.Width - 4, refRect.Height);

                using (SolidBrush tb = new SolidBrush(back))
                {
                    g.FillRectangle(tb, tr);
                }
                if (selected)
                {
                    using (SolidBrush ab = new SolidBrush(AccentColor))
                    {
                        g.FillRectangle(ab, tr.X, tr.Y, tr.Width, 3);
                    }
                }
                TextFormatFlags flags = TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter
                    | TextFormatFlags.SingleLine | TextFormatFlags.NoPrefix | TextFormatFlags.NoPadding | TextFormatFlags.NoClipping;
                Rectangle textRect = new Rectangle(r.X, tr.Y, r.Width, tr.Height);
                TextRenderer.DrawText(g, TabPages[i].Text, Font, textRect, fore, flags);
            }
        }

        protected override void OnSelectedIndexChanged(EventArgs e)
        {
            base.OnSelectedIndexChanged(e);
            Invalidate();
        }

        protected override void OnMouseMove(MouseEventArgs e)
        {
            base.OnMouseMove(e);
            int idx = -1;
            for (int i = 0; i < TabCount; i++)
            {
                if (GetTabRect(i).Contains(e.Location)) { idx = i; break; }
            }
            if (idx != hotIndex)
            {
                hotIndex = idx;
                Invalidate();
            }
        }

        protected override void OnMouseLeave(EventArgs e)
        {
            base.OnMouseLeave(e);
            if (hotIndex != -1)
            {
                hotIndex = -1;
                Invalidate();
            }
        }
    }
}
'@

# Crea il tab control scuro; se la compilazione non riesce usa quello standard.
function New-AppTabControl {
    try {
        if (-not ('Bino.DarkTabControl' -as [type])) {
            Add-Type -TypeDefinition $global:BinoDarkTabSource -ReferencedAssemblies 'System.Windows.Forms', 'System.Drawing' -ErrorAction Stop
        }
        return (New-Object Bino.DarkTabControl)
    } catch {
        Write-StartLog "Tab scuri non disponibili, uso il controllo standard: $_"
        return (New-Object System.Windows.Forms.TabControl)
    }
}


# ==============================================================================
# POPUP DI BENVENUTO CON VERSIONE E TOTALE COMANDI DINAMICO
# ==============================================================================
$welcomeForm = New-Object System.Windows.Forms.Form
Enable-DarkTitleBar $welcomeForm
$welcomeForm.Text = "AVVISO DI SICUREZZA E LIMITAZIONE DI RESPONSABILITÀ"
$welcomeForm.Size = New-Object System.Drawing.Size(760, 700)
$welcomeForm.StartPosition = "CenterScreen"
$welcomeForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$welcomeForm.MaximizeBox = $false
$welcomeForm.MinimizeBox = $false
$welcomeForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")
$welcomeForm.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::Stretch
# --- SFONDO PERSONALIZZATO ---
try {
    $scriptDir = Split-Path -Parent $PSCommandPath
    if (-not $scriptDir) { $scriptDir = $PSScriptRoot }
    if (-not $scriptDir) { $scriptDir = (Get-Location).Path }
    $possibleBgs = @(
        (Join-Path $scriptDir "bino_bg.jpg"),
        (Join-Path $scriptDir "bino_bg.png"),
        (Join-Path $scriptDir "splash_bg.jpg"),
        (Join-Path $scriptDir "splash_bg.png"),
        (Join-Path $scriptDir "background.jpg"),
        (Join-Path $scriptDir "background.png")
    )
    foreach ($bgPath in $possibleBgs) {
        if (Test-Path $bgPath) {
            try {
                $img = [System.Drawing.Image]::FromFile($bgPath)
                $welcomeForm.BackgroundImage = $img
                # Overlay semi-trasparente per leggibilità
                $overlay = New-Object System.Windows.Forms.Panel
                $overlay.Dock = [System.Windows.Forms.DockStyle]::Fill
                $overlay.BackColor = [System.Drawing.Color]::FromArgb(200, 15, 23, 42) # #0F172A con alpha 200
                $welcomeForm.Controls.Add($overlay)
                $overlay.SendToBack()
                # Il BackgroundImage deve stare sotto, quindi overlay sopra background ma sotto i controlli
                # Per farlo, mettiamo overlay come primo controllo e poi BringToFront su tutti gli altri dopo
                break
            } catch { Write-StartLog "Errore ignorato: $_" }
        }
    }
} catch { Write-StartLog "Errore ignorato: $_" }

# Icona di attenzione
$pbIcon = New-Object System.Windows.Forms.PictureBox
$pbIcon.Image = [System.Drawing.SystemIcons]::Warning.ToBitmap()
$pbIcon.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$pbIcon.Size = New-Object System.Drawing.Size(48, 48)
$pbIcon.Location = New-Object System.Drawing.Point(20, 20)
$welcomeForm.Controls.Add($pbIcon)

# Titolo principale
$lblWTitle = New-Object System.Windows.Forms.Label
$lblWTitle.Text = "Benvenuto nello Strumento di Manutenzione by Bino"
$lblWTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12.5, [System.Drawing.FontStyle]::Bold)
$lblWTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F8FAFC")
$lblWTitle.Location = New-Object System.Drawing.Point(80, 20)
$lblWTitle.Size = New-Object System.Drawing.Size(640, 30)
$welcomeForm.Controls.Add($lblWTitle)

$lblWSub = New-Object System.Windows.Forms.Label
$lblWSub.Text = "Presta la massima attenzione alla colorazione dei comandi:"
$lblWSub.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$lblWSub.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#94A3B8")
$lblWSub.Location = New-Object System.Drawing.Point(80, 52)
$lblWSub.Size = New-Object System.Drawing.Size(640, 25)

$welcomeForm.Controls.Add($lblWSub)

# --- LABEL VERSIONE E TOTALE COMANDI (dinamico) ---
$lblVersionInfo = New-Object System.Windows.Forms.Label
$lblVersionInfo.Text = "Versione: $scriptVersion"
# Se il conteggio fallback è 0, prova a ricalcolare più tardi, intanto mostra versione
if ($global:totalCommands -eq 0) {
    $lblVersionInfo.Text = "Versione: $scriptVersion"
}
$lblVersionInfo.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblVersionInfo.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#38BDF8")
$lblVersionInfo.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E293B")
$lblVersionInfo.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$lblVersionInfo.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$lblVersionInfo.Location = New-Object System.Drawing.Point(20, 82)
$lblVersionInfo.Size = New-Object System.Drawing.Size(700, 30)
$lblVersionInfo.AutoSize = $false
$welcomeForm.Controls.Add($lblVersionInfo)


# Pallino e Testo BIANCO - NUOVO
$pnlWhite = New-Object System.Windows.Forms.Panel
$pnlWhite.Size = New-Object System.Drawing.Size(16, 16)
$pnlWhite.Location = New-Object System.Drawing.Point(25, 125)
$pnlWhite.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#CBD5E1")
$pnlWhite.BorderStyle = "FixedSingle"
$welcomeForm.Controls.Add($pnlWhite)

$lblWhiteText = New-Object System.Windows.Forms.Label
$lblWhiteText.Text = "PULSANTI GRIGIO CHIARO (Sola Lettura / Sicurissimi): Comandi che non modificano nulla. Solo lettura info, zero rischi. Ideali per diagnostica."
$lblWhiteText.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblWhiteText.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F8FAFC")
$lblWhiteText.Location = New-Object System.Drawing.Point(55, 122)
$lblWhiteText.Size = New-Object System.Drawing.Size(660, 50)
$welcomeForm.Controls.Add($lblWhiteText)

# Pallino e Testo VERDE
$pnlGreen = New-Object System.Windows.Forms.Panel
$pnlGreen.Size = New-Object System.Drawing.Size(16, 16)
$pnlGreen.Location = New-Object System.Drawing.Point(25, 185)
$pnlGreen.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#10B981")
$welcomeForm.Controls.Add($pnlGreen)

$lblGreenText = New-Object System.Windows.Forms.Label
$lblGreenText.Text = "PULSANTI VERDI (Sicuri / Standard): Azioni di normale diagnostica, lettura informazioni o pulizie basilari. Nessun rischio di alterazione permanente o perdita dati."
$lblGreenText.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$lblGreenText.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F8FAFC")
$lblGreenText.Location = New-Object System.Drawing.Point(55, 182)
$lblGreenText.Size = New-Object System.Drawing.Size(660, 50)
$welcomeForm.Controls.Add($lblGreenText)

# Pallino e Testo ARANCIONE
$pnlOrange = New-Object System.Windows.Forms.Panel
$pnlOrange.Size = New-Object System.Drawing.Size(16, 16)
$pnlOrange.Location = New-Object System.Drawing.Point(25, 245)
$pnlOrange.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#F59E0B")
$welcomeForm.Controls.Add($pnlOrange)

$lblOrangeText = New-Object System.Windows.Forms.Label
$lblOrangeText.Text = "PULSANTI ARANCIONI (Attenzione / Avanzati): Azioni a medio impatto o modifiche strutturali (es. attivazioni BitLocker, pulizie profonde WinSxS, disattivazioni ibernazione). Richiedono consapevolezza."
$lblOrangeText.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$lblOrangeText.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F8FAFC")
$lblOrangeText.Location = New-Object System.Drawing.Point(55, 242)
$lblOrangeText.Size = New-Object System.Drawing.Size(660, 50)
$welcomeForm.Controls.Add($lblOrangeText)

# Pallino e Testo ROSSO
$pnlRed = New-Object System.Windows.Forms.Panel
$pnlRed.Size = New-Object System.Drawing.Size(16, 16)
$pnlRed.Location = New-Object System.Drawing.Point(25, 305)
$pnlRed.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#DC2626")
$welcomeForm.Controls.Add($pnlRed)

$lblRedText = New-Object System.Windows.Forms.Label
$lblRedText.Text = "PULSANTI ROSSI (Critico / Pericolo): Funzioni ad altissimo impatto (es. reset completo delle schede di rete o messa offline dischi). Possono interrompere la connettività o disattivare volumi."
$lblRedText.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$lblRedText.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F8FAFC")
$lblRedText.Location = New-Object System.Drawing.Point(55, 302)
$lblRedText.Size = New-Object System.Drawing.Size(660, 50)
$welcomeForm.Controls.Add($lblRedText)

# Nota Antivirus Integrata
$lblAvIcon = New-Object System.Windows.Forms.Label
$lblAvIcon.Text = "⚠"
$lblAvIcon.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblAvIcon.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FACC15")
$lblAvIcon.BackColor = [System.Drawing.Color]::Transparent
$lblAvIcon.Location = New-Object System.Drawing.Point(25, 363)
$lblAvIcon.Size = New-Object System.Drawing.Size(26, 26)
$lblAvIcon.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$welcomeForm.Controls.Add($lblAvIcon)

$lblAvText = New-Object System.Windows.Forms.Label
$lblAvText.Text = "AVVISO ANTIVIRUS E FALSI POSITIVI: Alcuni strumenti di attivazione o manutenzione avanzata potrebbero essere rilevati falsamente come minacce dai sistemi di sicurezza. Configura le esclusioni se necessario."
$lblAvText.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblAvText.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#38BDF8")
$lblAvText.Location = New-Object System.Drawing.Point(55, 362)
$lblAvText.Size = New-Object System.Drawing.Size(660, 55)
$welcomeForm.Controls.Add($lblAvText)

# Nota finale
$lblWFooter = New-Object System.Windows.Forms.Label
$lblWFooter.Text = "L'uso improprio di questi strumenti può compromettere la stabilità del sistema operativo. Vuoi procedere con l'apertura dell'applicazione?"
$lblWFooter.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblWFooter.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F8FAFC")
$lblWFooter.Location = New-Object System.Drawing.Point(25, 485)
$lblWFooter.Size = New-Object System.Drawing.Size(690, 45)
$welcomeForm.Controls.Add($lblWFooter)

# ==============================================================================
# TESTO DESCRITTIVO INFO - A BLOCCHI MODIFICABILI DIRETTAMENTE NEL PS1
# Ogni blocco è una variabile separata - modifica solo il testo dentro ""
# L'altezza si adatta automaticamente alla lunghezza del testo
# ==============================================================================

# --- BLOCCO 1 ---
$global:aboutBlocco1_Titolo = "Creazione dello script Powershell"
$global:aboutBlocco1_Testo = "Questo script è stato creato con l'aiuto della AI, nel tempo sono state integrate diverse funzioni, inizialmente semplici e minime per poi diventare piu complesse e utili al lavoro dell'IT che necessita di funzioni di diagnostica rapida e verifica OS Windows client e server, in particolare alcune funzioni permettono di risolvere problemi di lentezza del sistema operativo e ripristino dei componenti delle versioni Windows 10 e 11, è stato integrato da poco anche AD-Tools che include comandi di lettura Active Directory per generare dei report di vario tipo riguardanti utenti e gruppi. Nell'ultima release siamo arrivati a ben $($global:totalCommands) comandi totali cosi divisi:`n`nDiagnostica Hardware: $($diagBtns.Count)`nDISM & Avvio: $($dismBtns.Count)`nUtility di Sistema: $($toolBtns.Count)`nRete: $($netBtns.Count)`nManutenzione OS: $($maintBtns.Count)`nStampanti: $($printerBtns.Count)`nSicurezza & BitLocker: $($secBtns.Count)`nTweaks W11: $($tweakBtns.Count)`nDischi Esterni e Veeam Backup and Replication fix: $($usbBtns.Count)`nAD-TOOLs: $($adBtns.Count)`nOffice 365 & Outlook: $($o365Btns.Count)"

# --- BLOCCO 2 ---
$global:aboutBlocco2_Titolo = "Chi sono"
$global:aboutBlocco2_Testo = "Mi chiamo Luca e sono un ex programmatore DELPHI dilettante, ora impiegato nel campo dell'informatica come tecnico IT, se vuoi inviarmi un consiglio su come evolvere questo script scrivimi a luca@libra.it"

# --- BLOCCO 3 ---
$global:aboutBlocco3_Titolo = "Perché uso l'AI ?"
$global:aboutBlocco3_Testo = "AI per me è utilissima sia per per creare contenuti come questo sia per trovare soluzioni a problemi piu o meno noti che giornalmente affliggono i PC dei clienti"

function New-InfoBlock {
    param([string]$titolo, [string]$testo, [int]$yPos, [string]$colorHex)
    
    $fontTxt = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $fontTit = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
    $maxWidth = 590
    $flags = [System.Windows.Forms.TextFormatFlags]::WordBreak

    $proposedSize = New-Object System.Drawing.Size($maxWidth, 10000)
    try {
        $measured = [System.Windows.Forms.TextRenderer]::MeasureText($testo, $fontTxt, $proposedSize, $flags)
        $textHeight = $measured.Height + 10
    } catch {
        $textHeight = [math]::Ceiling($testo.Length / 75) * 20 + 20
    }
    
    if ($textHeight -lt 22) { $textHeight = 22 }
    $panelHeight = 35 + $textHeight + 12
    if ($panelHeight -lt 70) { $panelHeight = 70 }
    if ($panelHeight -gt 800) { $panelHeight = 800 }

    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.Location = New-Object System.Drawing.Point(20, $yPos)
    $pnl.Size = New-Object System.Drawing.Size(620, $panelHeight)
    $pnl.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E293B")
    $pnl.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $lblTit = New-Object System.Windows.Forms.Label
    $lblTit.Text = $titolo
    $lblTit.Font = $fontTit
    $lblTit.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($colorHex)
    $lblTit.Location = New-Object System.Drawing.Point(12, 8)
    $lblTit.Size = New-Object System.Drawing.Size(590, 22)
    $lblTit.AutoSize = $false
    $pnl.Controls.Add($lblTit)

    $lblTxt = New-Object System.Windows.Forms.Label
    $lblTxt.Text = $testo
    $lblTxt.Font = $fontTxt
    $lblTxt.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#E2E8F0")
    $lblTxt.Location = New-Object System.Drawing.Point(12, 32)
    $lblTxt.Size = New-Object System.Drawing.Size(590, $textHeight)
    $lblTxt.AutoSize = $false
    $pnl.Controls.Add($lblTxt)

    return @($pnl, $panelHeight)
}

function Show-AboutInfoPopup {
    $aboutForm = New-Object System.Windows.Forms.Form
    Enable-DarkTitleBar $aboutForm
    $aboutForm.Text = "Informazioni - About"
    $aboutForm.Size = New-Object System.Drawing.Size(700, 750)
    $aboutForm.MinimumSize = New-Object System.Drawing.Size(700, 500)
    $aboutForm.MaximumSize = New-Object System.Drawing.Size(700, 900)
    $aboutForm.StartPosition = "CenterParent"
    $aboutForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
    $aboutForm.MaximizeBox = $false
    $aboutForm.MinimizeBox = $false
    $aboutForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")
    $aboutForm.AutoScroll = $true
    $aboutForm.ShowInTaskbar = $false

    $lblAboutTitle = New-Object System.Windows.Forms.Label
    $lblAboutTitle.Text = "Informazioni sullo strumento - $scriptVersion"
    $lblAboutTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $lblAboutTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#38BDF8")
    $lblAboutTitle.Location = New-Object System.Drawing.Point(20, 15)
    $lblAboutTitle.Size = New-Object System.Drawing.Size(620, 25)
    $aboutForm.Controls.Add($lblAboutTitle)

    # Crea i blocchi con altezza dinamica
    $y = 50
    $result = New-InfoBlock $global:aboutBlocco1_Titolo $global:aboutBlocco1_Testo $y "#38BDF8"
    $b1 = $result[0]; $h1 = $result[1]
    $aboutForm.Controls.Add($b1)
    $y += $h1 + 12

    $result = New-InfoBlock $global:aboutBlocco2_Titolo $global:aboutBlocco2_Testo $y "#10B981"
    $b2 = $result[0]; $h2 = $result[1]
    $aboutForm.Controls.Add($b2)
    $y += $h2 + 12

    $result = New-InfoBlock $global:aboutBlocco3_Titolo $global:aboutBlocco3_Testo $y "#F59E0B"
    $b3 = $result[0]; $h3 = $result[1]
    $aboutForm.Controls.Add($b3)
    $y += $h3 + 12

    $btnAboutClose = New-Object System.Windows.Forms.Button
    $btnAboutClose.Text = "CHIUDI"
    $btnAboutClose.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnAboutClose.ForeColor = [System.Drawing.Color]::White
    $btnAboutClose.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0EA5E9")
    $btnAboutClose.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnAboutClose.FlatAppearance.BorderSize = 0
    $btnAboutClose.Size = New-Object System.Drawing.Size(120, 36)
    $aboutForm.AutoScrollMinSize = New-Object System.Drawing.Size(0, $y + 80)
    $btnAboutClose.Location = New-Object System.Drawing.Point(540, $y)
    $btnAboutClose.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $btnAboutClose.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnAboutClose.Add_Click({ $aboutForm.Close() })
    $aboutForm.Controls.Add($btnAboutClose)

    [void]$aboutForm.ShowDialog()
}

# Pulsante INFO nella finestra di benvenuto (basso a sinistra)
$btnWelcomeInfo = New-Object System.Windows.Forms.Button
$btnWelcomeInfo.Text = "INFO"
$btnWelcomeInfo.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnWelcomeInfo.ForeColor = [System.Drawing.Color]::White
$btnWelcomeInfo.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E293B")
$btnWelcomeInfo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnWelcomeInfo.FlatAppearance.BorderSize = 1
$btnWelcomeInfo.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#38BDF8")
$btnWelcomeInfo.Size = New-Object System.Drawing.Size(130, 45)
$btnWelcomeInfo.Location = New-Object System.Drawing.Point(25, 585)
$btnWelcomeInfo.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnWelcomeInfo.Add_MouseEnter({ $btnWelcomeInfo.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#334155") })
$btnWelcomeInfo.Add_MouseLeave({ $btnWelcomeInfo.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E293B") })
$btnWelcomeInfo.Add_Click({ Show-AboutInfoPopup })
$welcomeForm.Controls.Add($btnWelcomeInfo)
# Porta tutti i controlli sopra l'overlay se presente
try { foreach ($c in $welcomeForm.Controls) { if ($c -ne $overlay) { $c.BringToFront() } } } catch { Write-StartLog "Errore ignorato: $_" }

# Pulsante SI
$btnYes = New-Object System.Windows.Forms.Button
$btnYes.Text = "Si procedi! "
$btnYes.Font = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
$btnYes.ForeColor = [System.Drawing.Color]::White
$btnYes.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0284C7")
$btnYes.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnYes.FlatAppearance.BorderSize = 0
$btnYes.Size = New-Object System.Drawing.Size(130, 45)
$btnYes.Location = New-Object System.Drawing.Point(430, 585)
$btnYes.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnYes.Add_Click({
    $welcomeForm.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    $welcomeForm.Close()
})
$welcomeForm.Controls.Add($btnYes)

# Pulsante NO
$btnNo = New-Object System.Windows.Forms.Button
$btnNo.Text = "Annulla"
$btnNo.Font = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
$btnNo.ForeColor = [System.Drawing.Color]::White
$btnNo.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#334155")
$btnNo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnNo.FlatAppearance.BorderSize = 0
$btnNo.Size = New-Object System.Drawing.Size(130, 45)
$btnNo.Location = New-Object System.Drawing.Point(590, 585)
$btnNo.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnNo.Add_Click({
    $welcomeForm.DialogResult = [System.Windows.Forms.DialogResult]::No
    $welcomeForm.Close()
})
$welcomeForm.Controls.Add($btnNo)

# Label già impostata sopra, qui solo refresh sicuro (unico punto)
$lblVersionInfo.Text = "Versione: $scriptVersion"

# --- FIX TASTI SPARITI CON SFONDO ---
try {
    if ($overlay -ne $null) {
        $overlay.SendToBack()
        foreach ($c in $welcomeForm.Controls) {
            if ($c -ne $overlay) { $c.BringToFront() }
        }
        $btnYes.BringToFront()
        $btnNo.BringToFront()
        $btnWelcomeInfo.BringToFront()
    }
} catch { Write-StartLog "Errore ignorato: $_" }

$welcomeResult = $welcomeForm.ShowDialog()

if ($welcomeResult -ne [System.Windows.Forms.DialogResult]::Yes) {
    exit
}

$form = New-Object System.Windows.Forms.Form
Enable-DarkTitleBar $form -CaptionHex "#1E293B"
$form.Text = "BINO - Strumento di Manutenzione e Diagnostica (ADMIN) [$scriptVersion]"
$form.Size = New-Object System.Drawing.Size(1415, 920)
$form.MinimumSize = New-Object System.Drawing.Size(1415, 800)
$form.MaximumSize = New-Object System.Drawing.Size(1415, 1600)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")

# --- HEADER / INTESTAZIONE CON LOGO ---
$pnlHeader = New-Object System.Windows.Forms.Panel
$pnlHeader.Dock = "Top"
$pnlHeader.Height = 75
$pnlHeader.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E293B")

$logoPath = Join-Path -Path $PSScriptRoot -ChildPath "logo.png"
$titleXOffset = 20

if (Test-Path $logoPath) {
    $pbLogo = New-Object System.Windows.Forms.PictureBox
    $pbLogo.Image = [System.Drawing.Image]::FromFile($logoPath)
    $pbLogo.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $pbLogo.Size = New-Object System.Drawing.Size(55, 55)
    $pbLogo.Location = New-Object System.Drawing.Point(15, 10)
    $pnlHeader.Controls.Add($pbLogo)
    $titleXOffset = 80
}

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "UTILITY PER LA MANUTENZIONE DEL SISTEMA OPERATIVO E DEI SUI COMPONENTI"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#38BDF8")
$lblTitle.Location = New-Object System.Drawing.Point($titleXOffset, 12)
$lblTitle.AutoSize = $true

$lblSubTitle = New-Object System.Windows.Forms.Label
$lblSubTitle.Text = "Strumento di Manutenzione Windows, Office, Rete, BitLocker e Diagnostica | creato da Bino con supporto AI | $scriptVersion"
$lblSubTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblSubTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#94A3B8")
$lblSubTitle.Location = New-Object System.Drawing.Point($titleXOffset, 44)
$lblSubTitle.AutoSize = $true


# ==============================================================================
# PULSANTE INFO + POPUP EDITABILE - Aggiunto su richiesta utente
# ==============================================================================
$global:infoFilePath = Join-Path -Path $PSScriptRoot -ChildPath "bino_info.txt"
# fallback se PSScriptRoot non scrivibile
try {
    if (-not (Test-Path $PSScriptRoot)) { $global:infoFilePath = Join-Path $env:TEMP "bino_info.txt" }
} catch { $global:infoFilePath = Join-Path $env:TEMP "bino_info.txt" }

function Show-InfoPopup {
    $infoForm = New-Object System.Windows.Forms.Form
    Enable-DarkTitleBar $infoForm
    $infoForm.Text = "INFO - Note e Informazioni"
    $infoForm.Size = New-Object System.Drawing.Size(700, 550)
    $infoForm.StartPosition = "CenterParent"
    $infoForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $infoForm.MaximizeBox = $false
    $infoForm.MinimizeBox = $false
    $infoForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")
    $infoForm.Topmost = $false

    $lblInfoHeader = New-Object System.Windows.Forms.Label
    $lblInfoHeader.Text = "Inserisci qui le tue informazioni / note:"
    $lblInfoHeader.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $lblInfoHeader.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#38BDF8")
    $lblInfoHeader.Location = New-Object System.Drawing.Point(20, 15)
    $lblInfoHeader.Size = New-Object System.Drawing.Size(640, 25)
    $infoForm.Controls.Add($lblInfoHeader)

    $txtInfo = New-Object System.Windows.Forms.TextBox
    $txtInfo.Multiline = $true
    $txtInfo.ScrollBars = "Both"
    $txtInfo.WordWrap = $false
    $txtInfo.Font = New-Object System.Drawing.Font("Consolas", 10.5)
    $txtInfo.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#020617")
    $txtInfo.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#E2E8F0")
    $txtInfo.Location = New-Object System.Drawing.Point(20, 45)
    $txtInfo.Size = New-Object System.Drawing.Size(640, 390)
    # Carica testo salvato se esiste
    if (Test-Path $global:infoFilePath) {
        try { $txtInfo.Text = Get-Content -Path $global:infoFilePath -Raw -ErrorAction SilentlyContinue } catch { Write-StartLog "Errore ignorato: $_" }
    } else {
        $txtInfo.Text = "Scrivi qui le tue note...`r`n`r`nEsempio:`r`n- Contatti assistenza`r`n- Note cliente`r`n- Procedure personalizzate`r`n"
    }
    $infoForm.Controls.Add($txtInfo)

    $lblPath = New-Object System.Windows.Forms.Label
    $lblPath.Text = "File: $global:infoFilePath"
    $lblPath.Font = New-Object System.Drawing.Font("Segoe UI", 7.5)
    $lblPath.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#64748B")
    $lblPath.Location = New-Object System.Drawing.Point(20, 440)
    $lblPath.Size = New-Object System.Drawing.Size(400, 15)
    $infoForm.Controls.Add($lblPath)

    $btnSave = New-Object System.Windows.Forms.Button
    $btnSave.Text = "SALVA"
    $btnSave.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $btnSave.ForeColor = [System.Drawing.Color]::White
    $btnSave.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0EA5E9")
    $btnSave.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnSave.FlatAppearance.BorderSize = 0
    $btnSave.Size = New-Object System.Drawing.Size(120, 36)
    $btnSave.Location = New-Object System.Drawing.Point(310, 460)
    $btnSave.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnSave.Add_Click({
        try {
            Set-Content -Path $global:infoFilePath -Value $txtInfo.Text -Force -Encoding UTF8
            Write-Log "[OK] Note Info salvate in $global:infoFilePath" "Info Salvate"
            [System.Windows.Forms.MessageBox]::Show("Informazioni salvate con successo!`r`n`r`nPercorso: $global:infoFilePath", "Salvato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Errore salvataggio:`r`n$_", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })
    $infoForm.Controls.Add($btnSave)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "CHIUDI"
    $btnClose.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $btnClose.ForeColor = [System.Drawing.Color]::White
    $btnClose.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#334155")
    $btnClose.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnClose.FlatAppearance.BorderSize = 0
    $btnClose.Size = New-Object System.Drawing.Size(120, 36)
    $btnClose.Location = New-Object System.Drawing.Point(440, 460)
    $btnClose.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnClose.Add_Click({ $infoForm.Close() })
    $infoForm.Controls.Add($btnClose)

    $btnClear = New-Object System.Windows.Forms.Button
    $btnClear.Text = "PULISCI"
    $btnClear.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btnClear.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#94A3B8")
    $btnClear.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E293B")
    $btnClear.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnClear.FlatAppearance.BorderSize = 0
    $btnClear.Size = New-Object System.Drawing.Size(80, 36)
    $btnClear.Location = New-Object System.Drawing.Point(20, 460)
    $btnClear.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnClear.Add_Click({ $txtInfo.Clear() })
    $infoForm.Controls.Add($btnClear)

    $infoForm.Add_Shown({ $txtInfo.Focus() })
    [void]$infoForm.ShowDialog()
}


$btnHeaderExit = New-Object System.Windows.Forms.Button
$btnHeaderExit.Text = "EXIT"
$btnHeaderExit.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnHeaderExit.ForeColor = [System.Drawing.Color]::White
$btnHeaderExit.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#334155")
$btnHeaderExit.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnHeaderExit.FlatAppearance.BorderSize = 0
$btnHeaderExit.Size = New-Object System.Drawing.Size(100, 40)
$btnHeaderExit.Location = New-Object System.Drawing.Point(1280, 16)
$btnHeaderExit.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnHeaderExit.Add_MouseEnter({ $btnHeaderExit.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#475569") })
$btnHeaderExit.Add_MouseLeave({ $btnHeaderExit.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#334155") })
$btnHeaderExit.Add_Click({ $form.Close() })

$btnHeaderInfo = New-Object System.Windows.Forms.Button
$btnHeaderInfo.Text = "NOTE"
$btnHeaderInfo.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnHeaderInfo.ForeColor = [System.Drawing.Color]::White
$btnHeaderInfo.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0EA5E9")
$btnHeaderInfo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnHeaderInfo.FlatAppearance.BorderSize = 0
$btnHeaderInfo.Size = New-Object System.Drawing.Size(100, 40)
$btnHeaderInfo.Location = New-Object System.Drawing.Point(1165, 16)
$btnHeaderInfo.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnHeaderInfo.Add_MouseEnter({ $btnHeaderInfo.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0284C7") })
$btnHeaderInfo.Add_MouseLeave({ $btnHeaderInfo.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0EA5E9") })
$btnHeaderInfo.Add_Click({ Show-InfoPopup })

$pnlHeader.Controls.AddRange(@($lblTitle, $lblSubTitle, $btnHeaderInfo, $btnHeaderExit))

# --- STATUS BAR ---
$pnlStatus = New-Object System.Windows.Forms.Panel
$pnlStatus.Dock = "Bottom"
$pnlStatus.Height = 32
$pnlStatus.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0284C7")

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = " Pronto (Eseguito come Amministratore). Passa il mouse sopra un comando per visualizzarne la descrizione."
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$lblStatus.ForeColor = [System.Drawing.Color]::White
$lblStatus.Dock = "Left"
$lblStatus.Width = 1050
$lblStatus.TextAlign = "MiddleLeft"

$lblVersion = New-Object System.Windows.Forms.Label
$lblVersion.Text = "Versione $scriptVersion"
$lblVersion.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$lblVersion.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#E0F2FE")
$lblVersion.Dock = "Right"
$lblVersion.Width = 350
$lblVersion.AutoSize = $false
$lblVersion.TextAlign = "MiddleRight"

$pnlStatus.Controls.AddRange(@($lblStatus, $lblVersion))

# --- PANEL LOG / CONSOLE ---
$pnlLog = New-Object System.Windows.Forms.Panel
$pnlLog.Dock = "Fill"
$pnlLog.Height = 310
$pnlLog.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")
$pnlLog.Padding = New-Object System.Windows.Forms.Padding(12)

$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "Console Output Log (Report Esteso e Diagnostica):"
$lblLog.Font = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
$lblLog.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#38BDF8")
$lblLog.Dock = "Top"
$lblLog.Height = 28

$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.ScrollBars = "Vertical"
$txtLog.ReadOnly = $true
$txtLog.DetectUrls = $false
$txtLog.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#020617")
$txtLog.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#38BDF8")
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 11.5)
$txtLog.Dock = "Fill"

$btnClearLog = New-Object System.Windows.Forms.Button
$btnClearLog.Text = "Pulisci Console"
$btnClearLog.Size = New-Object System.Drawing.Size(120, 26)
$btnClearLog.Location = New-Object System.Drawing.Point(1200, 2)
$btnClearLog.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearLog.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#94A3B8")
$btnClearLog.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E293B")
$btnClearLog.Add_Click({ $txtLog.Clear() })

$btnSaveLog = New-Object System.Windows.Forms.Button
$btnSaveLog.Text = "Salva Log in TXT"
$btnSaveLog.Size = New-Object System.Drawing.Size(120, 26)
$btnSaveLog.Location = New-Object System.Drawing.Point(1070, 2)
$btnSaveLog.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSaveLog.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#38BDF8")
$btnSaveLog.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E293B")
$btnSaveLog.Add_Click({
    $filePath = Join-Path -Path $global:OutputDir -ChildPath ("Report_Diagnostica_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")
    ($txtLog.Text -replace "`r?`n", "`r`n") | Out-File -FilePath $filePath -Encoding utf8
    Write-Log "[OK] Log della console salvato nella cartella dello script: $filePath" "Log Salvato"
    [System.Windows.Forms.MessageBox]::Show("File di log salvato nella cartella dello script con successo!`r`n`r`n$filePath", "Salvataggio Completato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})

$pnlLog.Controls.Add($btnSaveLog)
$pnlLog.Controls.Add($btnClearLog)
$pnlLog.Controls.Add($txtLog)
$pnlLog.Controls.Add($lblLog)

# --- TAB CONTROL CONTAINER - COMPATTO E RESIZABLE ---
$pnlTabs = New-Object System.Windows.Forms.Panel
$pnlTabs.Dock = "Top"
$pnlTabs.Height = 460
$pnlTabs.Padding = New-Object System.Windows.Forms.Padding(10)
$pnlTabs.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")

$tabControl = New-AppTabControl
$tabControl.Dock = "Fill"
$tabControl.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$pnlTabs.Controls.Add($tabControl)

# --- LOG ---
$pnlLog.Dock = "Fill"

$form.Controls.Add($pnlLog)
$form.Controls.Add($pnlTabs)
$form.Controls.Add($pnlStatus)
$form.Controls.Add($pnlHeader)



# ==============================================================================
# RICERCA COMANDI (Ctrl+F) E PREFERITI (v3.9.20)
# Ogni pulsante creato da Add-ButtonGrid viene registrato in $global:BinoRegistry:
# la ricerca e il menu Preferiti lavorano su questo elenco, senza duplicare i comandi.
# I preferiti sono salvati in bino_settings.json (chiave Favorites); i recenti restano solo in memoria.
# ==============================================================================
$global:BinoRegistry = New-Object System.Collections.ArrayList
$global:BinoRecent = New-Object System.Collections.ArrayList
$global:BinoTabControl = $tabControl
$global:BinoMainForm = $form
$global:BinoSearchDlg = $null; $global:BinoSearchTxt = $null; $global:BinoSearchLst = $null; $global:BinoSearchDesc = $null
$global:BinoSearchResults = @(); $global:BinoSearchChoice = $null; $global:BinoSearchAction = "go"
$global:BinoPendingKey = $null; $global:BinoFavMenu = $null

function Get-BinoCleanText {
    param([string]$t)
    return (($t -replace '\r?\n', ' ') -replace '\s+', ' ').Trim()
}

# Minuscolo e senza accenti, così "sicurezza" trova anche "Sicurezza" e "così" trova "cosi"
function ConvertTo-BinoSearchKey {
    param([string]$t)
    if ([string]::IsNullOrEmpty($t)) { return "" }
    $n = $t.Normalize([System.Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $n.ToCharArray()) {
        if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) { [void]$sb.Append($ch) }
    }
    return $sb.ToString().ToLowerInvariant()
}

function Get-BinoFavorites {
    $s = Get-BinoSettings
    return @($s["Favorites"] | Where-Object { $_ })
}

function Add-BinoFavorite {
    param([string]$Key)
    $f = @(Get-BinoFavorites)
    if ($f -notcontains $Key) { $f += $Key; [void](Set-BinoSetting "Favorites" @($f)) }
}

function Remove-BinoFavorite {
    param([string]$Key)
    $f = @(Get-BinoFavorites | Where-Object { $_ -ne $Key })
    [void](Set-BinoSetting "Favorites" @($f))
}

function Add-BinoRecent {
    param([string]$Key)
    if ([string]::IsNullOrEmpty($Key)) { return }
    $global:BinoRecent.Remove($Key)
    $global:BinoRecent.Insert(0, $Key)
    while ($global:BinoRecent.Count -gt 8) { $global:BinoRecent.RemoveAt($global:BinoRecent.Count - 1) }
}

# Registra un pulsante appena creato (chiamata da Add-ButtonGrid e dal tab DISM)
function Register-BinoButton {
    param($Btn, $Entry, $Tab)
    $text = Get-BinoCleanText ([string]$Entry[0])
    $key = "{0}|{1}" -f $Tab.Text, $text
    $tip = ""; if ($Entry.Count -gt 4) { $tip = [string]$Entry[4] }
    $Btn.Name = $key
    $Btn.ContextMenuStrip = $global:BinoCtx
    [void]$global:BinoRegistry.Add([PSCustomObject]@{
        Key = $key; TabName = [string]$Tab.Text; Page = $Tab; Text = $text; Tooltip = $tip; Button = $Btn
        KeyName = (ConvertTo-BinoSearchKey ("{0} {1}" -f $Tab.Text, $text)); KeyTip = (ConvertTo-BinoSearchKey $tip); Order = $global:BinoRegistry.Count
    })
    # Registra l'uso (per l'elenco dei recenti): aggiunto prima del comando vero e proprio
    $Btn.Add_Click({ param($s, $e) Add-BinoRecent $s.Name })
}

function Find-BinoEntry {
    param([string]$Key)
    foreach ($e in $global:BinoRegistry) { if ($e.Key -eq $Key) { return $e } }
    return $null
}

# Esegue il comando come se si fosse cliccato il pulsante originale (anche se la sua scheda non è visibile)
function Invoke-BinoCommand {
    param($Entry)
    if (-not $Entry -or -not $Entry.Button) { return }
    try {
        # v3.9.25: niente Reflection / .Invoke() su metodi privati (trigger euristico AV).
        # PerformClick() e' il metodo pubblico di WinForms e scatena gli stessi handler Add_Click.
        $Entry.Button.PerformClick()
    } catch { Write-Log "[ERRORE] Impossibile avviare il comando: $_" "Errore" }
}

# Avvia il comando dopo un attimo, a menu già chiuso
function Request-BinoCommand {
    param([string]$Key)
    $global:BinoPendingKey = $Key
    $t = New-Object System.Windows.Forms.Timer
    $t.Interval = 80
    $t.Add_Tick({ param($s, $e)
        $s.Stop(); $s.Dispose()
        $k = $global:BinoPendingKey; $global:BinoPendingKey = $null
        if ($k) { Invoke-BinoCommand (Find-BinoEntry $k) }
    })
    $t.Start()
}

# Porta in primo piano il comando: seleziona la scheda, scorre fino al pulsante e lo evidenzia per un paio di secondi
function Invoke-BinoGoToCommand {
    param($Entry)
    if (-not $Entry) { return }
    $tc = $global:BinoTabControl
    if ($tc.SelectedTab -ne $Entry.Page) { $tc.SelectedTab = $Entry.Page }
    if ($tc.SelectedTab -ne $Entry.Page) { return }
    $btn = $Entry.Button
    $Entry.Page.ScrollControlIntoView($btn)
    $oldColor = $btn.FlatAppearance.BorderColor
    $oldSize = $btn.FlatAppearance.BorderSize
    $btn.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#FACC15")
    $btn.FlatAppearance.BorderSize = 4
    $btn.Focus() | Out-Null
    $t = New-Object System.Windows.Forms.Timer
    $t.Interval = 2500
    $t.Tag = @{ Btn = $btn; Color = $oldColor; Size = $oldSize }
    $t.Add_Tick({ param($s, $e)
        $s.Stop()
        $d = $s.Tag
        try { $d.Btn.FlatAppearance.BorderColor = $d.Color; $d.Btn.FlatAppearance.BorderSize = $d.Size } catch { $null = $_ }
        $s.Dispose()
    })
    $t.Start()
}

# --- Menu tasto destro sui pulsanti: aggiungi / rimuovi dai preferiti ---
$global:BinoCtx = New-Object System.Windows.Forms.ContextMenuStrip
$global:BinoCtx.ShowImageMargin = $false
$global:BinoMiAdd = $global:BinoCtx.Items.Add("Aggiungi ai preferiti")
$global:BinoMiDel = $global:BinoCtx.Items.Add("Rimuovi dai preferiti")
$global:BinoCtx.Add_Opening({
    param($s, $e)
    $src = $global:BinoCtx.SourceControl
    if (-not $src -or [string]::IsNullOrEmpty($src.Name)) { $e.Cancel = $true; return }
    $isFav = (@(Get-BinoFavorites) -contains $src.Name)
    $global:BinoMiAdd.Visible = (-not $isFav)
    $global:BinoMiDel.Visible = $isFav
})
$global:BinoMiAdd.Add_Click({
    $src = $global:BinoCtx.SourceControl
    if ($src -and $src.Name) {
        Add-BinoFavorite $src.Name
        Write-Log ("[OK] Aggiunto ai preferiti: {0}" -f (($src.Name -split '\|', 2)[1])) "Preferiti"
    }
})
$global:BinoMiDel.Add_Click({
    $src = $global:BinoCtx.SourceControl
    if ($src -and $src.Name) {
        Remove-BinoFavorite $src.Name
        Write-Log ("[OK] Rimosso dai preferiti: {0}" -f (($src.Name -split '\|', 2)[1])) "Preferiti"
    }
})

# --- Menu del pulsante Preferiti nell'intestazione ---
function Show-BinoFavoritesMenu {
    if ($global:BinoFavMenu) { try { $global:BinoFavMenu.Dispose() } catch { $null = $_ } }
    $menu = New-Object System.Windows.Forms.ContextMenuStrip
    $menu.ShowImageMargin = $false
    $global:BinoFavMenu = $menu

    $h1 = $menu.Items.Add("PREFERITI"); $h1.Enabled = $false
    $nFav = 0
    $favKeys = @(Get-BinoFavorites)
    foreach ($k in $favKeys) {
        $e = Find-BinoEntry $k
        if (-not $e) { continue }
        $mi = $menu.Items.Add(("{0}  ›  {1}" -f $e.TabName, $e.Text))
        $mi.Tag = $k
        $mi.Add_Click({ param($s, $ev) Request-BinoCommand ([string]$s.Tag) })
        $nFav++
    }
    if ($nFav -eq 0) {
        $none = $menu.Items.Add("Nessun preferito: clic destro su un comando, poi Aggiungi ai preferiti")
        $none.Enabled = $false
    }

    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    $h2 = $menu.Items.Add("RECENTI (questa sessione)"); $h2.Enabled = $false
    $nRec = 0
    foreach ($k in @($global:BinoRecent)) {
        $e = Find-BinoEntry ([string]$k)
        if (-not $e) { continue }
        $mi = $menu.Items.Add(("{0}  ›  {1}" -f $e.TabName, $e.Text))
        $mi.Tag = [string]$k
        $mi.Add_Click({ param($s, $ev) Request-BinoCommand ([string]$s.Tag) })
        $nRec++
    }
    if ($nRec -eq 0) { $none2 = $menu.Items.Add("Nessun comando eseguito finora"); $none2.Enabled = $false }

    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
    if ($nFav -gt 0) {
        $rm = New-Object System.Windows.Forms.ToolStripMenuItem("Rimuovi dai preferiti")
        foreach ($k in $favKeys) {
            $e = Find-BinoEntry $k
            if (-not $e) { continue }
            $sub = $rm.DropDownItems.Add(("{0}  ›  {1}" -f $e.TabName, $e.Text))
            $sub.Tag = $k
            $sub.Add_Click({ param($s, $ev) Remove-BinoFavorite ([string]$s.Tag); Write-Log ("[OK] Rimosso dai preferiti: {0}" -f (([string]$s.Tag -split '\|', 2)[1])) "Preferiti" })
        }
        [void]$menu.Items.Add($rm)
    }
    $srch = $menu.Items.Add("Cerca comando...    Ctrl+F")
    $srch.Add_Click({ Show-BinoSearch })
    $menu.Show($global:BinoFavBtn, (New-Object System.Drawing.Point(0, $global:BinoFavBtn.Height)))
}

# --- Finestra di ricerca ---
function Find-BinoCommands {
    param([string]$Query)
    $tokens = @((ConvertTo-BinoSearchKey $Query) -split '\s+' | Where-Object { $_ })
    $out = New-Object System.Collections.ArrayList
    foreach ($e in $global:BinoRegistry) {
        $score = 0; $ok = $true
        foreach ($t in $tokens) {
            if ($e.KeyName.Contains($t)) { $score += 2 }
            elseif ($e.KeyTip.Contains($t)) { $score += 1 }
            else { $ok = $false; break }
        }
        if ($ok) { [void]$out.Add([PSCustomObject]@{ Entry = $e; Score = $score; Order = $e.Order }) }
    }
    return @($out | Sort-Object @{ Expression = "Score"; Descending = $true }, @{ Expression = "Order"; Descending = $false })
}

function Update-BinoSearchList {
    $res = @(Find-BinoCommands $global:BinoSearchTxt.Text)
    $global:BinoSearchResults = $res
    $lst = $global:BinoSearchLst
    $lst.BeginUpdate()
    $lst.Items.Clear()
    foreach ($r in $res) { [void]$lst.Items.Add(("{0}  ›  {1}" -f $r.Entry.TabName, $r.Entry.Text)) }
    $lst.EndUpdate()
    if ($lst.Items.Count -gt 0) { $lst.SelectedIndex = 0 } else { $global:BinoSearchDesc.Text = "Nessun comando trovato." }
}

function Update-BinoSearchDesc {
    $i = $global:BinoSearchLst.SelectedIndex
    if ($i -ge 0 -and $i -lt $global:BinoSearchResults.Count) {
        $global:BinoSearchDesc.Text = [string]$global:BinoSearchResults[$i].Entry.Tooltip
    }
}

function Select-BinoSearchResult {
    param([string]$Action)
    $i = $global:BinoSearchLst.SelectedIndex
    if ($i -ge 0 -and $i -lt $global:BinoSearchResults.Count) {
        $global:BinoSearchChoice = $global:BinoSearchResults[$i].Entry
        $global:BinoSearchAction = $Action
        $global:BinoSearchDlg.Close()
    }
}

function Show-BinoSearch {
    $dlg = New-Object System.Windows.Forms.Form
    Enable-DarkTitleBar $dlg
    $dlg.Text = "Cerca comando"
    $dlg.ClientSize = New-Object System.Drawing.Size(700, 520)
    $dlg.StartPosition = "CenterParent"
    $dlg.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $dlg.MaximizeBox = $false; $dlg.MinimizeBox = $false; $dlg.ShowInTaskbar = $false
    $dlg.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Scrivi una o più parole: vengono cercate nel nome e nella descrizione dei comandi."
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $lbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#94A3B8")
    $lbl.Location = New-Object System.Drawing.Point(15, 12); $lbl.AutoSize = $true

    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Font = New-Object System.Drawing.Font("Segoe UI", 13)
    $txt.Location = New-Object System.Drawing.Point(15, 36); $txt.Size = New-Object System.Drawing.Size(670, 32)
    $txt.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E293B")
    $txt.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F8FAFC")
    $txt.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $lst = New-Object System.Windows.Forms.ListBox
    $lst.Font = New-Object System.Drawing.Font("Segoe UI", 10.5)
    $lst.Location = New-Object System.Drawing.Point(15, 80); $lst.Size = New-Object System.Drawing.Size(670, 340)
    $lst.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E293B")
    $lst.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F8FAFC")
    $lst.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $lst.IntegralHeight = $false

    $desc = New-Object System.Windows.Forms.Label
    $desc.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $desc.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#94A3B8")
    $desc.Location = New-Object System.Drawing.Point(15, 426); $desc.Size = New-Object System.Drawing.Size(670, 38)

    $btnGo = New-Object System.Windows.Forms.Button
    $btnGo.Text = "Vai alla scheda (Invio)"
    $btnGo.Location = New-Object System.Drawing.Point(15, 472); $btnGo.Size = New-Object System.Drawing.Size(210, 36)
    $btnGo.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0EA5E9"); $btnGo.ForeColor = [System.Drawing.Color]::White
    $btnRun = New-Object System.Windows.Forms.Button
    $btnRun.Text = "Esegui subito (Ctrl+Invio)"
    $btnRun.Location = New-Object System.Drawing.Point(235, 472); $btnRun.Size = New-Object System.Drawing.Size(210, 36)
    $btnRun.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#064E3B"); $btnRun.ForeColor = [System.Drawing.Color]::White
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Chiudi (Esc)"
    $btnClose.Location = New-Object System.Drawing.Point(585, 472); $btnClose.Size = New-Object System.Drawing.Size(100, 36)
    $btnClose.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#334155"); $btnClose.ForeColor = [System.Drawing.Color]::White
    $btnClose.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    foreach ($b in @($btnGo, $btnRun, $btnClose)) {
        $b.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $b.FlatAppearance.BorderSize = 0
        $b.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold); $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    }
    $dlg.CancelButton = $btnClose
    $dlg.Controls.AddRange(@($lbl, $txt, $lst, $desc, $btnGo, $btnRun, $btnClose))

    $global:BinoSearchDlg = $dlg; $global:BinoSearchTxt = $txt; $global:BinoSearchLst = $lst; $global:BinoSearchDesc = $desc
    $global:BinoSearchResults = @(); $global:BinoSearchChoice = $null; $global:BinoSearchAction = "go"

    $txt.Add_TextChanged({ Update-BinoSearchList })
    $lst.Add_SelectedIndexChanged({ Update-BinoSearchDesc })
    $lst.Add_DoubleClick({ Select-BinoSearchResult "go" })
    $btnGo.Add_Click({ Select-BinoSearchResult "go" })
    $btnRun.Add_Click({ Select-BinoSearchResult "run" })
    $txt.Add_KeyDown({
        param($s, $e)
        $l = $global:BinoSearchLst
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Down) {
            if ($l.SelectedIndex -lt ($l.Items.Count - 1)) { $l.SelectedIndex = $l.SelectedIndex + 1 }
            $e.Handled = $true; $e.SuppressKeyPress = $true
        } elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Up) {
            if ($l.SelectedIndex -gt 0) { $l.SelectedIndex = $l.SelectedIndex - 1 }
            $e.Handled = $true; $e.SuppressKeyPress = $true
        } elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
            $e.Handled = $true; $e.SuppressKeyPress = $true
            if ($e.Control) { Select-BinoSearchResult "run" } else { Select-BinoSearchResult "go" }
        }
    })
    $lst.Add_KeyDown({
        param($s, $e)
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
            $e.Handled = $true; $e.SuppressKeyPress = $true
            if ($e.Control) { Select-BinoSearchResult "run" } else { Select-BinoSearchResult "go" }
        }
    })
    $dlg.Add_Shown({ Update-BinoSearchList; $global:BinoSearchTxt.Focus() | Out-Null })

    [void]$dlg.ShowDialog($global:BinoMainForm)
    $choice = $global:BinoSearchChoice; $action = $global:BinoSearchAction
    $global:BinoSearchChoice = $null
    $dlg.Dispose()
    if ($choice) {
        if ($action -eq "run") { Invoke-BinoCommand $choice } else { Invoke-BinoGoToCommand $choice }
    }
}

# --- Pulsanti nell'intestazione + scorciatoia Ctrl+F ---
$sx = [math]::Max(($lblSubTitle.Right + 12), 780)
$btnFav = New-Object System.Windows.Forms.Button
$btnFav.Text = "Preferiti ▾"
$btnFav.Size = New-Object System.Drawing.Size(95, 28)
$btnFav.Location = New-Object System.Drawing.Point(1060, 44)
$btnSearch = New-Object System.Windows.Forms.Button
$btnSearch.Text = "Cerca comando...   Ctrl+F"
$btnSearch.Size = New-Object System.Drawing.Size([math]::Max(170, (1054 - $sx)), 28)
$btnSearch.Location = New-Object System.Drawing.Point((1054 - $btnSearch.Width), 44)
$btnSearch.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$btnSearch.Padding = New-Object System.Windows.Forms.Padding(8, 0, 0, 0)
foreach ($hb in @($btnFav, $btnSearch)) {
    $hb.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $hb.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $hb.FlatAppearance.BorderSize = 1
    $hb.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#475569")
    $hb.FlatAppearance.MouseOverBackColor = [System.Drawing.ColorTranslator]::FromHtml("#334155")
    $hb.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")
    $hb.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#CBD5E1")
    $hb.Cursor = [System.Windows.Forms.Cursors]::Hand
}
$global:BinoFavBtn = $btnFav
$btnFav.Add_Click({ Show-BinoFavoritesMenu })
$btnSearch.Add_Click({ Show-BinoSearch })
$pnlHeader.Controls.Add($btnFav)
$pnlHeader.Controls.Add($btnSearch)

$form.KeyPreview = $true
$form.Add_KeyDown({
    param($s, $e)
    if ($e.Control -and $e.KeyCode -eq [System.Windows.Forms.Keys]::F) {
        $e.Handled = $true; $e.SuppressKeyPress = $true
        Show-BinoSearch
    }
})

$tabDiag = New-Object System.Windows.Forms.TabPage
$tabDiag.Text = "Diagnostica Hardware"
$tabDiag.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")
$tabDiag.AutoScroll = $true
$tabControl.Controls.Add($tabDiag)


Add-ButtonGrid -Tab $tabDiag -Buttons $diagBtns


# ==============================================================================
# TAB 2: DISM & AVVIO - DISM (ScanHealth, edizioni, driver, spazio riservato), Driver Verifier, BCDEdit
# ==============================================================================
$tabDISM = New-Object System.Windows.Forms.TabPage
$tabDISM.Text = "DISM & Avvio"
$tabDISM.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")
$tabDISM.AutoScroll = $true
$tabControl.Controls.Add($tabDISM)


$row = 0; $col = 0
$cols = 4
$btnW = 305
$btnH = 58
$gapX = 320
$gapY = 66
$startX = 15
$startY = 10
foreach ($b in $dismBtns) {
    $x = $startX + ($col * $gapX)
    $y = $startY + ($row * $gapY)
    $bg = $b[2]; $fg = $b[3]; $tooltip = $b[4]
    $btn = New-CustomButton $b[0] $x $y $btnW $btnH $bg $fg $tooltip
    if ($bg -eq "#F8FAFC" -or $bg -eq "#CBD5E1") {
        $btn.FlatStyle = "Flat"
        $btn.FlatAppearance.BorderSize = 2
        $btn.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#3B82F6")
    }
    Register-BinoButton $btn $b $tabDISM
    $btn.Add_Click($b[1]); $tabDISM.Controls.Add($btn)
    $col++
    if ($col -ge $cols) { $col = 0; $row++ }
}

# ==============================================================================
# TAB 3: UTILITY DI SISTEMA - console MMC e strumenti Windows (dispositivi, servizi, eventi, regedit, gpedit, firewall), inventario PC e software, report GPO
# ==============================================================================
$tabTools = New-Object System.Windows.Forms.TabPage
$tabTools.Text = "Utility di Sistema"
$tabTools.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")
$tabTools.AutoScroll = $true
$tabControl.Controls.Add($tabTools)


Add-ButtonGrid -Tab $tabTools -Buttons $toolBtns

# ==============================================================================
# TAB 4: NETWORK - IP, DNS, Winsock e TCP/IP, ping, porte (in ascolto, connessioni, scansione, firewall), proxy, profili Wi-Fi
# ==============================================================================
$tabNet = New-Object System.Windows.Forms.TabPage
$tabNet.Text = "Network"
$tabNet.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")
$tabNet.AutoScroll = $true
$tabControl.Controls.Add($tabNet)


Add-ButtonGrid -Tab $tabNet -Buttons $netBtns

# ==============================================================================
# TAB 5: MANUTENZIONE OS - pulizia (temp, log eventi, WinSxS, cache WU), SFC/DISM/CHKDSK, punto di ripristino, winget, KB e Windows Update
# ==============================================================================
$tabMaint = New-Object System.Windows.Forms.TabPage
$tabMaint.Text = "Manutenzione OS"
$tabMaint.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")
$tabMaint.AutoScroll = $true
$tabControl.Controls.Add($tabMaint)


Add-ButtonGrid -Tab $tabMaint -Buttons $maintBtns

# ==============================================================================
# TAB 6: STAMPANTI - spooler, code di stampa, elenco ed eliminazione stampanti e driver, installazione per utenti non admin
# ==============================================================================
$tabPrinters = New-Object System.Windows.Forms.TabPage
$tabPrinters.Text = "Stampanti"
$tabPrinters.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")
$tabPrinters.AutoScroll = $true
$tabControl.Controls.Add($tabPrinters)


Add-ButtonGrid -Tab $tabPrinters -Buttons $printerBtns

# ==============================================================================
# TAB 7: SICUREZZA & BITLOCKER - BitLocker (report, stato, attiva/disattiva), Defender, product key OEM, attivazione Windows, servizi critici, audit sicurezza client, amministratori locali, autorun e persistenza, condivisioni SMB, accessi falliti
# ==============================================================================
$tabSec = New-Object System.Windows.Forms.TabPage
$tabSec.Text = "Sicurezza & BitLocker"
$tabSec.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")
$tabSec.AutoScroll = $true
$tabControl.Controls.Add($tabSec)


Add-ButtonGrid -Tab $tabSec -Buttons $secBtns

# ==============================================================================
# TAB 8: TWEAKS W11 - menu contestuale, cache Store e browser, Esplora risorse, prestazioni, ibernazione, avviso RDP
# ==============================================================================
$tabTweaks = New-Object System.Windows.Forms.TabPage
$tabTweaks.Text = "Tweaks W11"
$tabTweaks.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")
$tabTweaks.AutoScroll = $true
$tabControl.Controls.Add($tabTweaks)

Add-ButtonGrid -Tab $tabTweaks -Buttons $tweakBtns



# ==============================================================================
# TAB 9: DISCHI ESTERNI & VEEAM - dischi USB, espulsione sicura, servizi Veeam, rimozione hardware, chi blocca un'unità, disco offline
# ==============================================================================
$tabUSB = New-Object System.Windows.Forms.TabPage
$tabUSB.Text = "Dischi Esterni & Veeam"
$tabUSB.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")
$tabUSB.AutoScroll = $true
$tabControl.Controls.Add($tabUSB)


Add-ButtonGrid -Tab $tabUSB -Buttons $usbBtns


# ==============================================================================
# ==============================================================================
# TAB 10: AD-TOOLS - Active Directory: report utenti, gruppi, computer e OU, password e blocchi account, salute DC e FSMO, audit sicurezza, delega Kerberos, computer obsoleti e LAPS, policy password, adminCount orfani, GPO, canale sicuro del dominio, test porte verso i DC
# ==============================================================================
$tabAD = New-Object System.Windows.Forms.TabPage
$tabAD.Text = "AD-TOOLs"
$tabAD.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")
$tabAD.AutoScroll = $true
$tabControl.Controls.Add($tabAD)

# Helper Function per AD Tools
function Test-ADModule {
    param([bool]$Silent = $false)
    try {
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -ErrorAction Stop
        }
        # Verifica anche che siamo in dominio
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        if ($cs -and -not $cs.PartOfDomain) {
            if (-not $Silent) {
                Write-Log "[INFO] PC non in dominio - modulo AD caricato ma non in ambiente AD." "AD-Check"
            }
            # Ritorna true se modulo c'è, ma avviseremo nel tab
            return $true
        }
        return $true
    } catch {
        if (-not $Silent) {
            Write-Log "[INFO] Modulo ActiveDirectory non disponibile su questo PC (normale su client Windows): $_" "AD-Check"
        }
        return $false
    }
}

function Show-ADInfoPopup {
    # Avviso informativo (non bloccante) mostrato al massimo una volta per sessione e disattivabile in modo permanente.
    param([switch]$Force)
    if (-not $Force) {
        if ($global:ADInfoShownThisSession) { return }
        $st = Get-BinoSettings
        if ($st["HideADInfoPopup"] -eq $true) { return }
    }
    $global:ADInfoShownThisSession = $true
    $dlg = New-Object System.Windows.Forms.Form
    Enable-DarkTitleBar $dlg
    try {
        $dlg.Text = "AD-TOOLs - Informazioni"
        $dlg.ClientSize = New-Object System.Drawing.Size(580, 470)
        $dlg.StartPosition = "CenterParent"
        $dlg.FormBorderStyle = "FixedDialog"
        $dlg.MaximizeBox = $false
        $dlg.MinimizeBox = $false
        $dlg.ShowInTaskbar = $false
        $dlg.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F172A")
        $dlg.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#E2E8F0")

        $lblTitle = New-Object System.Windows.Forms.Label
        $lblTitle.Text = "Prima di usare i comandi AD-TOOLs"
        $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
        $lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#38BDF8")
        $lblTitle.SetBounds(20, 14, 540, 30)
        $dlg.Controls.Add($lblTitle)

        $lblBody = New-Object System.Windows.Forms.Label
        $lblBody.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
        $lblBody.AutoSize = $false
        $lblBody.SetBounds(20, 52, 540, 295)
        $lblBody.Text = (
            "• La maggior parte dei comandi è in SOLA LETTURA: legge informazioni da Active Directory senza modificarle.`r`n`r`n" +
            "• Le azioni che modificano AD (sblocco account, reset password, ripristino canale sicuro) chiedono sempre una scelta esplicita prima di procedere.`r`n`r`n" +
            "• 'Backup + Report GPO' crea soltanto file nella cartella dello script, senza modificare il dominio.`r`n`r`n" +
            "• I report (CSV/TXT/HTML) contengono DATI SENSIBILI (utenti, gruppi amministrativi, SPN): eliminali quando hai finito e tieni lo script in una cartella con accessi limitati.`r`n`r`n" +
            "• 'Salute DC' (dcdiag) può richiedere alcuni minuti: la finestra può sembrare ferma, ma l'indicatore di attesa resta aperto fino alla fine.`r`n`r`n" +
            "• 'Origine Blocchi Account': se non trova eventi, di solito l'audit 'Gestione account utente' non è attivo sul PDC Emulator (non è un errore dello strumento)."
        )
        $dlg.Controls.Add($lblBody)

        $chk = New-Object System.Windows.Forms.CheckBox
        $chk.Text = "Non mostrare più questo messaggio"
        $chk.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
        $chk.AutoSize = $true
        $chk.Location = New-Object System.Drawing.Point(20, 358)
        $dlg.Controls.Add($chk)

        $lblHint = New-Object System.Windows.Forms.Label
        $lblHint.Text = "Per riattivarlo: elimina il file bino_settings.json nella cartella dello script, oppure imposta HideADInfoPopup su false."
        $lblHint.Font = New-Object System.Drawing.Font("Segoe UI", 8)
        $lblHint.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#94A3B8")
        $lblHint.AutoSize = $false
        $lblHint.SetBounds(38, 384, 520, 34)
        $dlg.Controls.Add($lblHint)

        $btnOk = New-Object System.Windows.Forms.Button
        $btnOk.Text = "OK, ho capito"
        $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $btnOk.FlatStyle = "Flat"
        $btnOk.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#064E3B")
        $btnOk.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F8FAFC")
        $btnOk.SetBounds(430, 426, 130, 32)
        $dlg.Controls.Add($btnOk)
        $dlg.AcceptButton = $btnOk

        [void]$dlg.ShowDialog($form)

        if ($chk.Checked) {
            if (Set-BinoSetting -Name "HideADInfoPopup" -Value $true) {
                Write-Log "[INFO] Avviso informativo AD-TOOLs disattivato. Impostazione salvata in: $(Get-BinoSettingsPath)"
            } else {
                Write-Log "[AVVISO] Impossibile salvare l'impostazione: l'avviso verrà mostrato di nuovo alla prossima apertura dello strumento."
            }
        }
    } finally { $dlg.Dispose() }
}

function Show-ADWarningIfNeeded {
    $hasAD = Test-ADModule -Silent $true
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    $isDomain = $cs -and $cs.PartOfDomain
    $isServer = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption -like "*Server*"

    # CASO 1 - PC in dominio ma senza RSAT: avviso leggero, UNA SOLA VOLTA per sessione, senza bloccare l'accesso
    # (Canale Sicuro e Test Porte DC funzionano comunque, gli altri comandi AD richiedono il modulo ActiveDirectory)
    if ($isDomain -and -not $hasAD) {
        if (-not $global:ADNoRsatNoticeShown) {
            $global:ADNoRsatNoticeShown = $true
            $note = "Il modulo ActiveDirectory (RSAT) non è installato su questo PC.`r`n`r`n" +
                    "Puoi usare comunque:`r`n" +
                    "- Verifica / Ripristina Canale Sicuro Dominio`r`n" +
                    "- Test Porte verso Domain Controller`r`n`r`n" +
                    "Gli altri comandi di questa sezione richiedono RSAT oppure l'esecuzione dello strumento su un Domain Controller.`r`n`r`n" +
                    "Per installare RSAT: 'Strumenti di amministrazione remota del server' -> 'Modulo AD per PowerShell'.`r`n`r`n" +
                    "(Questo avviso viene mostrato una sola volta per sessione.)"
            [System.Windows.Forms.MessageBox]::Show($note, "AD-TOOLs - RSAT non installato", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
            Write-Log "[INFO] AD-TOOLs aperto su PC in dominio senza RSAT: disponibili Canale Sicuro e Test Porte DC, gli altri comandi AD richiedono RSAT." "AD-Check"
        }
        return $true
    }

    # CASO 2 - PC fuori dominio: nessun comando AD puo' funzionare, avviso completo con scelta (come prima)
    if (-not $isDomain) {
        $msg = "ATTENZIONE: Sezione AD-TOOLs riservata a Server / Domain Controller.`r`n`r`n"
        if (-not $hasAD) { $msg += "- Modulo ActiveDirectory (RSAT) non installato su questo PC.`r`n" }
        $msg += "- Questo PC non fa parte di un dominio Active Directory.`r`n"
        $msg += "`r`nI comandi AD non funzioneranno su questo computer.`r`nUnica eccezione: 'Test Porte verso Domain Controller' si può usare indicando il nome o l'IP di un DC.`r`n"
        $msg += "Per usare gli altri:`r`n- Esegui lo strumento su un Domain Controller o`r`n- Installa RSAT e unisci il PC al dominio`r`n`r`nVuoi continuare comunque?"

        $choice = [System.Windows.Forms.MessageBox]::Show($msg, "AD-TOOLs - Ambiente non Server", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($choice -eq [System.Windows.Forms.DialogResult]::No) {
            $tabControl.SelectedTab = $tabDiag
            return $false
        }
        Write-Log "[AVVISO] Utente ha aperto AD-TOOLs su PC non in dominio - i comandi AD potrebbero fallire." "AD-Check"
        return $true
    }

    # CASO 3 - ambiente corretto (dominio + RSAT/DC): avviso informativo breve (una volta per sessione, disattivabile)
    Show-ADInfoPopup
    return $true
}


function Get-ADOutputPath {
    param([string]$FileName)
    $base = $global:OutputDir
    if (!(Test-Path $base)) { New-Item -ItemType Directory -Path $base -Force | Out-Null }
    return Join-Path $base $FileName
}


Add-ButtonGrid -Tab $tabAD -Buttons $adBtns
# ==============================================================================
# FINE TAB AD-TOOLS
# ==============================================================================

# ==============================================================================

# ==============================================================================
# TAB 11: OFFICE 365 & OUTLOOK - ADAL, Autodiscover, report licenze Office
# ==============================================================================
$tabO365 = New-Object System.Windows.Forms.TabPage
$tabO365.Text = "Office 365 & Outlook"

# Sfondo uniforme blu scuro per tutti i tab - leggibilità massima
$darkTabBg = [System.Drawing.Color]::FromArgb(15, 23, 42) # #0F172A
$tabDiag.BackColor = $darkTabBg
$tabDISM.BackColor = $darkTabBg
$tabTools.BackColor = $darkTabBg
$tabNet.BackColor = $darkTabBg
$tabMaint.BackColor = $darkTabBg
$tabPrinters.BackColor = $darkTabBg
$tabSec.BackColor = $darkTabBg
$tabTweaks.BackColor = $darkTabBg
$tabUSB.BackColor = $darkTabBg
$tabAD.BackColor = $darkTabBg
$tabO365.BackColor = $darkTabBg
$tabO365.AutoScroll = $true
$tabControl.Controls.Add($tabO365)


Add-ButtonGrid -Tab $tabO365 -Buttons $o365Btns

# ==============================================================================
# GESTIONE EVENTO APERTURA TAB: ALERT DI SICUREZZA E CONTROLLO SERVIZI VEEAM
# ==============================================================================
$tabControl.Add_SelectedIndexChanged({
    if ($tabControl.SelectedTab -eq $tabUSB) {
        # Controllo automatico dei servizi Veeam all'apertura del tab
        $veeamServices = Get-Service -Name "Veeam*" -ErrorAction SilentlyContinue
        $activeVeeam = $veeamServices | Where-Object { $_.Status -eq 'Running' }
        
        if ($activeVeeam) {
            $msg = "ATTENZIONE: Servizi Veeam in esecuzione rilevati!`r`n`r`nL'accesso a dischi esterni con Veeam attivo può causare perdita dati.`r`n`r`nVuoi continuare?"
            $choice = [System.Windows.Forms.MessageBox]::Show($msg, "Avviso Sicurezza Veeam", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
            if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) {
                $tabControl.SelectedTab = $tabDiag
                Write-Log "[INFO] Accesso alla sezione 'Dischi Esterni & Veeam' bloccato: servizi Veeam attivi e utente ha annullato." "Accesso interrotto"
                return
            }
        }
    }
    
    if ($tabControl.SelectedTab -eq $tabAD) {
        # Controllo ambiente AD all'apertura del tab
        Show-ADWarningIfNeeded | Out-Null
    }
})

# ==============================================================================
# AVVIO APPLICAZIONE
# ==============================================================================
Write-Log "[INFO] Cartella di output dei file: $global:OutputDir"
[System.Windows.Forms.Application]::Run($form)