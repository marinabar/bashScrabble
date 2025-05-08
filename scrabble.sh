#!/bin/bash

# Jeu de scrabble solitaire

# on charge le dictionnaire en mémoire en ajoutant des retours a la ligne, 
# pour qu'il y en ait autour de chaque mot
dict=$'\n'$(<Dictionnaire.txt)$'\n'

lettres= points= nb_pioches=
# on lit le fichier lettres.txt et on attribue les valeurs en séparant aux virgules
while IFS=, read lettre point nb; 
do
  lettres+=$lettre
  points+=$point
  nb_pioches+=$nb

done < lettres.txt

# on enlève les caractères \r du fichier
lettres=${lettres//$'\r'/}
points=${points//$'\r'/}
nb_pioches=${nb_pioches//$'\r'/}


porte_lettres="abcdefg"
nb_lettres=7

remplir_pioche() {
    pioche=()
    local i=0 lettre nb j
    while [ "$i" -lt "${#lettres}" ]; 
    do
        # on remplit la pioche avec les lettres et le nombre de fois qu'elles sont disponibles
        lettre=${lettres:i:1}
        nb=${nb_pioches:i:1}
        # on ajoute la lettre à la pioche nb fois
        j=0
        while [ "$j" -lt "$nb" ];
        do
            pioche+=$lettre
            j=$((j+1))
        done
        i=$((i+1))
    done
}

mot_valide () {
    echo "Vérification de la validité du mot $1"
    echo ""
    # on verifie si le mot est dans le dictionnaire en vérifiant la correspondance \n$mot\n
    local mot=$1
    if [[ $dict == *$'\n'"$mot"$'\n'* ]]; 
    then
        return 0
    else
        return 1
    fi
}

random_lettre () {
    # on remplace une lettre du porte lettre par une lettre aleatoire de la pioche
    local id_remplacer=$1
    # renvoie un indice de la pioche
    local tirage_aleatoire=$(( RANDOM % ${#pioche} ))

    local lettre_aleatoire=${pioche:tirage_aleatoire:1}
    local next=$((id_remplacer + 1))
    # on remplace une lettre par une lettre aleatoire de la pioche
    porte_lettres="${porte_lettres:0:id_remplacer}$lettre_aleatoire${porte_lettres:next}"
    # on retire la lettre de la pioche
    pioche=${pioche/$lettre_aleatoire/}
} 


remplir_porte_lettres() {
    local i=0
    while [ "$i" -lt "$nb_lettres" ];
    do
        # on remplace une lettre du porte lettre par une lettre aleatoire de la pioche
        random_lettre $i
        i=$((i+1))
    done
}

calculer_score() {
    # calcule le score rapporté par le mot et met à jour le porte lettres
    local mot=$1
    score_mot=0
    local i=0

    local copie_pl=$porte_lettres
    while [ "$i" -lt  "${#mot}" ];
    do
        l=${mot:i:1}
        # indice de la lettre dans le dictionnaire avec l'indice commençant à 0
        local indice_lettre=0
        while [ $indice_lettre -lt ${#lettres} ]; do
            if [ "${lettres:$indice_lettre:1}" = "$l" ]; then
                break
            fi
            indice_lettre=$((indice_lettre+1))
        done

        # calcul du score de la lettre
        local point_lettre=${points:$indice_lettre:1}
        echo "lettre: $l, points: $point_lettre, indice dans le dictionnaire: $indice_lettre"

        score_mot=$((score_mot + point_lettre))
        
        # on remplace une lettre du porte lettre par une lettre aleatoire de la pioche
        local indice_porte_lettre=0
        while [ $indice_porte_lettre -lt ${#copie_pl} ]; do
            if [ "${copie_pl:$indice_porte_lettre:1}" = "$l" ]; then
                break
            fi
            indice_porte_lettre=$((indice_porte_lettre+1))
        done

        #echo "lettre: $l, indice porte lettres: $indice_porte_lettre"
        random_lettre "$indice_porte_lettre"
        i=$((i+1))
    done
}

# vérifie si le mot est dans le porte lettres
choix_valide() {
  local mot=$1
  local p=$porte_lettres
  local c

  # tant que mot non vide
  while [ -n "$mot" ]; do
    # la première lettre du mot
    c=${mot:0:1}

    # si p ne contient pas c le caractère
    if [[ $p != *"$c"* ]]; then
      return 1
    fi

    # on enleve la lettre du porte lettres temporaire et du mot
    p=${p/"$c"/}
    mot=${mot:1}
  done

  return 0
}

# programme principal
# 1 on remplit la pioche
# 2 on commence la partie, boucle de 10 tours
# 2.1 on affiche le porte lettres
# 2.2 on demande un mot
# 2.3 on verifie si le mot est valide
# 2.4 on calcule le score
# 2.5 on affiche le score


# début de la partie
remplir_pioche
remplir_porte_lettres

echo "Début de la partie de scrabble solitaire"
echo "La partie se déroule en 10 tours"

echo ""
tour=1
total=0
while [ $tour -lt 10 ];
do 
    echo ""
    echo "Tour numéro $tour"
    echo ""
    echo "Lettres à disposition : $porte_lettres"
    echo "Entrez un mot ou appuyez sur entrée pour passer votre tour et réinitialiser le porte lettres..."
    # on lit le mot avec le retour à la ligne
    read mot
    if [ -z "$mot" ]; 
    then
        # on passe le tour et on réinitialise le porte lettres
        echo "Vous avez passé votre tour, aucun point ne sera ajouté"
        remplir_porte_lettres
        tour=$((tour+1))
        continue
    fi
    # on verifie si le mot est valide
    if mot_valide "$mot"; 
    then
        echo "Mot valide"
        choix_valide "$mot"
        if [ $? -eq 0 ]; 
        then
            echo "Mot trouvé dans le porte lettres"
        else
            echo "Une ou plusieurs lettres du mot ne sont pas dans le porte lettres"
            # on rejoue le tour
            tour=$((tour-1))
            continue
        fi
        calculer_score "$mot"
        echo "Points gagnés: $score_mot"
        total=$((total + score_mot))
        echo "Score total: $total"
    else
        echo "Mot invalide, veuillez entrer un mot valide"
        # on rejoue le tour
        tour=$((tour-1))
    fi
    tour=$((tour+1))
done
echo ""
echo "Fin de la partie"
echo "Score final: $total"