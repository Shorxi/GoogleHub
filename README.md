# 📘 Google Ecosystem Desktop Hub V2  
### *Kurze Projektbeschreibung & Funktionsübersicht*
<img width="485" height="888" alt="hub" src="https://github.com/user-attachments/assets/7d648429-93a5-41ac-b352-14e87e630735" />

---

## 🟦 **Kurzbeschreibung**
Der **Google Ecosystem Desktop Hub V2** ist ein kompakter, rahmenloser Windows‑Launcher, der das gesamte Google‑Ökosystem in einer einzigen App bündelt.  
Er bietet schnellen Zugriff auf Google‑Dienste, eine integrierte Inline‑Suchmaschine und eine moderne Fluent‑Design‑Oberfläche komplett ohne Telemetrie und vollständig lokal auf deinem System.

---

## 🧩 **Was das Tool enthält**

### 🔹 **1. Edge‑App‑Mode Launcher**  
Öffnet alle Microsoft‑Dienste direkt im Edge‑App‑Fenster (`--app`), ohne Browser‑Rahmen.

### 🔹 **2. Auto‑Slide‑Orb (Docking)**  
Der Launcher kann an den Bildschirmrand gleiten und dort als kleiner Orb „parken“.

<img width="148" height="191" alt="Screenshot 2026-10-31 042818" src="https://github.com/user-attachments/assets/d14ec363-6a88-4cc3-bbad-d421662e8e61" />


### 🔹 **3. Inline‑Search Engine (Copilot‑ähnlich)**  
Die Suchfunktion kombiniert mehrere Quellen:
- Wikipedia Summary  
- Microsoft Learn / Docs API  
- Bing News RSS  
- Bing Web Fallback  

Ergebnisse werden direkt im Hub angezeigt.

### 🔹 **4. Microsoft Account Detection (MSA / Entra ID)**  
Das Tool erkennt:
- Windows‑Registry‑Einträge  
- Edge‑Profil‑Daten  
und zeigt an, ob ein Microsoft‑Konto aktiv ist.

### 🔹 **5. 40+ Microsoft‑Apps integriert**  
Beispiele:
- Outlook  
- OneDrive  
- Copilot  
- Office 365  
- Teams  
- Xbox Cloud  
- MS Store  
- Azure Portal  
- Defender  
- Windows Update  
- Bing Maps  
- Power BI  
u.v.m.

### 🔹 **6. Native Windows‑Protokolle**  
Unterstützt direkte Systemaufrufe:
- `ms-settings:`  
- `windowsdefender:`  

### 🔹 **7. Persistente Einstellungen (INI‑Datei)**  
Speichert:
- Position  
- AlwaysOnTop  
- AppMode  
- AutoSlideEdge  

### 🔹 **8. PowerShell‑Buildsystem**  
Im Ordner **build/** liegt die Datei:

```
build.ps1
```

Sie kompiliert das Projekt und erzeugt die EXE + Icon.

---

## 🛠 **Verzeichnisstruktur (vereinfacht)**

```
MicrosoftEcosystemHub/
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
- Edge‑App‑Mode Launcher (`--app`)
- Auto‑Slide‑Orb (Docking)
- Inline‑Search Engine (Wikipedia / MS Learn / Bing)
- Microsoft Account Detection (MSA / Entra ID)
- 40+ Microsoft‑Apps integriert
- Native Windows‑Protokolle
- Persistente Einstellungen (INI)
- PowerShell‑Buildsystem (build.ps1)
- Keine Telemetrie, vollständig lokal

---

## 🟦 Funktionen

- **Edge‑App‑Mode Launcher**  
  Öffnet Microsoft‑Dienste ohne Browser‑Rahmen (`--app`).

- **Inline‑Search Engine**  
  Kombiniert mehrere Quellen:  
  - Wikipedia Summary  
  - Microsoft Learn / Docs API  
  - Bing News RSS  
  - Bing Web Fallback  
  Ergebnisse erscheinen direkt im Hub.

- **Microsoft Account Detection (MSA / Entra ID)**  
  Erkennt aktive Konten über Registry und Edge‑Profil.

- **40+ integrierte Microsoft‑Apps**  
  Outlook, OneDrive, Copilot, Office, Teams, Xbox Cloud, Azure Portal, Defender, Windows Update u.v.m.

- **Native Windows‑Protokolle**  
  Unterstützt direkte Systemaufrufe wie:  
  - `ms-settings:`  
  - `windowsdefender:`

- **Persistente Einstellungen (INI)**  
  Speichert Position, AlwaysOnTop, AppMode Verriegelung Schloss.
<img width="170" height="81" alt="Unbenannt" src="https://github.com/user-attachments/assets/a09e429f-b51f-42f9-8682-6c70d8417006" />


---

## 🛠 Build

Im Ordner **build/** befindet sich die Datei:

- [build.ps1](build/build.ps1) →
Sie kompiliert das Projekt, erzeugt das Icon und legt die fertige EXE auf dem Desktop ab.

---

## ⚠️ Wichtiger Hinweis zur Erstellung

Da der Google Ecosystem Desktop Hub **keine offiziell signierte Microsoft‑Datei** ist, kann es vorkommen, dass manche Virenscanner die frisch erzeugte EXE fälschlicherweise blockieren oder löschen.  
Das ist ein typisches Verhalten bei **selbst kompilierten Tools**, die nicht digital signiert sind.

Damit die Erstellung problemlos funktioniert:

1. **Virenscanner kurz deaktivieren**, bevor du `build.ps1` ausführst.  
2. Nach der Erstellung die EXE **in einen festen Ordner verschieben** (z. B. `C:\Tools\MicrosoftHub\`).  
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
