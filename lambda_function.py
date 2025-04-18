import json
import os
import urllib.parse
import boto3
import shutil

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    # Obtiene información del bucket y del archivo desde el evento
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])
    
    # Define la ruta en EFS donde se guardará el archivo
    efs_mount_path = os.environ.get('EFS_MOUNT_PATH', '/mnt/efs')
    
    # Asegura que el directorio exista
    os.makedirs(os.path.dirname(f"{efs_mount_path}/{key}"), exist_ok=True)
    
    # Descarga el archivo del bucket S3 a una ubicación temporal
    download_path = f"/tmp/{os.path.basename(key)}"
    s3_client.download_file(bucket, key, download_path)
    
    # Copia el archivo de la ubicación temporal al EFS
    shutil.copy2(download_path, f"{efs_mount_path}/{key}")
    
    # Limpia el archivo temporal
    os.remove(download_path)
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Archivo {key} copiado exitosamente a EFS')
    }