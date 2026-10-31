# 📘 Google Ecosystem Desktop Hub V2  
### *Kurze Projektbeschreibung & Funktionsübersicht*
<img width="485" height="888" alt="hub" src="https://github.com/user-attachments/assets/7d648429-93a5-41ac-b352-14e87e630735" />

---

## 🟦 **Kurzbeschreibung**
Der **Google Ecosystem Desktop Hub V2** ist ein kompakter, rahmenloser Windows‑Launcher, der das gesamte Google‑Ökosystem in einer einzigen App bündelt.  
Er bietet schnellen Zugriff auf alle relevanten Google‑Dienste, eine integrierte Inline‑Suchmaschine für direkte KI-Antworten und eine moderne Dark‑Mode‑Oberfläche – komplett ohne Telemetrie und vollständig lokal auf deinem System.

---

## 🧩 **Was das Tool enthält**

### 🔹 **1. Chrome‑App‑Mode Launcher**  
Öffnet alle Google‑Dienste direkt als eigenständiges Desktop-Fenster (`--app`) über die Chrome-Engine, ohne störenden Browser‑Rahmen.

### 🔹 **2. Auto‑Slide‑Orb (Docking)**  
Das vertraute 3x3-Punkte-Menü (Launcher-Symbol) kann an den Bildschirmrand gleiten und dort unauffällig als kompakter Orb „parken“.

<img width="148" height="191" alt="Screenshot 2026-10-31 042818" src="https://github.com/user-attachments/assets/d14ec363-6a88-4cc3-bbad-d421662e8e61" />


### 🔹 **3. Inline‑Search Engine (KI‑Übersicht)**  
Die Suchfunktion kombiniert mehrere Datenquellen und liefert Antworten direkt unter der Suchleiste:
- Wikipedia DE Summary API (für KI-Wissens-Snippets)  
- Google News RSS  
- Google Web Fallback  
Ergebnisse werden direkt im Hub angezeigt, ohne ein externes Fenster öffnen zu müssen.

### 🔹 **4. Google Account Detection**  
Das Tool erkennt vollautomatisch dein lokales Setup:
- Auslesen der `Local State` und `Preferences` im lokalen Chrome-Profil  
- Zeigt sofort an, ob ein Google-Konto aktiv eingeloggt ist, um Dienste und Play Points nahtlos zu verknüpfen.

### 🔹 **5. 30+ Google‑Apps integriert**  
Beispiele aus den Favoriten und erweiterten Tools:
- Gemini  
- YouTube & YouTube Music  
- Google Play (Points)  
- Google Workspace (Docs, Sheets, Drive)  
- Maps & Earth  
- Google TV  
- Google Ads & Analytics  
- NotebookLM  
u.v.m.

### 🔹 **6. Nahtlose Account-Sicherheit**  
Ist kein aktives Google-Konto im Chrome-Profil hinterlegt, leitet der Hub bei Bedarf intelligent auf die offizielle Google-Login-Seite (inkl. Weiterleitungs-Parameter) um.

### 🔹 **7. Persistente Einstellungen (INI‑Datei)**  
Speichert dauerhaft:
- Position am Bildschirm  
- AlwaysOnTop (Immer im Vordergrund)  
- Chrome AppMode (--app)  
- AutoSlideEdge (Seitliches Einfahren)

### 🔹 **8. PowerShell‑Buildsystem**  
Im Ordner **build/** liegt die Datei:

```
build.ps1
```

Sie kompiliert das C#-Projekt, erzeugt das 3x3-Grid-Icon und erstellt die native EXE-Datei.

---

## 🛠 **Verzeichnisstruktur (vereinfacht)**

```
GoogleEcosystemHub/
│
├── build/            
│   └── build.ps1     → build.ps1
├── README.md         → Projektbeschreibung
├── LICENSE           → MIT‑Lizenz
├── CONTRIBUTING.md   → Beitragsrichtlinien
└── .gitignore
```

---

## Features
- Chrome‑App‑Mode Launcher (`--app`)
- Auto‑Slide‑Orb (3x3 Punkte Docking)
- Inline‑Search Engine (Wissens-Übersicht & News)
- Google Account Detection (Chrome Profil-Analyse)
- 30+ Google‑Apps im Katalog integriert
- Persistente Einstellungen (INI)
- PowerShell‑Buildsystem (build.ps1)
- Keine Telemetrie, vollständig lokal

---

## 🟦 Funktionen

- **Chrome‑App‑Mode Launcher**  
  Öffnet Google‑Dienste ohne Browser‑Rahmen (`--app`), sodass sie sich wie native Windows-Apps anfühlen.

- **Inline‑Search Engine**  
  Kombiniert mehrere Quellen für direkte Antworten:  
  - KI-Wissens-Extrakte (Wikipedia API)  
  - Google News RSS-Feeds  
  - Direkte Google-Suche als Fallback  
  Ergebnisse erscheinen direkt im Hub mit eigener Scrollbar.

- **Google Account Detection**  
  Erkennt aktive Konten über das Chrome-Profil, um Play Points und Such-Historie perfekt zu synchronisieren.

- **30+ integrierte Google‑Apps**  
  Gemini, Drive, YouTube, Docs, Play Store, Maps, Ads, NotebookLM u.v.m.

- **Persistente Einstellungen (INI)**  
  Speichert Position, AlwaysOnTop, AppMode und die Verriegelung per Schloss-Symbol.
<img width="170" height="81" alt="Unbenannt" src="https://github.com/user-attachments/assets/a09e429f-b51f-42f9-8682-6c70d8417006" />


---

## 🛠 Build

Im Ordner **build/** befindet sich die Datei:

- [build.ps1](build/build.ps1) →
Sie kompiliert das Projekt über den Windows-internen C#-Compiler, erzeugt das Icon und legt die fertige `GoogleEcosystemHub.exe` auf dem Desktop ab.

---

## ⚠️ Wichtiger Hinweis zur Erstellung

Da der Google Ecosystem Desktop Hub **keine offiziell signierte Datei** ist, kann es vorkommen, dass manche Virenscanner die frisch erzeugte EXE fälschlicherweise blockieren oder löschen (sogenannte False-Positives).  
Das ist ein typisches Verhalten bei **selbst kompilierten Tools**, die direkt über PowerShell erstellt werden.

Damit die Erstellung problemlos funktioniert:

1. **Virenscanner kurz deaktivieren**, bevor du `build.ps1` ausführst.  
2. Nach der Erstellung die EXE **in einen festen Ordner verschieben** (z. B. `C:\Tools\GoogleHub\`).  
3. Diesen Ordner oder die EXE **als Ausnahme im Virenscanner eintragen**.  
4. Danach kannst du den Virenscanner **sofort wieder aktivieren**.

Die erzeugte EXE ist **technisch sauber**, enthält **keine Schadsoftware**, führt **keine gefährlichen Systemoperationen** aus und arbeitet **vollständig lokal ohne Telemetrie**.

---

## 📄 Lizenz
- [LICENSE](LICENSE) →
Dieses Projekt verwendet die **MIT‑Lizenz** und ist vollständig frei nutzbar, veränderbar und erweiterbar.

---

## 🤝 Beiträge

Beitragsrichtlinien findest du in:
- [CONTRIBUTING.md](CONTRIBUTING.md)
