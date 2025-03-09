#!/bin/bash
#
# This script deploys an e-commerce application on a CentOS server.
# Author: Renan Garcia
# Email: renanrgarcia@gmail.com

# Functions

#############################
# Print colored text in the console.
# Arguments:
#   $1: color of the text. Eg: green, red, etc.
#   $2: text to be printed.
#############################
function print_color() {
    case $1 in
    "green") COLOR="\033[0;32m" ;;
    "red") COLOR="\033[0;31m" ;;
    "*") COLOR="\033[0m" ;;
    esac

    NC="\033[0m"

    echo -e "${COLOR} $2 ${NC}"
}

#############################
# Check if a service is active.
# Arguments:
#   $1: service name.
#############################
function check_service_status() {
    is_service_active=$(sudo systemctl is-active $1)

    if [ "$is_service_active" = "active" ]; then
        print_color "green" "$service_name is active."
    else
        print_color "red" "$service_name is not active."
        exit 1
    fi
}

#############################
# Check if a firewall rule is configured.
# Arguments:
#   $1: port number.
#############################
function is_firewalld_rule_configured() {
    firewall_ports=$(sudo firewall-cmd --list-all --zone=public | grep ports)

    if [[ $firewall_ports == *"$1"* ]]; then
        print_color "green" "Port $1 is open in the firewall."
    else
        print_color "red" "Port $1 is not open in the firewall."
        exit 1
    fi
}

#############################
# Check if an item is present on a web page.
# Arguments:
#   $1: web page content.
#   $2: item to be checked.
#############################
function check_item() {
    if [[ $1 == *"$2"* ]]; then
        print_color "green" "$2 is present on the web page."
    else
        print_color "red" "$2 is not present on the web page."
        exit 1
    fi
}

# ----------- DB Configuration -----------
# Install and start firewalld
print_color "green" "Installing and starting firewalld..."
sudo yum install -y firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld
check_service_status firewalld

# Install and start MariaDB server
print_color "green" "Installing and starting MariaDB server..."
sudo yum install -y mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb
check_service_status mariadb

# Open port 3306 for MariaDB in the firewall
print_color "green" "Opening port 3306 for MariaDB in the firewall..."
sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --reload
is_firewalld_rule_configured 3306

# Create a database and user for the e-commerce application
print_color "green" "Creating database and user for the e-commerce application..."
cat >config-db.sql <<-EOF
CREATE DATABASE ecomdb;
CREATE USER 'ecomuser'@'localhost' IDENTIFIED BY 'ecompassword';
GRANT ALL PRIVILEGES ON *.* TO 'ecomuser'@'localhost';
FLUSH PRIVILEGES;
EOF

# Execute the database configuration script
print_color "green" "Executing the database configuration script..."
sudo mysql <config-db.sql

# Load initial data into the e-commerce database
print_color "green" "Loading initial data into the e-commerce database..."
cat >db-load-script.sql <<-EOF
USE ecomdb;
CREATE TABLE products (id mediumint(8) unsigned NOT NULL auto_increment,Name varchar(255) default NULL,Price varchar(255) default NULL, ImageUrl varchar(255) default NULL,PRIMARY KEY (id)) AUTO_INCREMENT=1;

INSERT INTO products (Name,Price,ImageUrl) VALUES ("Laptop","100","c-1.png"),("Drone","200","c-2.png"),("VR","300","c-3.png"),("Tablet","50","c-5.png"),("Watch","90","c-6.png"),("Phone Covers","20","c-7.png"),("Phone","80","c-8.png"),("Laptop","150","c-4.png");
EOF

# Execute the data load script
print_color "green" "Executing the data load script..."
sudo mysql <db-load-script.sql
mysql_db_results=$(sudo mysql -e "use ecomdb; select * from products;")
if [[ $mysql_db_results == *"Laptop"* ]]; then
    print_color "green" "Data loaded successfully."
else
    print_color "red" "Data load failed."
    exit 1
fi

# ----------- Web Server Configuration -----------
# Install Apache, PHP, and PHP MySQL extension
print_color "green" "Installing Apache, PHP, and PHP MySQL extension..."
sudo yum install -y httpd php php-mysqlnd

# Open port 80 for HTTP in the firewall
print_color "green" "Opening port 80 for HTTP in the firewall..."
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
sudo firewall-cmd --reload
is_firewalld_rule_configured 80

# Configure Apache to use index.php as the default index file
print_color "green" "Configuring Apache to use index.php as the default index file..."
sudo sed -i 's/index.html/index.php/g' /etc/httpd/conf/httpd.conf

# Start and enable Apache
print_color "green" "Starting and enabling Apache..."
sudo systemctl start httpd
sudo systemctl enable httpd
check_service_status httpd

# Install Git and clone the e-commerce application repository
print_color "green" "Installing Git and cloning the e-commerce application repository..."
sudo yum install -y git
sudo git clone https://github.com/kodekloudhub/learning-app-ecommerce.git /var/www/html/

# Create a .env file with database connection details
print_color "green" "Creating a .env file with database connection details..."
sudo tee -a /var/www/html/.env >/dev/null <<-EOF
DB_HOST=localhost
DB_USER=ecomuser
DB_PASSWORD=ecompassword
DB_NAME=ecomdb
EOF

# Create the main index.php file for the e-commerce application
print_color "green" "Creating the main index.php file for the e-commerce application..."
sudo tee /var/www/html/index.php >/dev/null <<-EOF
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">

        <title>Kodekloud E-Commerce</title>

        <!-- Favicon -->
        <link rel="icon" href="img/favicon.png" type="image/png" />
        <!-- Bootstrap CSS -->
        <link href="css/bootstrap.min.css" rel="stylesheet">
        <!-- Icon CSS-->
        <link rel="stylesheet" href="vendors/font-awesome/css/font-awesome.min.css">
        <link rel="stylesheet" href="vendors/linearicons/linearicons-1.0.0.css">
        <!-- Animations CSS-->
        <link rel="stylesheet" href="vendors/wow-js/animate.css">
        <!-- owl_carousel-->
        <link rel="stylesheet" href="vendors/owl_carousel/owl.carousel.css">

        <!-- Theme style CSS -->
        <link href="css/style.css" rel="stylesheet">
<!--        <link href="css/responsive.css" rel="stylesheet">  -->

        <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
        <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
        <!--[if lt IE 9]>
          <script src="https://oss.maxcdn.com/html5shiv/3.7.3/html5shiv.min.js"></script>
          <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
        <![endif]-->
    </head>
    <body>
        <!--==========Main Header==========-->
        <header class="main_header_area">
            <nav class="navbar navbar-default navbar-fixed-top" id="main_navbar">
                <div class="container-fluid searchForm">
                    <form action="#" class="row">
                        <div class="input-group">
                            <span class="input-group-addon"><i class="lnr lnr-magnifier"></i></span>
                            <input type="search" name="search" class="form-control" placeholder="Type & Hit Enter">
                            <span class="input-group-addon form_hide"><i class="lnr lnr-cross"></i></span>
                        </div>
                    </form>
                </div>
                <div class="container">
                    <div class="row">
                    <!-- Brand and toggle get grouped for better mobile display -->
                    <div class="col-md-2 p0">
                        <div class="navbar-header">
                            <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1" aria-expanded="false">
                            <span class="sr-only">Toggle navigation</span>
                            <span class="icon-bar"></span>
                            <span class="icon-bar"></span>
                            <span class="icon-bar"></span>
                            </button>
                            <a class="navbar-brand" href="index.html">
                                <img src="img/logo.png" alt="">
                                <img src="img/logo-2.png" alt="">
                            </a>
                        </div>
                    </div>

                    <!-- Collect the nav links, forms, and other content for toggling -->
                    <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
                        <div class="col-md-9 p0">
                            <ul class="nav navbar-nav main_nav">
                              <li><a href="#">Laptops</a></li>
                              <li><a href="#">Drones</a></li>
                                <li><a href="#">Gadgets</a></li>
                                <li><a href="#">Phones</a></li>
                                <li><a href="#">VR</a></li>
                                <li><a href="#">Contact us</a></li>
                            </ul>
                        </div>
                        <div class="col-md-1 p0">
                            <ul class="nav navbar-nav navbar-right">
                                <li><a href="#" class="nav_searchFrom"><i class="lnr lnr-magnifier"></i></a></li>
                            </ul>
                        </div>
                    </div><!-- /.navbar-collapse -->
                    </div>
                </div><!-- /.container-fluid -->
            </nav>
        </header>
        <!--==========Main Header==========-->

        <!--==========Slider area==========-->
        <section class="slider_area row m0">
            <div class="slider_inner">
                <div class="camera_caption">
                    <h2 class="wow fadeInUp animated">Make Your Shopping Easy</h2>
                    <h5 class="wow fadeIn animated" data-wow-delay="0.3s">Find everything accordingly</h5>
                    <a class="learn_mor wow fadeInU" data-wow-delay="0.6s" href="#product-list">Show Now!</a>
                </div>
            </div>
        </section>
        <!--==========End Slider area==========-->

        <section class="best_business_area row">
            <div class="check_tittle wow fadeInUp" data-wow-delay="0.7s" id="product-list">
                <h2>Product List</h2>
            </div>
            <div class="row it_works">
              <?php
                        // Function to load environment variables from a .env file
                        function loadEnv(\$path)
                        {
                            if (!file_exists(\$path)) {
                                return false;
                            }

                            \$lines = file(\$path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
                            foreach (\$lines as \$line) {
                                if (strpos(trim(\$line), '#') === 0) {
                                    continue;
                                }

                                list(\$name, \$value) = explode('=', \$line, 2);
                                \$name = trim(\$name);
                                \$value = trim(\$value);
                                putenv(sprintf('%s=%s', \$name, \$value));
                            }
                            return true;
                        }

                        // Load environment variables from .env file
                        loadEnv(__DIR__ . '/.env');

                        // \$link = mysqli_connect('172.20.1.101', 'ecomuser', 'ecompassword', 'ecomdb');
                        // Fetch database connection details directly from environment variables
                        \$dbHost = getenv('DB_HOST');
                        \$dbUser = getenv('DB_USER');
                        \$dbPassword = getenv('DB_PASSWORD');
                        \$dbName = getenv('DB_NAME');

                        // Attempt to connect to the database
                        \$link = mysqli_connect(\$dbHost, \$dbUser, \$dbPassword, \$dbName);

                        if (\$link) {
                        \$res = mysqli_query(\$link, "select * from products;");
                        while (\$row = mysqli_fetch_assoc(\$res)) { ?>

                <div class="col-md-3 col-sm-6 business_content">
                    <?php echo '<img src="img/' . \$row['ImageUrl'] . '" alt="">' ?>
                    <div class="media">
                        <div class="media-left">

                        </div>
                        <div class="media-body">
                            <a href="#"><?php echo \$row['Name'] ?></a>
                            <p>Purchase <?php echo \$row['Name'] ?> at the lowest price <span><?php echo \$row['Price'] ?>\$</span></p>
                        </div>
                    </div>
                </div>

                <?php
                        }
                    }
                    else {
                ?>
                <div style="width: 100%">
                <div class="error-content">

                    <h1>Database connection error</h1>
                    <p>
                    <?php
                          echo mysqli_connect_errno() . ":" . mysqli_connect_error();
                    ?>
                    </p>
                  </div>
                  </div>
                  <?php
                    }
                  ?>


            </div>
        </section>


        <footer class="footer_area row">
            <div class="container custom-container">



                <div class=scriptright_area">
                    <h4 class="copy_right">© Copyright 2019 Kodekloud Ecommerce | All Rights Reserved</h4>
                </div>
            </div>
        </footer>

        <!-- jQuery -->
        <script src="js/jquery-1.12.4.min.js"></script>
        <!-- Bootstrap -->
        <script src="js/bootstrap.min.js"></script>
        <!-- Wow js -->
        <script src="vendors/wow-js/wow.min.js"></script>
        <!-- Wow js -->
        <script src="vendors/Counter-Up/waypoints.min.js"></script>
        <script src="vendors/Counter-Up/jquery.counterup.min.js"></script>
        <!-- Stellar js -->
        <script src="vendors/stellar/jquery.stellar.js"></script>
        <!-- owl_carousel js -->
        <script src="vendors/owl_carousel/owl.carousel.min.js"></script>
        <!-- Theme js -->
        <script src="js/theme.js"></script>
    </body>
</html>
EOF

web_page=$(curl -s http://localhost)

for item in Laptop Drone VR; do
    check_item "$web_page" $item
done
