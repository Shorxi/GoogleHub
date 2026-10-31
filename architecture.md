# 📘 architecture.md  
### *Technische Architektur – Google Ecosystem Desktop Hub V2*

---

## 🟦 **Überblick**
Der **Google Ecosystem Desktop Hub V2** ist ein kompakter Windows‑Launcher, der vollständig über ein PowerShell‑Build‑Script (`build.ps1`) generiert wird.  
Das Tool besteht aus **einem einzigen C#‑Quellcodeblock**, der zur Laufzeit kompiliert wird, sowie einer dynamisch erzeugten Icon‑Datei.

Es ist **kein klassisches Visual‑Studio‑Projekt**, sondern ein **self‑contained Build‑System**, das alles automatisch erzeugt.

---

## 🧩 **Architekturkomponenten**

### 🔹 **1. PowerShell‑Buildsystem (`build.ps1`)**
Das Build‑Script übernimmt:

- Erzeugung des Google-Icons (3x3-Raster-Symbol)
- Schreiben des kompletten C#‑Quellcodes in eine temporäre Datei
- Kompilierung der EXE über den Windows-internen C#-Compiler (`Add-Type` / `csc.exe`)
- Platzierung der fertigen EXE auf dem Desktop
- Beenden alter Instanzen, damit die EXE bei Updates nahtlos überschrieben werden kann

Das Buildsystem ist der **Kern des Projekts**.

---

### 🔹 **2. C#‑Anwendung (dynamisch kompiliert)**
Der gesamte C#‑Code wird im Build‑Script als String gespeichert und kompiliert.  
Die Anwendung besteht aus mehreren Klassen:

#### **ChromeAccountDetector**
- Erkennung von aktiven Google-Konten
- Chrome-Profil-Scan (Auslesen von `Local State` & `Preferences`)
- Starten von URLs im Chrome-App-Modus (`--app`)
- Intelligente Fallback-Logik (Weiterleitung zum Google-Login, wenn kein Konto erkannt wurde)

#### **InlineSearchEngine**
- Wikipedia DE Summary API (für KI-Wissens-Übersichten)
- Wikipedia Search API (für lexikalische Begriffsdefinitionen)
- Google News RSS (für aktuelle Web- und Nachrichtenbeiträge)
- Google Search Web Fallback
- HTML‑Stripper
- JSON‑Decoder
- Stopword‑Cleaner (Filtert "Erkläre mir was ein...", "Was ist..." heraus)
- Aufbereitung der Ergebnisliste für die Inline‑Ansicht

#### **AppItem**
- Struktur für App‑Kacheln (Name, Kategorie, URL, Badge, Farbe)

#### **HubPopupForm**
- Hauptfenster des Launchers  
- Dynamisches App‑Grid  
- Inline‑Search‑Ansicht mit automatischem Rendering der Suchergebnisse 
- Account‑Banner mit Live-Status
- Konto / Login-Button
- Autostart‑Option (Windows Registry)
- AppMode‑Option
- Moderne Dark‑Mode-UI

#### **LauncherOrbForm**
- Kleines Orb‑Fenster (mit 3x3-Punkte-Branding)
- Auto‑Slide‑Docking (Fährt bei Inaktivität seitlich in den Bildschirmrand)
- AlwaysOnTop (Immer im Vordergrund)
- Öffnet das Hub-Menü per Klick
- Mechanisches Verriegelungsschloss (Sperren der X/Y-Koordinaten)

#### **ConfigManager**
- Speichert Einstellungen lokal in `%AppData%\GoogleEcosystemHub\settings.ini`:
  - `PosX` / `PosY`
  - `AlwaysOnTop`
  - `UseAppMode`
  - `AutoSlideEdge`
  - `IsLocked`

---

## 🔹 **3. Icon‑Generator**
Das Icon wird im Build‑Script on-the-fly erzeugt:

- 64×64 Bitmap  
- Dunkelgrauer Hintergrund mit 3x3 weißem Punkteraster (klassisches Google-Launcher-Design)
- ICO‑Header manuell in den Stream geschrieben  
- Speicherung im TEMP‑Ordner (`google_grid_icon.ico`)

---

## 🔹 **4. Build‑Output**
Nach dem Build entstehen folgende Dateien:

```
GoogleEcosystemHub.exe (auf dem Desktop)
google_grid_icon.ico (temporär)
settings.ini (wird beim ersten Start automatisch in AppData erzeugt)
```

---

## 🏗 **Projektstruktur (vereinfacht)**

```
GoogleEcosystemHub/
│
├── build/
│   └── build.ps1
│
├── README.md
├── architecture.md
├── LICENSE
└── .gitignore
```