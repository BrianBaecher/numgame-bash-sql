#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_game -t --no-align -c"

# user login
LOGIN() {
    read -p "Enter your username:" USERNAME
    # check if username exists in DB
    USER_ID=$($PSQL "SELECT user_id FROM user_info WHERE username ILIKE '$USERNAME'")
    if [[ -z $USER_ID ]]; then
        #register new user
        echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
        #insert new user
        INSERT_NEW_USER=$($PSQL "INSERT INTO user_info (username, games_played, best_game) VALUES ('$USERNAME', 0, 0)")
        #start game
        NEW_USER_ID=$($PSQL "SELECT user_id FROM user_info WHERE username ILIKE '$USERNAME'")
        NUMBER_GAME "$NEW_USER_ID" "$USERNAME" "$GAMES_PLAYED" "$BEST_GAME"
    else
        GET_USER_INFO=$($PSQL "SELECT games_played, best_game FROM user_info WHERE username ILIKE '$USERNAME'")
        echo $GET_USER_INFO | while IFS=\| read GAMES_PLAYED BEST_GAME; do
            echo -e "\nWelcome back, '$USERNAME'! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
        done
        NUMBER_GAME "$USER_ID" "$USERNAME" "$GAMES_PLAYED" "$BEST_GAME"
    fi
}

#game itself
NUMBER_GAME() {
    USER_ID=$1
    USERNAME=$2
    GAMES_PLAYED=$3
    BEST_GAME=$4
    GUESSES=0
    # SET ANSWER
    ANSWER=$(($RANDOM % 1000 + 1))

    # REMOVE ME!
    echo $ANSWER
    #PROMPT
    echo -e "\nGuess the secret number between 1 and 1000:"
    while true; do
        let "GUESSES++"
        read GUESS
        #if guess is NaN
        if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
            echo -e "\nThat is not an integer, guess again:"
            continue
        fi
        if (($GUESS != $ANSWER)); then
            if (($GUESS < $ANSWER)); then
                echo "It's higher than that, guess again:"
                continue
            fi
            if (($GUESS > $ANSWER)); then
                echo "It's lower than that, guess again:"
                continue
            fi
        else
            echo -e "\nYou guessed it in $GUESSES tries. The secret number was $ANSWER. Nice job!"
            INSERT_GAME_RESULT=$($PSQL "INSERT INTO games (user_id, guess_num) VALUES ($USER_ID, $GUESSES)")
            #update game played count
            UPDATE_GAME_NUM=$($PSQL "UPDATE user_info SET games_played = games_played+1 WHERE username='$USERNAME'")
            #see if current score is best score
            if [[ $GAMES_PLAYED -le 1 ]] || [[ $GUESSES -lt $BEST_GAME ]]; then
                #set/update best game score
                UPDATE_BEST_GAME=$($PSQL "UPDATE user_info SET best_game = $GUESSES")
            fi
            break
        fi
    done
}
LOGIN
