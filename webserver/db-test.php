<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Database Test</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #f4f4f4;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            border-bottom: 3px solid #2196F3;
            padding-bottom: 10px;
        }
        .success {
            background: #e8f5e9;
            padding: 15px;
            border-left: 4px solid #4CAF50;
            margin: 20px 0;
        }
        .error {
            background: #ffebee;
            padding: 15px;
            border-left: 4px solid #f44336;
            margin: 20px 0;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 12px;
            text-align: left;
        }
        th {
            background-color: #2196F3;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        a {
            color: #2196F3;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🗄️ MariaDB Connection Test</h1>
        
        <?php
        $host = 'localhost';
        $dbname = 'testdb';
        $username = 'testuser';
        $password = 'testpass123';

        try {
            // Create connection
            $conn = new mysqli($host, $username, $password, $dbname);

            // Check connection
            if ($conn->connect_error) {
                throw new Exception("Connection failed: " . $conn->connect_error);
            }

            echo '<div class="success">';
            echo '<h2>✅ Database Connection Successful!</h2>';
            echo '<p><strong>Host:</strong> ' . $host . '</p>';
            echo '<p><strong>Database:</strong> ' . $dbname . '</p>';
            echo '<p><strong>User:</strong> ' . $username . '</p>';
            echo '</div>';

            // Get MariaDB version
            $result = $conn->query("SELECT VERSION() as version");
            $row = $result->fetch_assoc();
            echo '<div class="success">';
            echo '<h2>Database Information</h2>';
            echo '<p><strong>MariaDB Version:</strong> ' . $row['version'] . '</p>';
            echo '</div>';

            // Query test data
            $result = $conn->query("SELECT * FROM users ORDER BY id");
            
            if ($result && $result->num_rows > 0) {
                echo '<div class="success">';
                echo '<h2>Test Data from "users" table</h2>';
                echo '<table>';
                echo '<tr><th>ID</th><th>Name</th><th>Email</th><th>Created At</th></tr>';
                
                while($row = $result->fetch_assoc()) {
                    echo '<tr>';
                    echo '<td>' . htmlspecialchars($row['id']) . '</td>';
                    echo '<td>' . htmlspecialchars($row['name']) . '</td>';
                    echo '<td>' . htmlspecialchars($row['email']) . '</td>';
                    echo '<td>' . htmlspecialchars($row['created_at']) . '</td>';
                    echo '</tr>';
                }
                
                echo '</table>';
                echo '</div>';
            }

            $conn->close();

        } catch (Exception $e) {
            echo '<div class="error">';
            echo '<h2>❌ Database Connection Failed</h2>';
            echo '<p>' . htmlspecialchars($e->getMessage()) . '</p>';
            echo '</div>';
        }
        ?>

        <p><a href="index.php">← Back to home</a></p>
    </div>
</body>
</html>
