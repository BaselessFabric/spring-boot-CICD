# Use an official Eclipse Temurin runtime as a parent image
FROM eclipse-temurin:21-jre

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy the JAR file to the working directory
COPY app.jar /usr/src/app/app.jar

# Expose port 8080
EXPOSE 8080

# Run the application
CMD ["java", "-jar", "app.jar"]
