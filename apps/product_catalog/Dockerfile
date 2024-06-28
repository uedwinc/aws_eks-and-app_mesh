FROM python:3.10

# Create and set the working directory
RUN mkdir /app
WORKDIR /app

# Copy and install dependencies
COPY requirements.txt /app
RUN pip install -r requirements.txt

# Copy the application code
COPY . /app

# Ensure the bootstrap.sh script has execute permissions
RUN chmod +x /app/bootstrap.sh

# ENV AGG_APP_URL='http://prodinfo.octank-mesh-ns.svc.cluster.local:3000/productAgreement'

# Expose the necessary port
EXPOSE 5000

# Set the entrypoint to run the bootstrap.sh script
ENTRYPOINT ["/app/bootstrap.sh"]