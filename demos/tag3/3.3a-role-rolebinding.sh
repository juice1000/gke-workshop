#!/usr/bin/env bash
# Demo 3.3a: Role und RoleBinding
# Folie: Tag 3, 3.3 Zugriffsrechte
# Zeigt: die Role sagt WAS, das RoleBinding WER. Mit auth can-i --as prueft
# ihr die Rechte einer anderen Person, ohne deren Zugang zu haben.
# Legt Role und RoleBinding demo-leser an und loescht beide am Ende.
# Voraussetzung: Cluster laeuft, Namespace workshop. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 3.3a "Role und RoleBinding" "3.3 Zugriffsrechte"
aufraeumen_mit "kubectl delete rolebinding demo-leser --ignore-not-found && kubectl delete role demo-leser --ignore-not-found"

PERSON=demo-person@example.com
sage "Lokal seid ihr Admin. Die Person $PERSON hat noch keine Rechte."
lauf "kubectl auth can-i list pods --as $PERSON"
sage "Role: Pods lesen, sonst nichts. Gilt nur im Namespace $NS."
lauf "kubectl create role demo-leser --verb=get,list,watch --resource=pods,pods/log"
sage "Die Role allein bewirkt nichts:"
lauf "kubectl auth can-i list pods --as $PERSON"
sage "RoleBinding: verbindet die Role mit der Person."
lauf "kubectl create rolebinding demo-leser --role=demo-leser --user=$PERSON"
lauf "kubectl auth can-i list pods --as $PERSON"
sage "Was nicht in der Role steht, ist verboten:"
lauf "kubectl auth can-i delete pods --as $PERSON"
lauf "kubectl auth can-i get secrets --as $PERSON"
sage "Alle Rechte der Person in diesem Namespace auf einen Blick:"
lauf "kubectl auth can-i --list --as $PERSON | head -n 8"
sage "Auf GKE kommt IAM davor: ohne IAM-Zugang zum Cluster hilft kein RoleBinding."
sage "Vollstaendiges Beispiel: trainer/rbac.yaml."
fertig
