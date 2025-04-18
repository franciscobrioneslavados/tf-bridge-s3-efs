# Guía: Subir Archivos a S3 y Transferirlos a EFS
### Instrucciones Paso a Paso para la Gestión de Archivos y Directorios 

## Comandos de Terraform para Desplegar
### Comandos necesarios para inicializar y desplegar la infraestructura con Terraform:
```bash
terraform init
```
### Validar la Configuración
#### Asegúrate de que la configuración de Terraform sea válida:
```bash
terraform validate
```
### Previsualizar los Cambios (Plan)
#### Genera un plan de ejecución para revisar los cambios que se aplicarán:
```bash
terraform plan -var-file="tfvars" --out tfplan
```
### Aplicar los Cambios
#### Despliega la infraestructura definida en los archivos de Terraform:
```bash
terraform apply "tfplan"
```
### Destruir la Infraestructura (Opcional)
#### Si necesitas eliminar la infraestructura creada, utiliza el siguiente comando:
```bash
terraform destroy --auto-approve
```
### Notas Importantes
#### Archivo terraform.tfvars: Este archivo contiene los valores de las variables y se utiliza automáticamente por Terraform. Asegúrate de no compartirlo si contiene información sensible.
Eliminación Forzada del Bucket S3: La variable force_destroy_bucket está configurada en true, lo que permite eliminar el bucket incluso si contiene objetos. Úsalo con precaución, especialmente en entornos de producción.

## Subir un archivo al bucket:
#### Para subir un archivo específico al bucket de S3, utiliza el siguiente comando. Este comando toma el archivo local `mi_archivo.txt` y lo copia al bucket `mi-bucket-s3-unico` en la ruta especificada (`archivos/mi_archivo.txt`). Asegúrate de que el archivo exista en tu sistema local y de que tengas los permisos necesarios para interactuar con el bucket de S3.
```bash
aws s3 cp mi_archivo.txt s3://mi-bucket-s3-unico/archivos/mi_archivo.txt
```
### Subir un directorio completo:
#### Si necesitas subir un directorio completo con múltiples archivos y subdirectorios, puedes usar el siguiente comando. Este comando copia de forma recursiva todo el contenido del directorio local mi_directorio al bucket de S3 en la ruta archivos/. Es ideal para transferir grandes cantidades de datos de una sola vez.
```bash
aws s3 cp --recursive ./mi_directorio/ s3://mi-bucket-s3-unico/archivos/
```
### Verificar que el archivo se ha subido:
#### Después de subir un archivo o directorio, puedes verificar que los datos se encuentran en el bucket de S3 utilizando este comando. Este comando lista los archivos y directorios presentes en la ruta especificada dentro del bucket. Es útil para confirmar que la operación de subida fue exitosa.
```bash
aws s3 ls s3://mi-bucket-s3-unico/archivos/
```
### Ver los logs del Lambda:
#### Para depurar o monitorear el comportamiento de la función Lambda que procesa los eventos de S3, puedes consultar los logs generados. Este comando filtra los eventos del grupo de logs asociado a la función Lambda (/aws/lambda/s3-to-efs-function) y muestra los mensajes generados en la última hora. Esto es útil para identificar errores o confirmar que la función Lambda se ejecutó correctamente.
```bash
aws logs filter-log-events --log-group-name /aws/lambda/s3-to-efs-function --start-time $(date --date="1 hour ago" +%s000) --query "events[*].message" --output text
```
## Descripción Técnica del Flujo de Trabajo
### Arquitectura Basada en Eventos:
Cada vez que se sube un archivo al bucket de S3 (mi-bucket-s3-unico), se genera una notificación de evento que activa una función Lambda.

### Ejecución de la Función Lambda:
La función Lambda procesa el evento, recupera el archivo subido desde el bucket de S3 y lo transfiere a un directorio compartido en el sistema de archivos elástico (EFS).

### Integración con EFS:
El sistema EFS está montado en una instancia EC2, proporcionando un sistema de archivos compartido accesible para múltiples servicios. Esto garantiza la persistencia y disponibilidad de los archivos.

### Verificación en la Instancia EC2:
La instancia EC2 está configurada para montar el directorio de EFS. Los usuarios pueden conectarse a la instancia mediante SSH para verificar la presencia de los archivos transferidos.

### Verificar la Transferencia de Archivos en EC2
#### Conéctate a la Instancia EC2:
Usa el siguiente comando para establecer una conexión SSH:
```bash
ssh -i "mi-clave.pem" ec2-user@<IP-de-la-instancia>
```
### Navega al Punto de Montaje de EFS:
### Una vez conectado, navega al directorio donde está montado EFS:
```bash
cd /mnt/efs
```
### Lista los Archivos en el Directorio:
#### Verifica la presencia del archivo transferido:
```bash
ls -l
```