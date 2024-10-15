import os
import logging
from datetime import datetime
from googleapiclient import discovery
from google.oauth2 import service_account

# Google Cloud parameters
project_id = 'your-project-id'
bucket_name = 'ti-dba-bucket'
backup_folder = 'Backups'
key_file = '/root/jsonfiles/ti-dba-prod-01.json'

# Cloud SQL instance parameters
instance_name = 'mysqldbv8'
databases = 'all'  # 'all' for all databases or list specific databases e.g., 'db1,db2'

# Logging Configuration
log_path = "/backup/logs/"
os.makedirs(log_path, exist_ok=True)
current_date = datetime.now().strftime("%Y-%m-%d")
log_filename = os.path.join(log_path, "MYSQL_backup_activity_{}.log".format(current_date))
logging.basicConfig(filename=log_filename, level=logging.INFO, format='%(asctime)s %(levelname)s: %(message)s')

def list_databases(service, project_id, instance_name):
    try:
        request = service.databases().list(project=project_id, instance=instance_name)
        response = request.execute()
        database_list = [db['name'] for db in response['items']]
        return database_list
    except Exception as e:
        logging.error(f"Failed to list databases: {e}")
        print(f"Failed to list databases: {e}")
        return []

def initiate_export(project_id, instance_name, bucket_name, backup_folder, key_file, databases):
    try:
        credentials = service_account.Credentials.from_service_account_file(key_file)
        service = discovery.build('sqladmin', 'v1beta4', credentials=credentials)

        # Get all database names if 'databases' is set to 'all'
        if databases == 'all':
            database_list = list_databases(service, project_id, instance_name)
        else:
            database_list = databases.split(',')

        for db in database_list:
            filename = datetime.now().strftime('%Y-%m-%d') + f'_{db}.sql.gz'
            destination_uri = f'gs://{bucket_name}/{backup_folder}/{filename}'

            body = {
                'exportContext': {
                    'fileType': 'SQL',
                    'uri': destination_uri,
                    'databases': [db],
                    'offload': True
                }
            }

            request = service.instances().export(
                project=project_id,
                instance=instance_name,
                body=body
            )

            response = request.execute()
            logging.info(f"Backup initiated for database {db}: {response}")
            print(f"Backup initiated for database {db}: {response}")

    except Exception as e:
        logging.error(f"An error occurred during export: {e}")
        print(f"An error occurred during export: {e}")

if __name__ == '__main__':
    initiate_export(project_id, instance_name, bucket_name, backup_folder, key_file, databases)
