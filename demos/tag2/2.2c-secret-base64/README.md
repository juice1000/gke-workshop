# Demo 2.2c (Extra): ConfigMap oder Secret?

**Folie:** Tag 2, Anhang, Extra-Auflösung „ConfigMap oder Secret?“  
**Dauer:** etwa 2 Minuten  
**Ändert den Cluster:** nein  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../00-vorbereiten/README.md)

```bash
bash demos/tag2/2.2c-secret-base64/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.2c-secret-base64/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.2c-secret-base64/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Ein Secret ist nur base64-kodiert, nicht verschlüsselt. Entscheidend ist, wer es lesen darf.

## Schritte und was ihr zeigt

1. `kubectl get secret hallo-secret -o yaml | grep DB_PASSWORT`  
   Zeigen: `DB_PASSWORT: dWVidW5nMTIz`. Sieht verschlüsselt aus, ist es nicht.

2. `kubectl get secret hallo-secret -o jsonpath='{.data.DB_PASSWORT}' | base64 -d; echo`  
   Zeigen: `uebung123`. Ein Befehl genügt.

3. `kubectl auth can-i get secrets`  
   Zeigen: `yes`. Lokal seid ihr Admin. Auf GKE regelt RBAC, wer Secrets lesen darf (Tag 3).

## Häufige Fragen

- **Wo liegt das Secret eigentlich?** In etcd, der Datenbank des Clusters, unter `/registry/secrets/workshop/hallo-secret`. Nicht im Repository, nicht im Image. In minikube unverschlüsselt, auf GKE verschlüsselt Google den Speicher.
- **Warum dann überhaupt Secret statt ConfigMap?** Eigene Rechte: Man kann Secrets lesen verbieten und ConfigMaps erlauben. Außerdem verschlüsseln Cluster wie GKE Secrets gesondert.
- **Darf ich ein Secret-YAML ins Repository legen?** Nein. base64 ist umkehrbar, Git behält jede Version. Das Secret wird per Befehl oder aus einem Secret Manager angelegt.
- **Sehe ich das Passwort im Pod?** Ja: `kubectl exec deploy/hallo -- printenv DB_PASSWORT`. Wer `exec` darf, kann es lesen.

## Wenn es hakt

- `NotFound`: Das Secret fehlt. Demo 00 legt es an.

## Aufräumen

Nicht nötig, die Demo ändert nichts.

Alle Demos: [Übersicht](../../README.md)
