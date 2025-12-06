# Hotstar Clone - Production-Ready Application

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)]()
[![Quality Gate](https://img.shields.io/badge/quality%20gate-passing-brightgreen)]()
[![Security](https://img.shields.io/badge/security-scanned-brightgreen)]()

A production-ready Hotstar clone built with React, featuring a complete DevSecOps pipeline with security scanning, containerization, and Kubernetes deployment.

## 🚀 Features

- **Modern React Application** - Built with React 18
- **Production-Ready** - Optimized Docker images, health checks, and monitoring
- **DevSecOps Pipeline** - Automated CI/CD with security scanning
- **Kubernetes Ready** - HA deployment with 3 replicas
- **Security First** - OWASP checks, Docker Scout, SonarQube analysis
- **Health Monitoring** - Built-in health and metrics endpoints

## 📋 Prerequisites

- Node.js 18+
- Docker
- Kubernetes cluster (or minikube for local)
- Jenkins (for CI/CD)
- TMDB API Key ([Get one here](https://www.themoviedb.org/settings/api))

## 🛠️ Setup

### Local Development

1. Clone the repository:
```bash
git clone https://github.com/arseneaki/Hotstar.git
cd Hotstar
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file:
```bash
cp .env.example .env
# Edit .env and add your TMDB API key:
# REACT_APP_TMDB_API_KEY=your_api_key_here
```

4. Start development server:
```bash
npm start
```

The application will be available at `http://localhost:3000`

### Production Build

```bash
# Build React application
npm run build

# Start production server
npm run server
```

### Docker

#### Build Image
```bash
docker build -t hotstar:latest .
```

#### Run Container
```bash
docker run -d \
  --name hotstar \
  -p 3000:3000 \
  -e REACT_APP_TMDB_API_KEY=your_api_key \
  hotstar:latest
```

#### Health Check
```bash
curl http://localhost:3000/health
```

### Kubernetes

#### 1. Create Secret
```bash
kubectl create secret generic hotstar-secrets \
  --from-literal=tmdb-api-key=YOUR_API_KEY \
  -n default
```

#### 2. Deploy Application
```bash
kubectl apply -f K8S/
```

#### 3. Check Deployment
```bash
kubectl get pods -n default
kubectl get svc -n default
kubectl get deployment -n default
```

#### 4. Access Application
```bash
# Get service URL
kubectl get svc hotstar-service -n default

# Or port-forward for local access
kubectl port-forward svc/hotstar-service 3000:80 -n default
```

## 🔒 Security

### Security Features

- **API Keys** - Stored in Kubernetes Secrets, never in code
- **Non-root Containers** - All containers run as non-root user
- **Security Contexts** - Pod and container security contexts configured
- **Dependency Scanning** - OWASP Dependency Check in CI/CD
- **Image Scanning** - Docker Scout for vulnerability scanning
- **Code Quality** - SonarQube analysis and quality gates
- **Helmet.js** - Security headers middleware

### Security Best Practices

1. **Never commit API keys** - Use environment variables or secrets
2. **Regular updates** - Keep dependencies updated
3. **Scan images** - Use Docker Scout before deployment
4. **Monitor** - Check health and metrics endpoints regularly

## 📊 Monitoring

### Health Endpoint
```bash
curl http://localhost:3000/health
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "uptime": 12345,
  "environment": "production",
  "version": "1.0.0"
}
```

### Metrics Endpoint
```bash
curl http://localhost:3000/metrics
```

## 🏗️ Architecture

### CI/CD Pipeline

1. **Clean Workspace** - Remove previous build artifacts
2. **Checkout** - Get latest code from Git
3. **Install Dependencies** - Install npm packages
4. **Lint Code** - Code quality checks
5. **Run Tests** - Execute test suite with coverage
6. **SonarQube Analysis** - Code quality and security analysis
7. **Quality Gate** - Enforce quality standards
8. **Build Application** - Create production build
9. **OWASP Dependency Check** - Scan for vulnerabilities
10. **Docker Scout FS** - Scan filesystem for issues
11. **Docker Build & Push** - Build and push container image
12. **Docker Scout Image** - Scan container image
13. **Deploy Docker** - Deploy to Docker host
14. **Deploy Kubernetes** - Deploy to K8s cluster
15. **Smoke Tests** - Verify deployment

### Kubernetes Architecture

- **Deployment** - 3 replicas for high availability
- **Service** - LoadBalancer type for external access
- **Secrets** - Secure storage for API keys
- **Service Account** - Pod security identity
- **Health Probes** - Liveness, readiness, and startup probes
- **Resource Limits** - CPU and memory constraints
- **Security Contexts** - Non-root, read-only filesystem where possible

## 📁 Project Structure

```
Hotstar/
├── src/                    # React source code
│   ├── components/         # React components
│   ├── App.js             # Main app component
│   └── ...
├── K8S/                    # Kubernetes manifests
│   ├── deployment.yml     # Deployment configuration
│   ├── service.yml        # Service configuration
│   ├── secret.yml         # Secrets template
│   └── serviceaccount.yml # Service account
├── EKS_TERRAFORM/          # Terraform for EKS
├── public/                 # Static files
├── Dockerfile             # Multi-stage Docker build
├── Jenkinsfile            # CI/CD pipeline
├── server.js              # Express server for production
├── package.json           # Dependencies and scripts
└── README.md              # This file
```

## 🧪 Testing

```bash
# Run tests
npm test

# Run tests with coverage
npm test -- --coverage

# Run linter
npm run lint

# Fix linting issues
npm run lint:fix
```

## 📝 Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `REACT_APP_TMDB_API_KEY` | TMDB API key | Yes |
| `REACT_APP_TMDB_BASE_URL` | TMDB API base URL | No (default: https://api.themoviedb.org/3) |
| `PORT` | Server port | No (default: 3000) |
| `NODE_ENV` | Environment mode | No (default: production) |

## 🔧 Scripts

| Script | Description |
|--------|-------------|
| `npm start` | Start development server |
| `npm run build` | Build production bundle |
| `npm test` | Run tests with coverage |
| `npm run lint` | Run ESLint |
| `npm run server` | Start production server |
| `npm run start:prod` | Start production server with NODE_ENV=production |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Ensure all tests pass (`npm test`)
5. Run linter (`npm run lint`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## 📄 License

MIT License - see LICENSE file for details

## 🔗 Links

- **Blog Post**: [DevSecOps CI/CD - Deploying a Secure Hotstar Clone](https://mrcloudbook.com/devsecops-ci-cd-deploying-a-secure-hotstar-clone-even-if-youre-not-a-pro/)
- **TMDB API**: [The Movie Database API](https://www.themoviedb.org/documentation/api)

## 📞 Support

For issues and questions, please open an issue on GitHub.

---

**Built with ❤️ using React, Docker, Kubernetes, and Jenkins**
