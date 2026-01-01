provider "aws" {
  region = "us-east-1"  # או כל Region אחר שנוח לכם
}

# 1. יצירת VPC חדש
# זהו "הבית" של הרשת שלנו. טווח הכתובות הוא 10.0.0.0/16
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "DevOps-Course-VPC"
  }
}

# 2. יצירת Internet Gateway (IGW)
# זה "הדלת" שמאפשרת יציאה וכניסה מהאינטרנט.
# בלי זה - השרתים מבודדים לגמרי ולא יוכלו להוריד חבילות התקנה.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "Main-IGW"
  }
}

# 3. יצירת Subnet ציבורית
# שים לב לשורה map_public_ip_on_launch = true
# זה קריטי למשימה שלנו! זה אומר שכל שרת שיקום כאן יקבל IP ציבורי אוטומטית.
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true 

  tags = {
    Name = "Public-Subnet"
  }
}

# 4. יצירת Route Table (טבלת ניתוב)
# כאן אנחנו אומרים: "כל תעבורה שיוצאת לעולם (0.0.0.0/0) - תעבור דרך ה-IGW"
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

# 5. חיבור ה-Subnet ל-Route Table
# בלי החלק הזה, הסאבנט לא "ידע" להשתמש בניתוב שיצרנו למעלה.
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
# --- תוספת: שרתים ואבטחה ---

# 1. משיכת ה-AMI העדכני של אובונטו 22.04
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# 2. Security Group לשרת ה-Web
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Security Group לשרת ה-DB
resource "aws_security_group" "db_sg" {
  name        = "db-server-sg"
  description = "Allow DB access from Web SG only"
  vpc_id      = aws_vpc.main_vpc.id

  # חוק הברזל: גישה ל-DB רק מקבוצת האבטחה של ה-Web
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  # SSH לניהול
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. שרת ה-Web
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = "devops-key" # המפתח שיצרת בקונסולה
  
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "Web-Server-Flask"
  }
}

# 5. שרת ה-DB
resource "aws_instance" "db_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = "devops-key"

  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = "DB-Server-Postgres"
  }
}

# 6. Outputs - זה מה שנחתך לך קודם!
# החלק הזה ידפיס את הכתובות בסוף הריצה
output "web_server_ip" {
  value = aws_instance.web_server.public_ip
}

output "db_server_ip" {
  value = aws_instance.db_server.public_ip
}
