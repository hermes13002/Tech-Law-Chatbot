# Law App

A Flutter application with a Dart Shelf API backend for legal assistance.

## Project Structure

- **Flutter App**: Mobile application for users to interact with the legal assistant
- **Shelf API**: Dart backend server that handles API requests and communicates with external services

## Getting Started

### Prerequisites

- Flutter SDK (^3.6.0)
- Dart SDK (^3.6.0)
- MongoDB account (for database)
- Groq API key (for AI capabilities)

### Local Development

1. Clone the repository
2. Install dependencies:
   ```
   cd law_app
   flutter pub get
   ```
3. Set up environment variables in `.env` file
4. Run the server:
   ```
   dart bin/server.dart
   ```
5. Run the Flutter app:
   ```
   flutter run
   ```

## Deploying to Globe.dev through GitHub

### Prerequisites

1. A GitHub account
2. A Globe.dev account
3. Your code pushed to a GitHub repository

### Deployment Steps

1. **Push your code to GitHub**:
   - Make sure all the necessary files are committed and pushed:
     - `Procfile`
     - `.globe/config.yaml`
     - Updated server code with environment variable support

2. **Connect your GitHub repository to Globe.dev**:
   - Log in to your Globe.dev account
   - Create a new project
   - Select "GitHub" as the source
   - Authorize Globe.dev to access your GitHub repositories
   - Select the repository containing your Law App

3. **Configure environment variables**:
   - In the Globe.dev dashboard, navigate to your project settings
   - Add the following environment variables:
     - `JWT_SECRET`: Your JWT secret key
     - `DB_URI`: Your MongoDB connection string
     - `GROQ_API_KEY`: Your Groq API key
     - Any other environment variables your application needs

4. **Deploy your application**:
   - Globe.dev will automatically detect the Dart application from the Procfile and .globe/config.yaml
   - Click "Deploy" to start the deployment process
   - Globe.dev will build and deploy your application

5. **Monitor the deployment**:
   - Globe.dev provides logs and monitoring tools to track your application's performance
   - Check the logs to ensure your application is running correctly

6. **Access your deployed application**:
   - Once deployment is complete, Globe.dev will provide a URL for your application
   - You can use this URL to access your API

### Continuous Deployment

Globe.dev supports continuous deployment from GitHub. Any changes pushed to your repository will trigger a new deployment automatically.

## Additional Resources

- [Globe.dev Documentation](https://docs.globe.dev)
- [Dart Shelf Documentation](https://pub.dev/packages/shelf)
- [Flutter Documentation](https://docs.flutter.dev)
