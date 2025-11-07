# Proyecto Terraform: Evaluación Práctica N°3 (EA3)
> TAY6111 - TECNOLOGÍAS DE RESPALDO Y RECUPERACIÓN
> Duoc UC - Sede Antonio Varas

Este repositorio contiene el código de Infraestructura como Código (IaC) utilizando Terraform para la Evaluación Práctica N°3. El objetivo es desplegar una infraestructura base en AWS para el escenario de "DataCore Analytics", con un enfoque específico en la implementación de servicios de almacenamiento y respaldo.

---

## 🏗️ Arquitectura Desplegada

El código en este repositorio despliega la siguiente infraestructura en AWS:

### Requisito A: Infraestructura Base
* **Red (VPC):**
    * 1 VPC principal (`10.100.0.0/16`).
    * 2 Subnets Públicas (una en cada AZ, ej: `us-east-1a`, `us-east-1b`).
    * 2 Subnets Privadas (una en cada AZ, ej: `us-east-1a`, `us-east-1b`).
    * 1 Internet Gateway (IGW) para dar salida a internet.
    * 1 Tabla de Rutas pública asociada a las subnets públicas.
* **Seguridad (Security Groups):**
    * 1 Security Group para el Servidor Web (`web-sg`): Permite tráfico entrante por **SSH (22)** y **HTTP (80)** desde cualquier IP (`0.0.0.0/0`).
    * 1 Security Group para EFS (`efs-sg`): Permite tráfico entrante por **NFS (2049)** *únicamente* desde el `web-sg`.
* **Cómputo (EC2):**
    * 1 Instancia EC2 (`t2.micro`) con Amazon Linux 2, desplegada en una de las subnets públicas.

### Requisito B: Almacenamiento EBS y Respaldo
* **Volumen:** 1 Volumen Amazon EBS de 8 GiB (`gp3`).
* **Asociación:** El volumen EBS se asocia (attaches) a la instancia EC2 (`/dev/sdh`).
* **Snapshot:** 1 Snapshot EBS (`aws_ebs_snapshot`) creado a partir del volumen de datos, con el tag `Name = "snapshot-app-prod"`.

### Requisito C: Almacenamiento S3 y Ciclo de Vida
* **Bucket:** 1 Bucket S3 con un nombre globalmente único (generado con un sufijo aleatorio).
* **Política de Ciclo de Vida:** Se aplica una política al bucket para:
    1.  Mover objetos a `STANDARD_IA` después de **30 días**.
    2.  Mover objetos a `GLACIER` después de **120 días** (90 días adicionales después de IA).

### Requisito D: Almacenamiento EFS
* **File System:** 1 Sistema de archivos Amazon EFS.
* **Mount Targets:** 2 Destinos de Montaje (Mount Targets) para el EFS, uno en cada subnet privada, asociados al `efs-sg` para controlar el acceso.

---

## 🗂️ Estructura de Archivos

El código está organizado en los siguientes archivos, como se solicita en los entregables:

* **`main.tf`**: Contiene la definición de todos los recursos de AWS (VPC, Subnets, EC2, SGs, EBS, S3, EFS).
* **`variables.tf`**: Define todas las variables de entrada (inputs) como la región de AWS, los bloques CIDR y el tipo de instancia.
* **`outputs.tf`**: Declara las salidas (outputs) que se mostrarán después de un `apply` exitoso, como la IP pública de la EC2 y el nombre del bucket S3.

---

## 🚀 Instrucciones de Despliegue

Sigue estos pasos para desplegar la infraestructura.

### Requisitos Previos

* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) (v1.0.0 o superior) instalado.
* Credenciales de AWS configuradas (para AWS Learned Lab), ya sea mediante variables de entorno o el archivo `~/.aws/credentials`.

### Pasos de Ejecución

1.  **Clonar el Repositorio**
    ```sh
    git clone [URL-DEL-REPOSITORIO]
    cd [NOMBRE-DEL-REPOSITORIO]
    ```

2.  **Inicializar Terraform**
    Este comando descarga los *providers* necesarios (en este caso, `aws` y `random`).
    ```sh
    terraform init
    ```

3.  **Validar y Planificar** (Opcional pero recomendado)
    Revisa la sintaxis y luego genera un plan de ejecución para ver qué recursos creará Terraform.
    ```sh
    terraform validate
    terraform plan
    ```

4.  **Aplicar la Configuración**
    Este comando crea la infraestructura en AWS. Deberás escribir `yes` para confirmar la ejecución.
    ```sh
    terraform apply
    ```

5.  **Revisar las Salidas**
    Una vez completado, Terraform mostrará los valores definidos en `outputs.tf`.

6.  **Destruir la Infraestructura**
    Este comando **eliminará todos los recursos** creados por Terraform. Es fundamental para la presentación y para no generar costos.
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

---

## 🧑‍💻 Autores

* **Integrante 1:** [Tu Nombre y Apellido]
* **Integrante 2:** [Nombre y Apellido de tu Compañero]
