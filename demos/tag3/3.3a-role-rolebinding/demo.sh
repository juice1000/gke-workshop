#!/usr/bin/env bash
# Demo 3.3a: Role und RoleBinding
# Folie: Tag 3, 3.3 Zugriffsrechte
# Zeigt: die Role sagt WAS, das RoleBinding WER. Mit auth can-i --as prueft
# ihr die Rechte einer anderen Person, ohne deren Zugang zu haben.
# Legt Role und RoleBinding demo-leser an und loescht beide am Ende.
# Voraussetzung: Cluster laeuft, Namespace workshop. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 3.3a "Role und RoleBinding" "3.3 Zugriffsrechte"
cleanup_with "kubectl delete rolebinding demo-leser --ignore-not-found && kubectl delete role demo-leser --ignore-not-found"

PERSON=demo-person@example.com
say "Lokal seid ihr Admin. Die Person $PERSON hat noch keine Rechte."
run "kubectl auth can-i list pods --as $PERSON"
say "Role: Pods lesen, sonst nichts. Gilt nur im Namespace $NS."
run "kubectl create role demo-leser --verb=get,list,watch --resource=pods,pods/log"
say "Die Role allein bewirkt nichts:"
run "kubectl auth can-i list pods --as $PERSON"
say "RoleBinding: verbindet die Role mit der Person."
run "kubectl create rolebinding demo-leser --role=demo-leser --user=$PERSON"
run "kubectl auth can-i list pods --as $PERSON"
say "Was nicht in der Role steht, ist verboten:"
run "kubectl auth can-i delete pods --as $PERSON"
run "kubectl auth can-i get secrets --as $PERSON"
say "Alle Rechte der Person in diesem Namespace auf einen Blick:"
run "kubectl auth can-i --list --as $PERSON | head -n 8"
say "Auf GKE kommt IAM davor: ohne IAM-Zugang zum Cluster hilft kein RoleBinding."
say "Vollstaendiges Beispiel: trainer/rbac.yaml."
finish
