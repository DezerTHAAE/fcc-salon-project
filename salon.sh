#! /bin/bash

# Configuración de la base de datos
PSQL="psql --username=freecodecamp --dbname=salon -t --no-align -c"

echo -e "\n~~~~~ MY SALON ~~~~~"
echo -e "\nWelcome to My Salon, how can I help you?"

MAIN_MENU() {
  # Si se proporciona un mensaje, se imprime (usado para errores de servicio)
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  # Obtener la lista de servicios y mostrarla
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
  echo "$SERVICES" | while IFS="|" read SERVICE_ID NAME
  do
    echo "$SERVICE_ID) $NAME"
  done
  
  # Leer la selección del servicio
  read SERVICE_ID_SELECTED
  
  # Verificar si el servicio es válido
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
  
  if [[ -z $SERVICE_NAME ]]
  then
    # Si el servicio no existe, volver al menú principal
    MAIN_MENU "I could not find that service. What would you like today?"
  else
    # Si el servicio es válido, proceder a solicitar el teléfono
    GET_CUSTOMER_INFO
  fi
}

GET_CUSTOMER_INFO() {
  # Solicitar número de teléfono
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  # Buscar el ID del cliente basado en el teléfono
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
  
  # Si el CUSTOMER_ID está vacío, el cliente es nuevo
  if [[ -z $CUSTOMER_ID ]]
  then
    # Solicitar nombre del cliente nuevo
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME

    # Insertar el nuevo cliente
    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
    
    # Obtener el nuevo customer_id
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
  
  else
    # Si el cliente ya existe, obtener su nombre
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID")
  fi
  
  # Proceder a solicitar la hora de la cita
  GET_APPOINTMENT_TIME
}

GET_APPOINTMENT_TIME() {
  # Solicitar la hora de la cita
  echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
  read SERVICE_TIME

  # Insertar la nueva cita
  INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
  
  # Confirmación de la cita
  echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
}

MAIN_MENU
