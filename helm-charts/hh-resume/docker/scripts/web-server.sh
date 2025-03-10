#!/bin/bash

# Set the port
PORT=${WEB_PORT:-8080}

# Create a directory for web files
mkdir -p /app/web

# Create a simple HTML status page
cat > /app/web/index.html << EOF
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HH.ru Resume Updater</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1 {
            color: #0072b1;
        }
        .status {
            margin: 20px 0;
            padding: 15px;
            border-radius: 5px;
        }
        .status.active {
            background-color: #e6f7e6;
            border: 1px solid #c3e6cb;
        }
        .status.inactive {
            background-color: #f8d7da;
            border: 1px solid #f5c6cb;
        }
        .log {
            background-color: #f8f9fa;
            border: 1px solid #e9ecef;
            padding: 15px;
            border-radius: 5px;
            max-height: 300px;
            overflow-y: auto;
            font-family: monospace;
            white-space: pre-wrap;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>HH.ru Resume Updater</h1>
        <div class="status active">
            <h2>Статус: Активен</h2>
            <p>Резюме ID: <span id="resume-id">RESUME_ID_PLACEHOLDER</span></p>
            <p>Расписание обновления: <span id="schedule">SCHEDULE_PLACEHOLDER</span></p>
            <p>Последнее обновление: <span id="last-update">LAST_UPDATE_PLACEHOLDER</span></p>
            <p>Следующее обновление: <span id="next-update">NEXT_UPDATE_PLACEHOLDER</span></p>
        </div>
        
        <h2>История обновлений</h2>
        <div class="log" id="update-log">
            HISTORY_PLACEHOLDER
        </div>
    </div>

    <script>
        // Функция для обновления данных на странице
        function updateStatus() {
            fetch('/api/status')
                .then(response => response.json())
                .then(data => {
                    document.getElementById('resume-id').textContent = data.resumeId;
                    document.getElementById('schedule').textContent = data.schedule;
                    document.getElementById('last-update').textContent = data.lastUpdate;
                    document.getElementById('next-update').textContent = data.nextUpdate;
                    
                    // Обновление истории
                    if (data.history) {
                        document.getElementById('update-log').textContent = data.history;
                    }
                })
                .catch(error => console.error('Error fetching status:', error));
        }
        
        // Обновление данных каждые 60 секунд
        updateStatus();
        setInterval(updateStatus, 60000);
    </script>
</body>
</html>
EOF

# Function to handle API requests
handle_request() {
    local request="$1"
    local response=""
    
    # Extract the request path
    local path=$(echo "$request" | head -n 1 | cut -d ' ' -f 2)
    
    if [[ "$path" == "/api/status" ]]; then
        # Get resume ID from environment variable
        local resume_id=${HH_RESUME_ID:-"Не указан"}
        
        # Get schedule from environment variable
        local schedule=${SCHEDULE:-"Не указано"}
        
        # Get last update time from log file
        local last_update="Нет данных"
        if [[ -f /app/resume/update-history.log ]]; then
            last_update=$(tail -n 1 /app/resume/update-history.log 2>/dev/null || echo "Нет данных")
        fi
        
        # Calculate next update time (placeholder)
        local next_update="Не запланировано"
        
        # Get update history
        local history="Нет данных"
        if [[ -f /app/resume/update-history.log ]]; then
            history=$(cat /app/resume/update-history.log 2>/dev/null || echo "Нет данных")
        fi
        
        # Create JSON response
        response="HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n"
        response+="{"
        response+="\"resumeId\":\"$resume_id\","
        response+="\"schedule\":\"$schedule\","
        response+="\"lastUpdate\":\"$last_update\","
        response+="\"nextUpdate\":\"$next_update\","
        response+="\"history\":\"$history\""
        response+="}"
    elif [[ "$path" == "/" || "$path" == "/index.html" ]]; then
        # Serve the HTML page
        response="HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n"
        response+=$(cat /app/web/index.html)
    else
        # 404 Not Found
        response="HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\n\r\n404 Not Found"
    fi
    
    echo -e "$response"
}

# Start a simple web server
echo "Starting web server on port $PORT..."
while true; do
    nc -l -p $PORT | while read request; do
        handle_request "$request" | nc -q 0 $(echo "$request" | awk '{print $1}') $PORT
    done
done