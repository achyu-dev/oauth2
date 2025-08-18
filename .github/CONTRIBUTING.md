# Contributing to PESU OAuth2

Thank you for your interest in contributing to the PESU OAuth2 provider! This document provides guidelines and instructions for setting up your development environment and contributing to the project.

Table of Contents:

- [Getting Started](#getting-started)
- [🛠️ Development Environment Setup](#🛠️-development-environment-setup)
- [🧰 Running the Application](#🧰-running-the-application)
- [🚀 Submitting Changes](#🚀-submitting-changes)
- [❓ Need Help?](#❓-need-help)
- [🔐 Security](#🔐-security)
- [✨ Code Style Guide](#✨-code-style-guide)
- [🏷️ GitHub Labels](#🏷️-github-labels)
- [🧩 Feature Suggestions](#🧩-feature-suggestions)
- [📄 License](#📄-license)

## Getting Started

### Development Workflow

The standard workflow for contributing is as follows:

1. Clone the repository to your local machine, or fork it and then clone your fork.
2. Install git hooks by running the following command:

```bash
pnpm hooks:install
```

3. Create a new branch with the format `(discord-username)/feature-description` for your feature or bug fix.
4. Make your changes and commit them with clear, descriptive messages.
5. Push your branch to the repository (or your fork).
6. Create a Pull Request (PR) against the repository's `dev` branch (not `main`).
7. Follow the PR template when creating your pull request.
8. Wait for review and feedback from the maintainers, address any comments or suggestions.
9. Once approved, your changes will be merged into the `dev` branch.

⚠️ **Important**: Direct PRs to `main` will be closed. All contributions must target the `dev` branch.

## 🛠️ Development Environment Setup

This section provides instructions for setting up your development environment to work on the PESU OAuth2 project.

### Prerequisites

- Node.js (v20 or higher)
- Git
- MongoDB (local instance or cloud service like MongoDB Atlas)
- pnpm package manager (recommended)

### Setting Up Your Environment

1. Clone the repository (or your fork) and navigate to the project:

```bash
# Option 1: Clone the main repository
git clone https://github.com/pesu-dev/oauth2.git
cd oauth2

# Option 2: Clone your fork
git clone https://github.com/your-github-username/oauth2.git
cd oauth2
```

2. Install dependencies:

```bash
pnpm install
# or
npm install
# or
yarn install
# or
bun install
```

### Set Up Environment Variables

1. Create a `.env` file in the root directory:

```bash
cp .env.example .env
```

2. Configure your environment variables:
   Open the `.env` file and add the following variables:

```env
# Database
MONGODB_URL=mongodb://localhost:27017/pesu-oauth2

# Encryption key for user credentials (AES-256, exactly 32 characters)
ENCRYPTION_KEY=your-32-character-encryption-key-here

# PESU Auth Integration
PESU_AUTH_URL=https://pesu-auth.onrender.com/authenticate

# Your OAuth2 server base URL
OAUTH_BASE_URL=http://localhost:3000

# Admin Panel Configuration
ADMIN_SESSION_TIMEOUT=86400000
```

Replace the placeholder values with your actual credentials:

- `MONGODB_URL`: Your MongoDB connection string
- `ENCRYPTION_KEY`: A 32-character string for AES-256 encryption
- `PESU_AUTH_URL`: URL for PESU authentication API
- `OAUTH_BASE_URL`: Base URL for your OAuth2 server (use `http://localhost:3000` for development)
- `ADMIN_SESSION_TIMEOUT`: Session timeout in milliseconds (default: 24 hours)

### Database Setup

The app uses MongoDB with Prisma ORM to store OAuth2 applications, users, and tokens.

Ensure you have:

1. A MongoDB instance running (local or cloud)
2. Proper connection string in your `.env` file
3. Appropriate database permissions for read/write operations

After setting up your environment variables, run the following to set up your database:

```bash
pnpm prisma generate
pnpm prisma db push
```

## 🧰 Running the Application

To run the app locally for development:

```bash
pnpm dev
# or
npm run dev
# or
yarn dev
# or
bun dev
```

The app will start and be available at [http://localhost:3000](http://localhost:3000/).

**Note**: Make sure you have set up your MongoDB instance and environment variables for development testing.

## 🚀 Submitting Changes

### 🔀 Create a Branch

Start by creating a new branch following the naming convention:

```bash
git checkout -b your-discord-username/feature-description
```

Replace `your-discord-username` with your actual Discord username and `feature-description` with a brief description of what you're working on.

### ✏️ Make and Commit Changes

After making your changes, commit them with clear messages:

```bash
git add required-files-only
git commit -m "Add OAuth2 refresh token endpoint functionality"
```

Use descriptive commit messages that explain what the change does.

### 📤 Push and Open a Pull Request

1. Push your branch to the repository (or your fork):

```bash
git push origin your-discord-username/feature-description
```

2. Open a Pull Request on GitHub targeting the `dev` branch.
3. Follow the PR template when creating your pull request.

## ❓ Need Help?

If you get stuck or have questions:

1. Check the [README.md](../README.md) for setup and usage info.
2. Review the [project board](https://github.com/orgs/pesu-dev/projects/4) to see current work and track progress.
3. Reach out to the maintainers on PESU Discord.
   - Use the appropriate development channels for questions.
   - Search for existing discussions before posting.
4. Open a new issue if you're facing something new or need clarification.

## 🔐 Security

If you discover a security vulnerability, please do not open a public issue.

Instead, report it privately by contacting the maintainers. We take all security concerns seriously and will respond promptly.

**Important**: Never commit sensitive information like encryption keys, database credentials, or API keys to the repository.

## ✨ Code Style Guide

To keep the codebase clean and maintainable, please follow these conventions:

### ✅ General Guidelines

- Write clean, readable code with meaningful variable and function names
- Use modern TypeScript with proper type definitions
- Keep functions focused and modular
- Follow the project's style guidelines (ESLint configuration)
- Use async/await for all asynchronous operations
- Follow OAuth2 RFC 6749 standards for authentication flows

### TypeScript Specific

- Use proper TypeScript types and interfaces
- Avoid `any` types when possible
- Use Zod for request validation
- Follow Next.js App Router conventions

### Database

- Use Prisma ORM for database operations
- Follow the established schema patterns
- Use proper error handling for database operations

## 🏷️ GitHub Labels

We use GitHub labels to categorize issues and PRs. Here's a quick guide to what they mean:

| Label              | Description                                     |
| ------------------ | ----------------------------------------------- |
| `good first issue` | Beginner-friendly, simple issues to get started |
| `bug`              | Something is broken or not working as intended  |
| `enhancement`      | Proposed improvements or new features           |
| `documentation`    | Docs, comments, or README-related updates       |
| `security`         | Security-related issues or improvements         |
| `question`         | Open questions or clarifications                |
| `help wanted`      | Maintainers are seeking help or collaboration   |

When creating or working on an issue/PR, feel free to suggest an appropriate label if not already applied.

## 🧩 Feature Suggestions

If you want to propose a new feature:

1. Check if it already exists on the [project board](https://github.com/orgs/pesu-dev/projects/4)
2. Open a new issue with a clear description
3. Explain the use case and how it benefits the PESU ecosystem
4. Consider OAuth2 compliance and security implications
5. Ensure it aligns with RFC 6749 standards when applicable

## 📄 License

By contributing to this repository, you agree that your contributions will be licensed under the same license as the project. See [LICENSE](../LICENSE) for full license text.
