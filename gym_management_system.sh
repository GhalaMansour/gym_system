#!/bin/bash

# Helper functions for file-based storage
save_data_to_file() {
    local filename="$1"
    local data="$2"

    if [ -f "$filename" ]; then
        # Append the new data to the existing file
        echo "$data" >> "$filename"
    else
        # Create a new file with the data
        echo "$data" > "$filename"
    fi
}

read_data_from_file() {
    local file_path="$1"

    if [ -f "$file_path" ]; then
        cat "$file_path"
    else
        echo ""
    fi
}

# Function to create an invoice
create_invoice() {
    local duration="$1"
    local fee="$2"
    local invoice_number=$((RANDOM % 1000 + 1))
    local invoice_date=$(date +"%Y-%m-%d")

    local invoice_data="
-----------------------------------------------------
Member Name: $member_name
Member ID: $member_id
Member Phone: \"$formatted_phone\"
Membership Duration: $duration months
Membership Fee: $fee
Invoice Number: $invoice_number
Invoice Date: $invoice_date
-----------------------------------------------------
"
    save_data_to_file "invoice_data.txt" "$invoice_data"
}


# Function to add a new member
add_new_member() {
    read -p "Enter member name: " member_name
    read -p "Enter member ID: " member_id

    # Check if the member ID already exists
    member_data=$(grep "$member_id" "members.txt")
    if [ -n "$member_data" ]; then
        echo "Member with ID $member_id already exists in the system."
        read -p "Do you want to add a new membership for this member? (y/n) " add_membership
        if [ "$add_membership" = "y" ]; then
            # Existing member, add new membership
            read -p "Select new membership duration (3, 6, 9, or 12 months): " new_membership_duration
            case $new_membership_duration in
                3)
                    new_membership_fee=99.99
                    ;;
                6)
                    new_membership_fee=179.99
                    ;;
                9)
                    new_membership_fee=249.99
                    ;;
                12)
                    new_membership_fee=299.99
                    ;;
                *)
                    echo "Invalid membership duration. Please try again."
                    add_new_member
                    return
                    ;;
            esac

            # Get the existing membership details from the member data
            IFS=', ' read -ra member_info <<< "$member_data"
            existing_membership_duration="${member_info[3]}"
            #existing_membership_fee="${member_info[4]}"

            # Calculate the new total membership duration 
            if [[ "$existing_membership_duration" =~ ^[0-9]+$ ]]; then
                new_total_duration=$((existing_membership_duration + new_membership_duration))
            else
                new_total_duration=$new_membership_duration
            fi
create_invoice "$new_membership_duration" "$new_membership_fee"

            # Update the existing member data in members.txt
            new_member_data="$member_name, $member_id, \"$formatted_phone\", $new_total_duration"
            sed -i "/$member_id/d" "members.txt"
            save_data_to_file "members.txt" "$new_member_data"
        else
            echo "Okay, not adding a new membership."
        fi
    else
        # New member
        local phone_number_pattern='^[0-9]{10}$'
        while true; do
        read -p "Enter member phone number: " member_phone
        if [[ "$member_phone" =~ $phone_number_pattern ]]; then
            # Format the phone number
            formatted_phone="${member_phone:0:3}-${member_phone:3:3}-${member_phone:6}"
        read -p "Select membership duration (3, 6, 9, or 12 months): " membership_duration

        case $membership_duration in
            3)
                membership_fee=99.99
                ;;
            6)
                membership_fee=179.99
                ;;
            9)
                membership_fee=249.99
                ;;
            12)
                membership_fee=299.99
                ;;
            *)
                echo "Invalid membership duration. Please try again."
                add_new_member
                return
                ;;
        esac
create_invoice "$membership_duration" "$membership_fee"
        # Save new member data to file
        local member_data="$member_name, $member_id, \"$formatted_phone\", $membership_duration"
        save_data_to_file "members.txt" "$member_data"
        break
        else
        echo "Invalid phone number format. Please enter a 10-digit phone number without any dashes or spaces."
        fi
        done
    fi
}


# Function to view member list
view_member_list() {
    local member_data=$(read_data_from_file "members.txt")
    if [ -n "$member_data" ]; then
        IFS=$','
        while read -ra member_info; do
            echo "name:${member_info[0]} ID:${member_info[1]} Phone:${member_info[2]} Membership duration:${member_info[3]}
---------------------------------------------------------------- "
        done <<< "$member_data"
    else
        echo "No members found."
    fi
}

# Function to check membership expiration by member ID
check_membership_expiration_by_id() {
    read -p "Enter member ID: " member_id
    local member_data=$(grep "$member_id" "members.txt")
    if [ -n "$member_data" ]; then
        IFS=$','
        read -ra member_info <<< "$member_data"
        local member_name="${member_info[0]}"
        local member_phone="${member_info[2]}"
        local membership_duration="${member_info[3]}"
        local invoice_date="${member_info[6]}"

        # Calculate expiration date
        local expiration_date=$(date -d "$invoice_date + $membership_duration months" +"%Y-%m-%d")
        local days_left=$(($(date -d "$expiration_date" +"%s") - $(date +"%s")))
        days_left=$((days_left / 86400))

        echo "Member: $member_name, Phone:\"$member_phone\", Expiration: $expiration_date, Days Left: $days_left"

        if [ "$days_left" -le 7 ]; then
            echo "
This is to inform you that the GYJ Gym membership for "$member_name" (Phone: \"$formatted_phone\") will expire in $days_left days. Please make sure to follow up with them regarding membership renewal."
            
        fi
    else
        echo "Member with ID $member_id not found."
    fi
}
# Manage members menu
manage_members(){
while true; do
        echo "======= Members Management ======="
        echo "1. Add New Member"
        echo "2. View Member List"
        echo "3. Check Membership Expiration"
        echo "4. Exit"

        read -p "Enter your choice (1-4): " choice

        case $choice in
            1)
                add_new_member
                ;;
            2)
                view_member_list
                ;;
            3)
                check_membership_expiration_by_id
                ;;
            
            4)
                echo "Back to the main menu..."
                break
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac
    done

}



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
}


validate_date() {
    local date_str=$1
    local date_regex='^[0-9]{4}-[0-9]{2}-[0-9]{2}$'

    if [[ $date_str =~ $date_regex ]]; then
        return 0
    else
        return 1
    fi
}

validate_time() {
    local time_str=$1
    local time_regex='^[0-9]{2}\:[0-9]{2}$'

    if [[ $time_str =~ $time_regex ]]; then
        return 0
    else
        return 1
    fi
}
validate_day() {
    local day_str=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    local days=("monday" "tuesday" "wednesday" "thursday" "friday" "saturday" "sunday")

    for day in "${days[@]}"; do
        if [[ "$day_str" == "$day" ]]; then
            return 0
        fi
    done

    return 1
}

add_class() {
    read -p "Enter the class name: " class_name
    while true; do
        read -p "Enter the day of the week (e.g., Monday, Tuesday, etc.): " class_day
        if validate_day "$class_day"; then
            break
        else
            echo "Invalid day format. Please enter a valid day of the week."
        fi
    done

    while true; do
        read -p "Enter the time (HH:MM): " class_time
        if validate_time "$class_time"; then
            break
        else
            echo "Invalid time format. Please use the format HH:MM."
        fi
    done

    # Display the list of trainers
    echo "Select a trainer:"
    while IFS="," read -r name email phone; do
        echo "- $name"
    done < "trainers.txt"

    read -p "Enter the trainer name: " trainer_name

    # Check if the trainer exists
    if grep -q "$trainer_name" "trainers.txt"; then
        # Append class details to the schedule file
        echo "$class_name, $class_day, $class_time, $trainer_name" >> "schedule.txt"
        echo "Class added to the schedule successfully!"
    else
        echo "Trainer not found. Please add the trainer first."
    fi
}

view_class_schedule() {
    local schedule_data=$(cat "schedule.txt")
    if [ -n "$schedule_data" ]; then
        # Sort the schedule by day and time
        sorted_schedule=$(echo "$schedule_data" | sort -k2,2 -k3,3)

        current_day=""
        while IFS=',' read -r class_name class_day class_time trainer_name; do
            if [[ "$class_day" != "$current_day" ]]; then
                echo "====== $class_day ======="
                current_day="$class_day"
            fi
            echo "Class: $class_name"
            echo "Time: $class_time"
            echo "Trainer: $trainer_name"
            echo "---"
        done <<< "$sorted_schedule"
    else
        echo "No classes found in the schedule."
    fi
}

# Manage classes menu
manage_classes(){
while true; do
        echo "======= Classes Management ======="
        echo "1. Add New class"
        echo "2. View class schedule"
        echo "3. Exit"

        read -p "Enter your choice (1-3): " choice

        case $choice in
            1)
                add_class
                ;;
            2)
                view_class_schedule
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
}
