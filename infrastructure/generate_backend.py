import subprocess
import os

# Define paths
bootstrap_dir = os.path.join(os.getcwd(), "..", "bootstrap")
infrastructure_dir = os.getcwd()

# Verify that the bootstrap directory exists
if not os.path.exists(bootstrap_dir):
    print(f"Error: The directory '{bootstrap_dir}' does not exist.")
    exit(1)

# Verify that the infrastructure directory exists
if not os.path.exists(infrastructure_dir):
    print(f"Error: The directory '{infrastructure_dir}' does not exist.")
    exit(1)

# Run the bootstrap process
try:
    subprocess.run(["terraform", "init"], cwd=bootstrap_dir, check=True)
    subprocess.run(["terraform", "apply", "-auto-approve"], cwd=bootstrap_dir, check=True)
except subprocess.CalledProcessError as e:
    print(f"Error running Terraform: {e}")
    exit(1)

# Capture outputs from the bootstrap process
try:
    tf_state_bucket_name = subprocess.run(
        ["terraform", "output", "-raw", "tf_state_bucket_name"],
        cwd=bootstrap_dir,
        capture_output=True,
        text=True,
    ).stdout.strip()

    region = subprocess.run(
        ["terraform", "output", "-raw", "region"],
        cwd=bootstrap_dir,
        capture_output=True,
        text=True,
    ).stdout.strip()

    tf_state_lock_table = subprocess.run(
        ["terraform", "output", "-raw", "tf_state_lock_table"],
        cwd=bootstrap_dir,
        capture_output=True,
        text=True,
    ).stdout.strip()
except subprocess.CalledProcessError as e:
    print(f"Error capturing Terraform outputs: {e}")
    exit(1)

# Generate backend.tf
backend_tf_content = f"""
terraform {{
  backend "s3" {{
    bucket         = "{tf_state_bucket_name}"
    key            = "terraform_state/statefile.tfstate"
    region         = "{region}"
    encrypt        = true
    dynamodb_table = "{tf_state_lock_table}"
  }}
}}
"""

# Write the generated backend.tf file
output_path = os.path.join(infrastructure_dir, "backend.tf")
with open(output_path, "w") as backend_file:
    backend_file.write(backend_tf_content)

print(f"Generated {output_path}")
