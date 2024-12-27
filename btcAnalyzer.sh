#! /bin/bash

# Author: La pirulita

#Colours
greenColour="\e[0;32m\033[1m" #`\e y \033` son escape. Lo demas es codigo ANSI
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"


trap ctrl_c SIGINT #`trap command` (ejecuta un argumento y una opcion) INT -> opcion para interrumpir con ctrl+c

function ctrl_c() {
	echo -e "\n${redColour}[!] Exit...\n${endColour}" #especificamos que cierre el color ${endColour}

	rm unconfirmed_transactions.t* money* amount.table entradas.tmp salidas.tmp address.information address_information.tmp cantidad*.txt dolares.t* 2>/dev/null #Eliminamos los archivos
	tput cnorm; exit 1 #`tput cnorm` hace que el cursor de la terminal vuelva a su estado normal
}


#Global Variables
unconfirmed_transactions="https://3xpl.com/bitcoin/mempool"
inspect_transaction_url="https://3xpl.com/bitcoin/transaction/"
inspect_address_url="https://3xpl.com/bitcoin/address/"


function helpPanel() {
	echo -e "\n${redColour}[!] Uso: ./btcAnalyzer${endColour}"
	for i in $(seq 1 80); do echo -ne "${redColour}-"; done; echo -ne "${endColour}" #echo -n -> no añade salto de linea
	echo -e "\n\n\t${grayColour}[-e]${endColour}${yellowColour} Modo exploración${endColour}"
	echo -e "\t\t${purpleColour}unconfirmed_transactions${endColour}${yellowColour}:\t\t Listar transacciones no confirmadas${endColour}"
	echo -e "\t\t${purpleColour}inspect_transactions${endColour}${yellowColour}:\t\t\t Inspeccionar un hash de transacción${endColour}"
	echo -e "\t\t${purpleColour}inspect_address${endColour}${yellowColour}:\t\t\t Inspeccionar una transacción de una dirección${endColour}"
	echo -e "\n\t${grayColour}[-n]${endColour}${yellowColour} Limitar el numero de resultados${endColour}${blueColour} (Ejemplo: -n 10)${endColour}"
	echo -e "\n\t${grayColour}[-i]${endColour}${yellowColour} Proporcionar el Identificador de Transacción${endColour}${blueColour} (Ejemplo: -i fe5b90cb8d2804d...)${endColour}"
	echo -e "\n\t${grayColour}[-a]${endColour}${yellowColour} Proporcionar una dirección de Transacción${endColour}${blueColour} (Ejemplo: -a 0xavg438kj34gferw2...)${endColour}"
	echo -e "\n\n\t${grayColour}[-h]${endColour}${yellowColour} Panel de ayuda${endColour}"

	tput cnorm; exit 1 #mostrar cursor
}


#START TABLE
function printTable(){

    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines(){

    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString(){

    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString(){

    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString(){

    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}
#FIN TABLE


function unconfirmedTransactions() {

	number_output=$1 #Tomamos primer argumento

	#TABLA-TRANSACCIONES
	echo '' > unconfirmed_transactions.tmp

	while [ "$(cat unconfirmed_transactions.tmp | wc -l)" == "1" ]; do  #Validamos que el fichero tenga contenido
		curl -s "$unconfirmed_transactions" | w3m -dump -T text/html > unconfirmed_transactions.tmp
	done

	hashes=$(cat unconfirmed_transactions.tmp | awk '{print $1}' | grep -A 1 "bitcoin$" | grep -v -E "bitcoin|\--" | sort | uniq | head -n $number_output) #Obtener Hashes limpios no repetidos y limito la cantidad a entregar

	echo "Hash_Cantidad_Bitcoin_Tiempo" > unconfirmed_transactions.table

	for hash in $hashes; do
		echo "${hash}_$(cat unconfirmed_transactions.tmp | grep "$hash" -A 5 | awk "NR==6" | awk '{print $1}')_$(cat unconfirmed_transactions.tmp | grep "$hash" -B 3 | awk "NR==1" | awk '{print $1}')_$(cat unconfirmed_transactions.tmp | grep "$hash" -A 1 | awk "NR==2" | awk 'NF{print $NF}')" >> unconfirmed_transactions.table
	done


	#CANTIDADES
	cat unconfirmed_transactions.table | tr '_' ' ' | awk '{print $2}' | grep -v "Cantidad" > money #se guardan las cantidades en dolares

	suma=0; while read -r linea; do suma=$(echo "$suma + $linea" | bc); done < money; echo "$suma" > money.tmp; #Sumatoria de los dolares

	echo -n "Cantidad total_" > amount.table
	echo "\$$(cat money.tmp)" >> amount.table

	#Validación antes de pintar Tabla
	if [ "$(cat unconfirmed_transactions.table | wc -l)" -ge "1" ]; then

		#IMPRIMIR TABLA-TRANSACCIONES
		echo -ne "${turquoiseColour}"
		printTable '_' "$(cat unconfirmed_transactions.table)" #Ingresa por parametro el delimitador y el contenido de la tabla
		echo -ne "${endColour}"

		#IMPRIMIR TABLA-TOTAL
		echo -ne "${blueColour}"
		printTable '_' "$(cat amount.table)"
		echo -ne "${endColour}"

		rm unconfirmed_transactions.t* money* amount.table 2>/dev/null #eliminar ficheros
		tput cnorm; exit 0
	else
		rm unconfirmed_transactions.t* money* amount.table 2>/dev/null
		echo -e "\n${redColour}[!] No se encontraron Transacciones... Try again! \n${endColour}"
	fi

	rm unconfirmed_transactions.t* money* amount.table 2>/dev/null #por las dudas si falla el condicional
	tput cnorm;

}

function inspectTransaction() {
	inspect_hash_transaction=$1

	#INPUTS
	echo "Dirección (Entradas)_Valor" > entradas.tmp

	while [ "$(cat entradas.tmp | wc -l)" == "1" ]; do  #Validamos que el fichero tenga contenido
                curl -s "${inspect_transaction_url}${inspect_hash_transaction}" | w3m -dump -T text/html | grep "^ -" -B 2 -A 2 | grep -v -E "\-|\--" | awk '{print $1 $2 $10 $11}' | sed 's/BTC/BTC----->/g' | awk 'NR%2{printf "%s ",$0;next;}1' | awk 'NR%2{printf "%s ",$0;next;}1' | awk '{print $1 "_" $2 " " $3}' >> entradas.tmp
	done

	#Validación
	if [ "$(cat entradas.tmp | wc -l)" -ge "1" ]; then

                #IMPRIMIR TABLA-INPUTS
        	echo -ne "${greenColour}"
        	printTable '_' "$(cat entradas.tmp)"
        	echo -ne "${endColour}"

                rm entradas.tmp 2>/dev/null
        else
                rm entradas.tmp 2>/dev/null
                echo -e "\n${redColour}[!] No se encontraron Inputs... Try again! \n${endColour}"
        fi

	#OUTPUTS
	echo "Dirección (Salidas)_Valor" > salidas.tmp

        while [ "$(cat salidas.tmp | wc -l)" == "1" ]; do
		curl -s "${inspect_transaction_url}${inspect_hash_transaction}" | w3m -dump -T text/html | grep "\+" -B 2 -A 2 | grep -v -E "\+|\--" | awk '{print $1 $2 $10 $11}' | sed 's/BTC/BTC----->/g' | awk 'NR%2{printf "%s ",$0;next;}1' | awk 'NR%2{printf "%s ",$0;next;}1' | awk '{print $1 "_" $2 " " $3}' >> salidas.tmp
	done

	#Validación
	if [ "$(cat salidas.tmp | wc -l)" -ge "1" ]; then

                #IMPRIMIR TABLA-OUTPUTS
        	echo -ne "${redColour}"
        	printTable '_' "$(cat salidas.tmp)"
        	echo -ne "${endColour}"

                rm salidas.tmp 2>/dev/null
        else
                rm salidas.tmp 2>/dev/null 
                echo -e "\n${redColour}[!] No se encontraron Outputs... Try again! \n${endColour}"
        fi

	rm entradas.tmp salidas.tmp 2>/dev/null #por las dudas si falla el condicional
        tput cnorm;
}

function inspectAddress() {
	address_wallet=$1

	#TABLA-BTC
	echo "Transacciones realizadas_Total ingreso de (BTC)_Total egreso de (BTC)_Balance en (BTC)" > address.information
 
	echo '' > address_information.tmp

        while [ "$(cat address_information.tmp | wc -l)" == "1" ]; do  #Validamos que el fichero tenga contenido
                curl -s "${inspect_address_url}${address_wallet}" | w3m -dump -T text/html > address_information.tmp
        done

	transactions=$(cat address_information.tmp | grep "Main" | tail -1 | awk '{print $2}' | sed 's/(16)/16/');

	inputs=$(cat address_information.tmp | grep "-" -A 2 | awk 'NF{print $NF}' | grep -v -E "\-|\--|\->|\▾|blockchair.com")
	total_input=0; for input in $inputs; do total_input=$(echo "$total_input + $input" | bc); done;
	total_input=$(printf "%.8f" "$total_input"); #Formatear la salida con un cero antes del punto decimal

	outputs=$(cat address_information.tmp | grep "+" -A 2 | awk 'NF{print $NF}' | grep -v -E "USD|History|\--|\+")
	total_output=0; for output in $outputs; do total_output=$(echo "$total_output + $output" | bc); done;
	total_output=$(printf "%.8f" "$total_output"); #Formatear la salida con un cero antes del punto decimal

	balance=$(cat address_information.tmp | grep "balance" -A 2 | tail -1 | awk '{print $2}' | tr -d ',');

	result="${transactions}_${total_input} BTC_${total_output} BTC_${balance} BTC"; #example->  16_.02161690 BTC_.01531388 BTC_0.00000000 BTC
	echo ${result} >> address.information

	#Validación
        if [ "$(cat address.information | wc -l)" -ge "1" ]; then

                #IMPRIMIR TABLA-ADDRESS
                echo -ne "${yellowColour}"
                printTable '_' "$(cat address.information)"
                echo -ne "${endColour}"

                rm address.information address_information.tmp 2>/dev/null
        else
                rm address.information address_information.tmp 2>/dev/null 
                echo -e "\n${redColour}[!] No se encontraro el Address Information... Try again! \n${endColour}"
        fi


	#TABLA-DOLARES
	bitcoin_price=$(curl -s "https://3xpl.com/bitcoin" | w3m -dump -T text/html | grep "Bitcoin price" -A 2 | tail -n -1 | awk '{print $1}' | tr -d ',');

	echo -e "${total_input}\n${total_output}\n${balance}" > cantidades_btc.txt

	while read -r line; do value=$(echo "$line * $bitcoin_price" | bc); printf "%.2f\n" "$value" >> cantidad_dolares.txt; done < cantidades_btc.txt

	#Agregar simbolo dolar
	echo "${transactions}" > dolares.txt
	while read -r line2; do echo "\$$line2" >> dolares.txt; done < cantidad_dolares.txt;

	#TABLA
	echo "Transacciones realizadas_Total ingreso de (USD)_Total egreso de (USD)_Balance en (USD)" > dolares.table
	cat dolares.txt | xargs | tr ' ' '_' >> dolares.table

	#Validación
        if [ "$(cat dolares.table | wc -l)" -ge "1" ]; then

                #IMPRIMIR TABLA-ADDRESS-DOLAR
                echo -ne "${greenColour}"
                printTable '_' "$(cat dolares.table)"
                echo -ne "${endColour}"

                rm cantidad*.txt dolares.t* 2>/dev/null
        else
                rm cantidad*.txt dolares.t* 2>/dev/null
                echo -e "\n${redColour}[!] Error en generar la Tabla Dolares... Try again! \n${endColour}"
        fi

	tput cnorm
}

#Logic Script Functions
parameter_counter=0
while getopts "e:n:i:a:h:" arg; do
	case $arg in
		e) exploration_mode=$OPTARG; let parameter_counter+=1;; #let permite asignar valores
		n) number_output=$OPTARG; let parameter_counter+=1;;
		i) inspect_hash_transaction=$OPTARG; let parameter_counter+=1;;
		a) inspect_address=$OPTARG; let parameter_counter+=1;;
		h) helpPanel;;
	esac 
done

tput civis #esto oculta el cursor

#Validation getopts options
if [ $parameter_counter -eq 0 ]; then
	helpPanel #esto muestra el panel cuando recien inicia el script
else
	if [ "$(echo $exploration_mode)" == "unconfirmed_transactions" ]; then
		if [ ! "$number_output" ]; then #Si no exite un valor entonces se coloca un valor por default
			number_output=100
			unconfirmedTransactions $number_output
		else
			unconfirmedTransactions $number_output #Tomamos el valor ingresado por el usuario
		fi
	elif [ "$(echo $exploration_mode)" == "inspect_transactions" ]; then
		inspectTransaction $inspect_hash_transaction #Tomamos el valor del Transaction Id

	elif [ "$(echo $exploration_mode)" == "inspect_address" ]; then
		inspectAddress $inspect_address
	fi
fi
