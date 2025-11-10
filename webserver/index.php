<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test Web Server</title>
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
            border-bottom: 3px solid #4CAF50;
            padding-bottom: 10px;
        }
        .info {
            background: #e8f5e9;
            padding: 15px;
            border-left: 4px solid #4CAF50;
            margin: 20px 0;
        }
        .status {
            display: inline-block;
            padding: 5px 10px;
            background: #4CAF50;
            color: white;
            border-radius: 4px;
            margin-left: 10px;
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
        <h1>🚀 Test Web Server <span class="status">ONLINE</span></h1>
        
        <div class="info">
            <h2>Server Information</h2>
            <p><strong>Server Software:</strong> <?php echo $_SERVER['SERVER_SOFTWARE']; ?></p>
            <p><strong>PHP Version:</strong> <?php echo phpversion(); ?></p>
            <p><strong>Server Name:</strong> <?php echo $_SERVER['SERVER_NAME']; ?></p>
            <p><strong>Server Address:</strong> <?php echo $_SERVER['SERVER_ADDR']; ?></p>
            <p><strong>Document Root:</strong> <?php echo $_SERVER['DOCUMENT_ROOT']; ?></p>
        </div>

        <div class="info">
            <h2>System Time</h2>
            <p><strong>Current Time:</strong> <?php echo date('Y-m-d H:i:s'); ?></p>
            <p><strong>Timezone:</strong> <?php echo date_default_timezone_get(); ?></p>
        </div>

        <div class="info">
            <h2>Database Test</h2>
            <p>Test MariaDB connection: <a href="db-test.php">Click here to test database</a></p>
        </div>

        <div class="info">
            <h2>PHP Extensions Loaded</h2>
            <p><?php echo implode(', ', get_loaded_extensions()); ?></p>
        </div>
    </div>
</body>
</html>
