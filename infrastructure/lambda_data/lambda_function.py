import os
import logging
import boto3
import psycopg2


# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    # Log the incoming event
    logger.info(f"Event: {event}")

    # Environment variables
    rds_host = os.environ['POSTGRES_HOST']
    rds_port = os.environ['POSTGRES_PORT']
    db_name = os.environ['POSTGRES_DB']
    db_user = os.environ['POSTGRES_USER']
    db_password = os.environ['POSTGRES_PASSWORD']
    s3_bucket = os.environ['S3_BUCKET_NAME']
    s3_key = os.environ['S3_OBJECT_KEY']
    region = os.environ['S3_REGION']

    # Log environment variables (for debugging)
    logger.info(f"RDS Host: {rds_host}")
    logger.info(f"RDS Port: {rds_port}")
    logger.info(f"Database Name: {db_name}")
    logger.info(f"S3 Bucket: {s3_bucket}")
    logger.info(f"S3 Key: {s3_key}")

    # Initialize S3 client
    s3 = boto3.client('s3', region_name=region)

    try:
        logger.info(f"Listing objects in S3 bucket: {s3_bucket}")
        response = s3.list_objects_v2(Bucket=s3_bucket)
        logger.info(f"S3 Objects: {response['Contents']}")
    except Exception as e:
        logger.error(f"Failed to list S3 objects: {str(e)}")
        return {
            'statusCode': 500,
            'body': f"Failed to list S3 objects: {str(e)}"
        }

    try:
        # Download the SQL dump file from S3
        sql_file = f"/tmp/{os.path.basename(s3_key)}"
        logger.info(f"Downloading SQL file from S3: {s3_bucket}/{s3_key}")
        s3.download_file(s3_bucket, s3_key, sql_file)
        logger.info(f"Downloaded SQL dump file: {s3_key}")

        # Connect to RDS PostgreSQL
        logger.info("Connecting to RDS PostgreSQL...")
        conn = psycopg2.connect(
            host=rds_host,
            port=rds_port,
            database=db_name,
            user=db_user,
            password=db_password
        )
        cursor = conn.cursor()
        logger.info("Connected to RDS PostgreSQL.")

        # Execute the SQL file
        logger.info("Executing SQL commands...")
        with open(sql_file, 'r') as file:
            sql_commands = file.read()
            cursor.execute(sql_commands)
            logger.info("Executed SQL commands successfully.")

        conn.commit()
        cursor.close()
        conn.close()

        return {
            'statusCode': 200,
            'body': 'Database populated successfully!'
        }
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': f"Error: {str(e)}"
        }