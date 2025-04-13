Deutsch | [English](README_en.md)

# jarss (just another rsync shell script)

Bei **jarss** handelt es sich um ein CLI-basiertes Shell-Skript das **rsync** verwendet, um Daten zwischen lokalen Pfaden oder Pfaden, auf die über das Netzwerk mit **SSH-Public-Key-Authentifizierung** zugegriffen werden kann, zu übertragen. Neben **synchronisierten** Datensicherungen unterstützt jarss auch **inkrementelle** Datensicherungen. 

## So funktioniert jarss genau
- ### Synchronisierte Datensicherung
    Bei der ersten Ausführung einer synchronen Datensicherung werden zunächst alle Quelldaten in das gewünschte Zielverzeichnis übertragen, bei allen weiteren Ausführungen werden nur die zwischenzeitlich geänderten, neu hinzugekommenen oder gelöschten Quelldaten mit dem Zielverzeichnis verglichen und entsprechend übertragen. Um einem möglichen Datenverlust vorzubeugen, können bei Bedarf alle zwischenzeitlich gelöschten Daten der Quelle(n) im Ziel für einen vordefinierten Zeitraum in einen Papierkorb mit dem Verzeichnisnamen @recycle verschoben werden. Erst nach Ablauf dieser Aufbewahrungsfrist werden die Daten unwiderruflich gelöscht.

- ### Inkrementelle Datensicherung
    Bei der ersten Ausführung einer inkrementellen Datensicherung werden alle Quelldaten in einem Unterverzeichnis, das nach Datum und Uhrzeit der aktuellen Sicherung benannt ist, in das gewünschte Zielverzeichnis übertragen. Unmittelbar danach wird mittels Symlinks ein Image der aktuellen Sicherung erstellt, das auf den i.d.R. nicht sichtbaren Ordner ~latest verweist, der sich ebenfalls im Zielverzeichnis befindet.

    Beim nächsten und allen weiteren Durchläufen werden die Quelldaten zunächst immer mit dem zuletzt erstellten Image (~latest) der vorherigen Sicherung verglichen. Dann wird im Zielverzeichnis erneut ein Unterverzeichnis mit dem Namen des aktuellen Sicherungsdatums und der aktuellen Sicherungszeit angelegt, wobei diesmal nur alle zwischenzeitlich geänderten oder neu hinzugekommenen Quelldaten übertragen werden, zwischenzeitlich gelöschte Quelldaten werden nicht berücksichtigt. Unveränderte Quelldaten erhalten im Ziel lediglich einen Verweis (sog. Hardlinks) auf die bereits im Image vorhandenen Daten und werden daher nicht erneut übertragen. Dadurch entsteht der Eindruck, dass jede neu erstellte Version den gesamten aktuellen Datenbestand und den damit verbundenen Speicherplatz enthält, obwohl sich der tatsächliche Speicherplatzbedarf nur auf die Änderungen seit der letzten Sicherung beschränkt.

    Um die Anzahl der Versionen zu begrenzen, können diese nach Ablauf einer vordefinierten Zeitspanne in Tagen automatisch gelöscht werden.
 
## Installationshinweise
Mit Hilfe des Kommandozeilenprogramms `curl` kann die Shell-Skript-Datei **jarss.sh** sowie die zugehörigen Konfigurationsdateien **jarss_Konfiguration_GER** bzw. **jarss_Konfiguration_ENU** einfach über ein Terminalprogramm deiner Wahl heruntergeladen werden. Erstelle zunächst ein neues (Unter-)Verzeichnis und wechsle in der Kommandozeile zu dem Verzeichnis, in dem die Shell-Skript-Datei und die Konfigurationsdatei(en) gespeichert werden sollen. Führe dann die folgenden Befehle aus, um die Skriptdatei und die Konfigurationsdatei in das ausgewählte Verzeichnis herunterzuladen.

**Download der Shell-Skript-Datei jarss.sh**

	curl -L https://raw.githubusercontent.com/toafez/jarss/refs/heads/main/scripts/jarss.sh


**Download der deutschen Konfigurationsdatei**

    curl -L https://raw.githubusercontent.com/toafez/jarss/refs/heads/main/scripts/jarss_Konfiguration_GER

**Download der englischen Konfigurationsdatei**

    curl -L https://raw.githubusercontent.com/toafez/jarss/refs/heads/main/scripts/jarss_Configuration_ENU

Führe anschließend im selben (Unter-)Verzeichnis den folgenden Befehl aus, um der Shell-Skript-Datei **jarss.sh** Ausführungsrechte zu erteilen. Dabei ist darauf zu achten, den Befehl als Systembenutzer root auszuführen (zu erkennen an dem vorangestellten sudo-Befehl).

	sudo chmod +x jarss.sh

## Konfigurationsdatei(en) erstellen
Da mit **jarss** mehrere verschiedene Konfigurationen erstellt und somit mehrere Aufgaben nacheinander ausgeführt werden können, ist es sinnvoll, vorab ein Abbild der Original-Konfigurationsdatei **jarss_Configuration_GER** bzw. **jarss_Configuration_ENU** zu erstellen und diesem Abbild einen eindeutigen Namen zu geben, der im besten Fall Rückschlüsse auf die auszuführende Aufgabe zulässt. Dies geschieht am einfachsten mit dem Befehl `mv`, wobei darauf zu achten ist, dass das Datei-Abbild im selben Verzeichnis abgelegt wird, in dem sich auch die Shell-Skript-Datei **jarss.sh** befindet. 

**Syntax:**

	mv [OIGINAL-DATEI] [DATEI-ABBILD]

**Beispiel:**

	mv jarss_Configuration_GER jarss_Backup_auf_USB-Festplatte

## Inhalt der Konfigurationsdatei anpassen
Öffne nun die soeben kopierte und umbenannte Konfigurationsdatei mit einem Texteditor deiner Wahl. In diesem Beispiel wird der Texteditor "nano" verwendet.

**Beispiel:**

	nano jarss_Backup_auf_USB-Festplatte

Es ist normal, dass man sich anfangs von der Textmenge etwas erschlagen fühlt. Bei genauerem Hinsehen stellt man jedoch schnell fest, dass der größte Teil des Textes aus Informationen besteht, die die einzelnen Schritte erklären. Diese Texte erkennt man daran, dass am Anfang jeder Zeile das Zeichen **#** (Doppelkreuz, Pfund oder auch Hash) steht, das eine Kommentarzeile kennzeichnet.

Alle Zeilen, denen **kein** #-Zeichen vorangestellt ist, sind sogenannte **Key/Value-Werte**, umgangssprachlich auch **Variablen** genannt. Die Schreibweise ist immer gleich. Vor dem Gleichheitszeichen steht ein fester Variablenname (Key), der nicht geändert werden darf. Hinter dem Gleichheitszeichen können Werte (Values) vom Benutzer **in Anführungszeichen** eingegeben werden. Um welche Werte es sich handelt, wird in der Regel durch die vorangestellte Information beschrieben.

- **Ein Beispiel**

  Wie die Überschrift bereits andeutet, wird in diesem Abschnitt das Zielverzeichnis definiert, d.h. der Ort, an dem die gesicherten Daten gespeichert werden sollen. Unter der Überschrift wird zunächst anhand eines Beispiels das Syntaxmuster bzw. die Schreibweise der Variablen erläutert. Danach folgen weitere Informationen, die den Vorgang näher beschreiben. Am Ende steht die eigentliche Variable, erkennbar am fehlenden #-Zeichen am Anfang der Zeile.

		# Zielverzeichnis
		#---------------------------------------------------------------------
		# Syntaxmuster: target="/[VOLUME]/[SHARE]/[FOLDER]"
		#---------------------------------------------------------------------
		# Es muss der vollständige Pfad zum Zielverzeichnis angegeben werden.
		# Wenn das Zielverzeichnis nicht existiert, wird es bei der ersten 
		# Datensicherung angelegt. Ungültige Zeichen in Datei- und 
		# Verzeichnisnamen sind ~ " # % & * : < > ? / \ { | }
		#---------------------------------------------------------------------
		target=""

  In diesem Fall befindet sich noch kein Wert innerhalb der Anführungszeichen der Variablen target="". Einige Variablen enthalten bereits Vorschlagswerte, die je nach Aufgabe gelöscht oder geändert werden können. In diesem Fall wird man aufgefordert, einen Verzeichnispfad (das Zielverzeichnis) einzugeben, der z.B. so aussehen könnte

		target="/volumeUSB1/Backup/Backup_Home_Verzeichnisse"

  Auf diese Weise arbeitet man sich von oben nach unten durch die Konfigurationsdatei, vergibt oder ändert Werte, löscht Inhalte und lässt Felder leer, je nachdem, was angefordert wird. Am Ende wird die Konfiguration gespeichert.

## Konfigurationsdatei ausführen
Wie oben bereits erwähnt, können mehrere verschiedene Konfigurationen für unterschiedliche Aufgaben erstellt und mit jarss ausgeführt werden. Dabei ist darauf zu achten, dass sich die Shell-Skript-Datei jarss und die Konfigurationsdatei(en) immer im selben Verzeichnis befinden.

Die Ausführung der Shell-Skript-Datei jarss sollte vorzugsweise mit root-Berechtigung (d.h. mit vorangestelltem sudo-Befehl) erfolgen, da ansonsten mit einigen Einschränkungen zu rechnen ist, wie z.B. dass Verzeichnisse nicht angelegt werden können, Dateien aufgrund fehlender Berechtigungen nicht gesichert werden können oder andere Befehle nicht korrekt ausgeführt werden können.

Der Aufruf selbst erfolgt am besten, indem man den absoluten Pfad, d.h. den Verzeichnispfad, in dem sich die Shell-Skript-Datei jarss.sh befindet, voranstellt, wobei auch der relative Pfad genügt, wenn man sich selbst im selben Verzeichnis wie das Shell-Skript und die Konfigurationsdatei(en) befindet. Es folgen weitere obligatorische und optionale Optionen, die weiter unten beschrieben werden.

#### _Hinweis: Text in Großbuchstaben innerhalb eckiger Klammern dient als Platzhalter und muss einschließlich der eckigen Klammern durch eigene Angaben ersetzt werden._

sudo bash /[ABSOLUTER-PFAD]/jarss.sh --job-name="[DATEINAME]" [--info=progress2] [--dry-run] [-v] [-vv] [-vvv]

```
/[ABSOLUTER-PFAD]/jarss.sh   Hier muss anstelle des Platzhalters [ABSOLUTER-PFAD], der absolute Pfad zu dem Verzeichnis angegeben werden, indem sich das Script jarss.sh befindet.
                             Beispiel: /volume1/backups/jarss.sh

--job-name="[DATEINAME]"     Hier muss anstelle der Platzhalters [DATEINAME] der Dateiname des auszuführenden Auftrages bzw. der auszuführenden Konfigurationsdatei eingetragen. 
                             Beispiel: --job-name="jarss_Konfiguration_GER"

Optionale Funktionen
    --info=progress2         Zeigt Informationen über den Gesamtfortschritt der Dateiübertragung an.
    --dry-run                Rsync simuliert nur was passieren würde, ohne das dabei Daten kopiert
                             bzw. synchronisiert werden.
    -v                       Kurzes rsync Protokoll, welche Dateien übertragen werden.
    -vv                      Erweitertes rsync Protokoll, welche Dateien übersprungen werden. 
    -vvv                     Sehr umfangreiches rsync Protokoll zum debuggen.
```

- **Ein Beispiel**

		bash /volume1/backups/jarss.sh --job-name="jarss_Backup_auf_USB-Festplatte" --dry-run

  Es wird empfohlen, vor der ersten Ausführung des Auftrages einen Testlauf durchzuführen, um sicherzustellen, dass alles korrekt abläuft. Dies ist mit der Option `--dry-run` möglich. Damit wird nur simuliert, was passieren würde, wenn keine Daten kopiert würden. Erst wenn die Simulation erfolgreich und zufriedenstellend verlaufen ist, kann die Option `--dry-run` wieder entfernt werden. Während der Ausführung werden zum einen alle relevanten Informationen im Terminalfenster angezeigt, zum anderen wird ein Protokoll geschrieben, das am selben Ort abgelegt wird, an dem sich auch die Shell-Skript-Datei jarss.sh und die ausgeführte Konfigurationsdatei befinden. Das Protokoll ist am Namen der ausgeführten Konfigurationsdatei und der Dateiendung .log zu erkennen. Dem Beispiel folgend lautet der Dateiname des Protokolls: jarss_Backup_auf_USB-Festplatte.log.