#!/bin/bash
# Manage trainers menu
manage_trainers(){
while true; do
        echo "======= Trainers Management ======="
        echo "1. Add New trainer"
        echo "2. View trainers List"
        echo "3. Exit"

        read -p "Enter your choice (1-3): " choice

        case $choice in
            1)
                add_new_trainer
                ;;
            2)
                view_trainer_list
                ;;            
            3)
                echo "Back to the main menu..."
                break
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac
    done
    
# Function to add a new trainer
add_new_trainer() {
    read -p "Enter trainer name: " trainer_name
    read -p "Enter trainer email: " trainer_email

    local phone_number_pattern='^[0-9]{10}$'
    while true; do
        read -p "Enter trainer phone number: " trainer_phone
        if [[ "$trainer_phone" =~ $phone_number_pattern ]]; then
            # Save trainer data to file
            local trainer_data="$trainer_name,$trainer_email,$trainer_phone"
            save_data_to_file "trainers.txt" "$trainer_data"
            echo "New trainer added successfully!"
            break
        else
            echo "Invalid phone number format. Please enter a 10-digit phone number without any dashes or spaces."
        fi
    done
}

# Function to view trainer list
view_trainer_list() {
    local trainer_data=$(read_data_from_file "trainers.txt")
    if [ -n "$trainer_data" ]; then
        IFS=','
        while read -ra trainer_info; do
            echo "Name: ${trainer_info[0]} Email: ${trainer_info[1]} Phone: ${trainer_info[2]}
-----------------------------------------------------------"
        done <<< "$trainer_data"
    else
        echo "No trainers found."
    fi
}
}
