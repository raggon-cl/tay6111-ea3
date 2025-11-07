# Proyecto Terraform: Evaluación Práctica N°3 (EA3)
> TAY6111 - TECNOLOGÍAS DE RESPALDO Y RECUPERACIÓN
> Duoc UC - Sede Antonio Varas

Este repositorio contiene el código de Infraestructura como Código (IaC) utilizando Terraform para la Evaluación Práctica N°3. El objetivo es desplegar una infraestructura base en AWS para el escenario de "DataCore Analytics", con un enfoque específico en la implementación de servicios de almacenamiento y respaldo.

---

## 🏗️ Arquitectura Desplegada

El código en este repositorio despliega la siguiente infraestructura en AWS:

* **Red (VPC):**
    * 1 VPC principal (`10.100.0.0/16`) con 2 Subnets Públicas y 2 Subnets Privadas en diferentes Zonas de Disponibilidad.
    * 1 Internet Gateway (IGW) y 1 Tabla de Rutas pública para dar acceso a internet.
* **Seguridad (Security Groups):**
    * 1 Security Group para el Servidor Web (`web-sg`): Permite tráfico **SSH (22)** y **HTTP (80)**.
    * 1 Security Group para EFS (`efs-sg`): Permite tráfico **NFS (2049)** solo desde el `web-sg`.
* **Cómputo (EC2):**
    * 1 Instancia EC2 (`t2.micro`) con Amazon Linux 2 en una subnet pública.
* **Almacenamiento EBS:**
    * 1 Volumen EBS de 8 GiB (`gp3`) asociado a la instancia EC2.
    * 1 Snapshot EBS del volumen de datos (tag: `snapshot-app-prod`).
* **Almacenamiento S3:**
    * 1 Bucket S3 con nombre único.
    * 1 Política de Ciclo de Vida que transiciona objetos a `STANDARD_IA` (30 días) y `GLACIER` (120 días).
* **Almacenamiento EFS:**
    * 1 File System EFS.
    * 2 Mount Targets (uno en cada subnet privada) para permitir que las instancias monten el EFS.

---

## 🗂️ Estructura de Archivos

* **`main.tf`**: Contiene la definición de todos los recursos de AWS.
* **`variables.tf`**: Define las variables de entrada (inputs) como la región, CIDR, etc.
* **`outputs.tf`**: Declara las salidas (outputs) que se mostrarán después del `apply` (IP pública, nombre del bucket, etc.).
* **`README.md`**: (Este archivo) Explicación del proyecto.

---

## ⚙️ Detalle de Recursos (`main.tf`)

A continuación, se explica el propósito de cada bloque `resource` y `data` en el archivo `main.tf`:

### 1. Configuración General
* **`terraform { ... }`**: Define los *providers* (AWS y Random) y sus versiones requeridas.
* **`provider "aws" { ... }`**: Configura el proveedor de AWS, indicando la región a utilizar (obtenida de `variables.tf`).

### 2. Requisito A: Infraestructura Base (Red)
* **`resource "aws_vpc" "main"`**: Crea la VPC (Virtual Private Cloud) principal para toda la infraestructura.
* **`resource "aws_subnet" "public"`**: Crea las 2 subnets públicas. Utiliza `count` para crear una en cada AZ definida en las variables.
* **`resource "aws_subnet" "private"`**: Crea las 2 subnets privadas. También utiliza `count` para desplegar en ambas AZ.
* **`resource "aws_internet_gateway" "main"`**: Crea el Internet Gateway (IGW) y lo asocia a nuestra VPC, permitiendo la comunicación con internet.
* **`resource "aws_route_table" "public"`**: Crea una tabla de rutas para el tráfico público.
* **`resource "aws_route_table_association" "public"`**: Asocia la tabla de rutas pública a las 2 subnets públicas, dándoles efectivamente salida a internet.

### 3. Requisito A: Infraestructura Base (Seguridad y Cómputo)
* **`resource "aws_security_group" "web_sg"`**: Define el *firewall* (Grupo de Seguridad) para la instancia EC2. Abre los puertos 22 (SSH) y 80 (HTTP) al mundo (`0.0.0.0/0`).
* **`resource "aws_security_group" "efs_sg"`**: Define el *firewall* para el EFS. Solo permite tráfico entrante por el puerto 2049 (NFS) y *únicamente* si proviene del `web_sg`.
* **`data "aws_ami" "amazon_linux_2"`**: Es un *data source*. No crea nada, sino que **busca** la ID de la AMI más reciente de Amazon Linux 2 para usarla en nuestra instancia EC2.
* **`resource "aws_instance" "web_server"`**: Crea la instancia EC2 (`t2.micro`). La ubica en la primera subnet pública y le asigna el `web_sg`.

### 4. Requisito B: Amazon EBS
* **`resource "aws_ebs_volume" "data_volume"`**: Crea el volumen de disco EBS de 8 GiB (`gp3`) en la misma Zona de Disponibilidad que la instancia EC2.
* **`resource "aws_volume_attachment" "ebs_attach"`**: "Conecta" (asocia) el volumen EBS (`data_volume`) a la instancia EC2 (`web_server`) como un dispositivo (`/dev/sdh`).
* **`resource "aws_ebs_snapshot" "data_snapshot"`**: Crea el snapshot (respaldo) del volumen EBS. Tiene una dependencia (`depends_on`) para asegurar que el volumen esté conectado a la instancia antes de tomar el snapshot.

### 5. Requisito C: Amazon S3
* **`resource "random_id" "bucket_suffix"`**: Utiliza el *provider* `random` para generar una cadena aleatoria de 8 bytes.
* **`resource "aws_s3_bucket" "logs_bucket"`**: Crea el bucket S3. Usa el `random_id` en el nombre (`datacore-logs-...`) para garantizar que el nombre sea globalmente único.
* **`resource "aws_s3_bucket_lifecycle_configuration" "logs_lifecycle"`**: Aplica la política de ciclo de vida al bucket. Define las reglas de transición: `STANDARD` -> `STANDARD_IA` (a los 30 días) -> `GLACIER` (a los 120 días).

### 6. Requisito D: Amazon EFS
* **`resource "aws_efs_file_system" "shared_fs"`**: Crea el sistema de archivos EFS (el "disco" compartido).
* **`resource "aws_efs_mount_target" "main"`**: Crea los puntos de acceso (Mount Targets) para el EFS. Usando `count`, crea 2 *targets* (uno en cada subnet privada) y les asigna el `efs_sg` para proteger el acceso.

---

## 🚀 Instrucciones de Despliegue

Sigue estos pasos para desplegar la infraestructura.

### Requisitos Previos

* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) (v1.0.0 o superior) instalado.
* Credenciales de AWS configuradas (para AWS Learned Lab).

### Pasos de Ejecución

1.  **Clonar el Repositorio**
    ```sh
    git clone [URL-DEL-REPOSITORIO]
    cd [NOMBRE-DEL-REPOSITORIO]
    ```

2.  **Inicializar Terraform**
    Descarga los *providers* de AWS y Random.
    ```sh
    terraform init
    ```

3.  **Planificar** (Recomendado)
    Muestra los cambios que Terraform va a realizar.
    ```sh
    terraform plan
    ```

4.  **Aplicar la Configuración**
    Crea la infraestructura en AWS. Deberás escribir `yes` para confirmar.
    ```sh
    terraform apply
    ```

5.  **Revisar las Salidas**
    Una vez completado, Terraform mostrará los valores definidos en `outputs.tf`.

6.  **Destruir la Infraestructura**
    **Elimina todos los recursos** creados. ¡Esencial para la demo!
    ```sh
    terraform destroy
    ```

---

## 📤 Salidas (Outputs)

Al finalizar `terraform apply`, se mostrarán los siguientes valores:

* **`ec2_public_ip`**: La dirección IP pública de la instancia EC2.
* **`s3_bucket_name`**: El nombre único del bucket S3 creado.
* **`ebs_snapshot_id`**: El ID del snapshot EBS del volumen de datos.
* **`efs_file_system_id`**: El ID del sistema de archivos EFS.
