Deutsch | [English](README_en.md)

# jarss (just another rsync shell script) 
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Ftoafez%2Fjarss&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)

**jarss** verwendet **rsync**, um Daten zwischen lokalen Pfaden oder Pfaden, auf die über das Netzwerk mit **SSH-Public-Key-Authentifizierung** zugegriffen werden kann, zu übertragen. Neben **synchronisierten** Datensicherungen unterstützt jarss auch **inkrementelle** Datensicherungen. 

## So funktioniert jarss genau
- ### Synchronisierte Datensicherung
    Bei der ersten Ausführung einer synchronen Datensicherung werden zunächst alle Quelldaten in das gewünschte Zielverzeichnis übertragen, bei allen weiteren Ausführungen werden nur die zwischenzeitlich geänderten, neu hinzugekommenen oder gelöschten Quelldaten mit dem Zielverzeichnis verglichen und entsprechend übertragen. Um einem möglichen Datenverlust vorzubeugen, können bei Bedarf alle zwischenzeitlich gelöschten Daten der Quelle(n) im Ziel für einen vordefinierten Zeitraum in einen Papierkorb mit dem Verzeichnisnamen @recycle verschoben werden. Erst nach Ablauf dieser Aufbewahrungsfrist werden die Daten unwiderruflich gelöscht.

- ### Inkrementelle Datensicherung
    Bei der ersten Ausführung einer inkrementellen Datensicherung werden alle Quelldaten in einem Unterverzeichnis, das nach Datum und Uhrzeit der aktuellen Sicherung benannt ist, in das gewünschte Zielverzeichnis übertragen. Unmittelbar danach wird mittels Symlinks ein Image der aktuellen Sicherung erstellt, das auf den i.d.R. nicht sichtbaren Ordner ~latest verweist, der sich ebenfalls im Zielverzeichnis befindet.

    Beim nächsten und allen weiteren Durchläufen werden die Quelldaten zunächst immer mit dem zuletzt erstellten Image (~latest) der vorherigen Sicherung verglichen. Dann wird im Zielverzeichnis erneut ein Unterverzeichnis mit dem Namen des aktuellen Sicherungsdatums und der aktuellen Sicherungszeit angelegt, wobei diesmal nur alle zwischenzeitlich geänderten oder neu hinzugekommenen Quelldaten übertragen werden, zwischenzeitlich gelöschte Quelldaten werden nicht berücksichtigt. Unveränderte Quelldaten erhalten im Ziel lediglich einen Verweis (sog. Hardlinks) auf die bereits im Image vorhandenen Daten und werden daher nicht erneut übertragen. Dadurch entsteht der Eindruck, dass jede neu erstellte Version den gesamten aktuellen Datenbestand und den damit verbundenen Speicherplatz enthält, obwohl sich der tatsächliche Speicherplatzbedarf nur auf die Änderungen seit der letzten Sicherung beschränkt.

    Um die Anzahl der Versionen zu begrenzen, können diese nach Ablauf einer vordefinierten Zeitspanne in Tagen automatisch gelöscht werden.

## Weitere Merkmale von jarss
- CLI-basiertes Shell-Skript, daher wahrscheinlich (nach individueller Prüfung) auf den meisten unixoiden Betriebssystemen lauffähig. 
-  Obwohl jarss vorzugsweise vom Systembenutzer root oder über sudo ausgeführt werden sollte, ist eine Ausführung als Benutzer, wenn auch mit gewissen Einschränkungen, durchaus möglich.
- Neben der Sicherung lokaler Pfade können auch Pfade zu oder von entfernten Servern über eine zuvor eingerichtete SSH-Public-Key-Authentifizierung gesichert werden.
- Die optionale Geschwindigkeitsbegrenzung von rsync wird deaktiviert, sobald das Programm ionice von jarss lokalisiert wurde. ionice ist in der Lage, die hohe Lese- und Schreiblast, die normalerweise durch den rsync-Prozess verursacht wird, so optimieren, dass die Verfügbarkeit des lokalen Systems und der an diesem Prozess beteiligten Remote-Server jederzeit gewährleistet ist.
- jarss verwendet sowohl die von rsync unterstützte synchrone als auch die inkrementelle Datensicherung, wobei die inkrementelle Datensicherung eine Kombination aus Hardlinks und Symlinks verwendet, um Dateien und Verzeichnisse über Dateisystemgrenzen hinweg verknüpfen zu können.
- jarss gibt während der Ausführung detaillierte Informationen über den aktuellen Fortschritt der Datensicherung über das Terminal aus und erstellt gleichzeitig ein detailliertes Protokoll zur späteren Durchsicht. 

## Installationshinweise
Lade die [ZIP-Datei](https://github.com/toafez/jarss/archive/refs/heads/main.zip) herunter und entpacke sie. Kopiere das Verzeichnis /scripts an einen Ort deiner Wahl und passe den Namen des Verzeichnisses ggf. deinen Wünschen an. Falls noch nicht geschehen, öffne ein Terminalfenster, wechsle in das oben genannte Verzeichnis und erteile der Skriptdatei jarss.sh Ausführungsrechte mit...

`chmod +x jarss.sh` oder auch `sudo chmod +x jarss.sh`

Öffne anschließend eine der beiden Konfigurationsdateien jarss_Konfiguration_GER (in deutscher Sprache) oder jarss_Configuration_ENU (in englischer Sprache) in einem Editor deiner Wahl und fülle die Werte anhand der beigefügten Hilfeanleitungen entsprechend aus. Nachdem alle Eingaben gemacht wurden, speichert man die Konfigurationsdatei und gibt ihr ggf. einen eindeutigen Namen, der im besten Fall Rückschlüsse auf die Art der Sicherung zulässt. Eine Dateierweiterung ist nicht erforderlich, kann aber beliebig verwendet werden. Ungültige Zeichen für Datei- und Verzeichnisnamen sind ~ " # % & * : < > ? / \ { | } 

## Aufruf des Ausführungsskript und der Konfigurationsdatei
jarss erhält seine Informationen zur Durchführung einer Datensicherung über eine separat zu erstellende Konfigurationsdatei, deren Dateiname frei wählbar ist und keine definierte Dateiendung besitzt. Auf diese Weise ist es möglich, mehrere verschiedene Konfigurationen für unterschiedliche Aufgaben zu erstellen und auszuführen. Es ist nur darauf zu achten, dass sich das jarss-Ausführungsskript und die Konfigurationsdatei(en) im selben Verzeichnis befinden. Der Aufruf des Skripts erfolgt am besten durch Voranstellen des absoluten Pfades, wobei auch der relative Pfad genügt, wenn man sich selbst im gleichen Verzeichnis wie das Skript und die Konfigurationsdatei(en) befindet.

#### _Hinweis: Text in Großbuchstaben innerhalb eckiger Klammern dient als Platzhalter und muss durch eigene Angaben ersetzt werden, während gemischter Text aus Groß- und Kleinbuchstaben, Ziffern und Sonderzeichen innerhalb eckiger Klammern optional verwendet werden kann. In jedem Fall müssen die eckigen Klammern beim Ersetzen von Platzhaltern oder bei der Verwendung einer Option entfernt werden._

```bash /[ABSOLUTER-PFAD-ZUM-SCRIPT]/jarss.sh --job-name="[DATEINAME]" [--info=progress2] [--dry-run] [-v] [-vv] [-vvv]```

```
--job-name="[DATEINAME]"     Hier den Dateinamen dieses Auftrages eintragen um das Backup auszuführen.
                             Beispiel: --job-name="jarss_Konfiguration_GER"

Optionale Funktionen
    --info=progress2         Zeigt Informationen über den Gesamtfortschritt der Dateiübertragung an.
    --dry-run                Rsync simuliert nur was passieren würde, ohne das dabei Daten kopiert
                             bzw. synchronisiert werden.
    -v                       Kurzes rsync Protokoll, welche Dateien übertragen werden.
    -vv                      Erweitertes rsync Protokoll, welche Dateien übersprungen werden. 
    -vvv                     Sehr umfangreiches rsync Protokoll zum debuggen.
```
