# 📄 **CONTRIBUTING.md**  
### *Richtlinien für Beiträge – Microsoft Ecosystem Desktop Hub V1*

---

## 🟦 Überblick
Vielen Dank für dein Interesse, zum **Microsoft Ecosystem Desktop Hub V1** beizutragen!  
Dieses Projekt ist vollständig Open Source (MIT) und lebt davon, dass Entwickler neue Ideen, Verbesserungen und Erweiterungen einbringen.

Dieses Dokument erklärt kurz und klar, wie du beitragen kannst.

---

## 🧩 **Wie du beitragen kannst**

### 🔹 **1. Fehler melden**
Wenn du einen Bug findest, öffne bitte ein Issue mit:
- einer kurzen Beschreibung  
- wie man den Fehler reproduziert  
- deiner Windows‑Version  
- Screenshots (optional)

→ **Issue erstellen**

---

### 🔹 **2. Verbesserungen vorschlagen**
Du kannst jederzeit neue Ideen einreichen:
- neue Microsoft‑Apps  
- UI‑Verbesserungen  
- neue Inline‑Search‑Quellen  
- Performance‑Optimierungen  
- Vorschläge für neue Features  

→ **Feature‑Vorschlag einreichen**

---

### 🔹 **3. Code‑Beiträge (Pull Requests)**
Wenn du Code beitragen möchtest:

1. Forke das Repository  
2. Erstelle einen neuen Branch  
3. Füge deine Änderungen hinzu  
4. Teste die Build‑Pipeline (`build.ps1`)  
5. Erstelle einen Pull Request

Bitte beschreibe im PR:
- was du geändert hast  
- warum du es geändert hast  
- ob es getestet wurde  

→ **Pull Request erstellen**

---

## 🛠 **Build‑System**
Das Projekt wird vollständig über die Datei:

```
build/build.ps1
```

kompiliert.  
Es gibt **keine einzelnen `.cs`‑Dateien** im Repository — der gesamte C#‑Code wird dynamisch im Build‑Script erzeugt.

---

## 📐 **Coding‑Style**
Da der C#‑Code im Build‑Script generiert wird, gelten folgende Regeln:

- klare Struktur  
- keine externen Abhängigkeiten  
- keine Telemetrie  
- keine sensiblen Systemzugriffe  
- kompakte, gut lesbare Klassen  
- Kommentare nur dort, wo sie wirklich nötig sind  

---

## 🔒 **Sicherheit**
Bitte stelle sicher, dass Beiträge:

- keine gefährlichen Systemoperationen enthalten  
- keine Registry‑Schlüssel verändern (außer lesend)  
- keine persönlichen Daten auslesen  
- keine Telemetrie hinzufügen  
- keine Cloud‑Abhängigkeiten einführen  

---

## 📄 **Lizenz**

- [LICENSE](LICENSE)
Alle Beiträge müssen mit der **MIT‑Lizenz** kompatibel sein.  
Mit dem Einreichen eines Pull Requests stimmst du zu, dass dein Beitrag unter der MIT‑Lizenz veröffentlicht wird.

→ **MIT‑Lizenz ansehen**

---

## 🤝 **Danke!**
Jeder Beitrag ob klein oder groß hilft dabei, den Microsoft Ecosystem Desktop Hub weiterzuentwickeln.  
Vielen Dank für deine Unterstützung!
