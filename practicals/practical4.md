# Practical 4: Setting up SAST (Static Application Security Testing) with Snyk in GitHub Actions

## Table of Contents

1. [Introduction to SAST and Snyk](#introduction)
2. [Prerequisites](#prerequisites)
3. [Understanding the Current Project](#understanding-project)
4. [Setting up Snyk Account](#setting-up-snyk)
5. [Configuring GitHub Secrets](#configuring-secrets)
6. [Integrating Snyk with GitHub Actions](#integrating-snyk)
7. [Advanced Snyk Configuration](#advanced-configuration)
8. [Interpreting Snyk Results](#interpreting-results)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)
11. [Hands-on Exercises](#exercises)

## 1. Introduction to SAST and Snyk {#introduction}

### What is SAST?

Static Application Security Testing (SAST) is a method of computer program debugging that analyzes source code to find security vulnerabilities before the software is deployed. Unlike Dynamic Application Security Testing (DAST), SAST examines code without executing it.

### What is Snyk?

Snyk is a developer-first security platform that helps you find and fix vulnerabilities in your code, dependencies, containers, and infrastructure as code. It provides:

- **Vulnerability scanning** for open source dependencies
- **License compliance** checking
- **Container security** scanning
- **Infrastructure as Code** security
- **Code security** (SAST) analysis

### Why Use Snyk with GitHub Actions?

- **Automated Security**: Runs security checks on every commit/PR
- **Early Detection**: Finds vulnerabilities before they reach production
- **Developer-Friendly**: Integrates seamlessly into existing workflows
- **Continuous Monitoring**: Monitors for new vulnerabilities in existing dependencies

## 2. Prerequisites {#prerequisites}

Before starting this practical, ensure you have:

- [ ] A GitHub account with repository access
- [ ] Basic understanding of Git and GitHub
- [ ] Familiarity with Java and Maven
- [ ] Understanding of CI/CD concepts
- [ ] Access to the `cicd-demo` repository

### Getting Started: Clone the Repository

Before proceeding with this practical, you need to clone the `cicd-demo` repository to your local machine.

#### Option 1: Clone the Original Repository (Read-only)

```bash
# Clone the repository
git clone https://github.com/douglasswmcst/cicd-demo.git

# Navigate to the project directory
cd cicd-demo

# Verify the project structure
ls -la
```

1. **Verify Your Environment**:

   ```bash
   # Check Java version (should be 17 or higher)
   java -version

   # Check Maven installation
   mvn -version

   # Test the project builds successfully
   mvn clean compile

   # Run the tests to ensure everything works
   mvn test
   ```

#### Project Setup Verification

Once cloned, verify your setup by running:

```bash
# Ensure you're in the project directory
pwd
# Output should end with: /cicd-demo

# Check project structure
tree -L 3
# Or if tree is not available:
find . -type f -name "*.java" -o -name "*.xml" -o -name "*.yml" | head -10

# Start the application locally (optional)
mvn spring-boot:run
# Application should start on http://localhost:8080
# Test with: curl http://localhost:8080/
```

#### Important Notes

- **For Workshop Participants**: Your instructor may provide a specific fork or branch to use
- **Repository Access**: Ensure you have the necessary permissions to create secrets and run GitHub Actions
- **Network Requirements**: Make sure you can access GitHub Actions and external package repositories

### Project Overview

Our demo project is a Spring Boot application with:

- **Framework**: Spring Boot 3.1.2
- **Java Version**: 17
- **Build Tool**: Maven
- **Dependencies**:
  - Spring Web
  - JavaFaker (for generating random data)
  - JaCoCo (for code coverage)

## 3. Understanding the Current Project {#understanding-project}

### Project Structure

```
cicd-demo/
├── .github/
│   └── workflows/
│       └── maven.yml          # GitHub Actions workflow
├── src/
│   ├── main/java/
│   │   └── sg/edu/nus/iss/cicddemo/
│   │       ├── CicdDemoApplication.java
│   │       └── Controller/
│   │           └── DataController.java
│   └── test/java/
├── pom.xml                    # Maven configuration
├── dockerfile                # Docker configuration
└── README.md
```

### Current GitHub Actions Workflow

The existing `maven.yml` already includes a basic Snyk integration:

```yaml
name: Java CI with Maven

on:
  push:
    branches: ["master"]
  pull_request:
    branches: ["master"]

jobs:
  test:
    name: build and test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: "17"
          distribution: "temurin"
          cache: maven
      - name: Perform the Unit Test Cases
        run: mvn -B test

  security:
    needs: test
    name: SA scan using snyk
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@master
      - name: Run Snyk to check for vulnerabilities
        uses: snyk/actions/maven@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

## 4. Setting up Snyk Account {#setting-up-snyk}

### Step 4.1: Create a Snyk Account

1. **Visit Snyk Website**: Go to [https://snyk.io](https://snyk.io)
2. **Sign Up**: Click "Sign up for free"
3. **Choose Authentication**:
   - Recommended: Sign up with your GitHub account for easier integration
   - Alternative: Use email/password

### Step 4.2: Connect Your GitHub Account

1. **Navigate to Integrations**: In Snyk dashboard, go to "Integrations"
2. **Add GitHub Integration**: Click on "GitHub" integration
3. **Authorize Access**: Allow Snyk to access your repositories
4. **Import Repositories**: Select the repositories you want to monitor

### Step 4.3: Get Your Snyk Token

1. **Access Account Settings**: Click on your profile → "Account settings"
2. **Navigate to API Token**: Go to "Auth Token" section
3. **Generate Token**: Click "Show" to reveal your API token
4. **Copy Token**: Copy the token for later use in GitHub Secrets

⚠️ **Security Note**: Keep your API token secure and never commit it to version control!

## 5. Configuring GitHub Secrets {#configuring-secrets}

### Step 5.1: Navigate to Repository Secrets

1. **Open Your Repository**: Go to your `cicd-demo` repository on GitHub
2. **Access Settings**: Click on "Settings" tab
3. **Navigate to Secrets**: Go to "Secrets and variables" → "Actions"

### Step 5.2: Add Snyk Token

1. **Create New Secret**: Click "New repository secret"
2. **Add Secret Details**:
   - **Name**: `SNYK_TOKEN`
   - **Value**: Paste your Snyk API token
3. **Save Secret**: Click "Add secret"

### Step 5.3: Verify Secret Configuration

- The secret should now appear in your repository secrets list
- It will show as `SNYK_TOKEN` with a green checkmark
- The value will be hidden for security

## 6. Integrating Snyk with GitHub Actions {#integrating-snyk}

### Step 6.1: Basic Snyk Integration (Already Configured)

The current workflow already includes basic Snyk scanning. Let's understand each part:

```yaml
security:
  needs: test # Runs after test job completes
  name: SA scan using snyk # Job name
  runs-on: ubuntu-latest # Ubuntu runner
  steps:
    - uses: actions/checkout@master # Checkout code
    - name: Run Snyk to check for vulnerabilities
      uses: snyk/actions/maven@master # Use Snyk Maven action
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }} # Access secret token
```

### Step 6.2: Enhanced Snyk Configuration

Let's create an enhanced version with more features:

```yaml
security:
  needs: test
  name: Security Analysis with Snyk
  runs-on: ubuntu-latest

  steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        java-version: "17"
        distribution: "temurin"
        cache: maven

    - name: Build project for Snyk analysis
      run: mvn clean compile

    - name: Run Snyk to check for vulnerabilities
      uses: snyk/actions/maven@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      with:
        args: --severity-threshold=high --fail-on=upgradable

    - name: Upload Snyk results to GitHub Code Scanning
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: snyk.sarif

    - name: Monitor dependencies with Snyk
      uses: snyk/actions/maven@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      with:
        command: monitor
```

### Step 6.3: Understanding Snyk Action Parameters

| Parameter                    | Description                             | Example                             |
| ---------------------------- | --------------------------------------- | ----------------------------------- |
| `--severity-threshold`       | Minimum severity to report              | `low`, `medium`, `high`, `critical` |
| `--fail-on`                  | Conditions to fail the build            | `all`, `upgradable`, `patchable`    |
| `--file`                     | Specific file to scan                   | `pom.xml`                           |
| `--exclude-base-image-vulns` | Exclude base image vulnerabilities      | (for container scans)               |
| `--json`                     | Output results in JSON format           |                                     |
| `--sarif`                    | Output SARIF format for GitHub Security |                                     |

## 7. Advanced Snyk Configuration {#advanced-configuration}

### Step 7.1: Creating a Snyk Configuration File

Create a `.snyk` file in your repository root for custom configurations:

```yaml
# .snyk file
version: v1.0.0

# Ignore specific vulnerabilities
ignore:
  "SNYK-JAVA-ORGAPACHECOMMONS-1234567":
    - "*":
        reason: "False positive - not exploitable in our context"
        expires: "2024-12-31T23:59:59.999Z"

# Patch configuration
patches: {}

# Language settings
language-settings:
  java:
    # Java-specific settings
```

### Step 7.2: Multiple Scan Types

```yaml
security:
  needs: test
  name: Comprehensive Security Scan
  runs-on: ubuntu-latest

  strategy:
    matrix:
      scan-type: [dependencies, code, container]

  steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        java-version: "17"
        distribution: "temurin"

    - name: Dependency Scan
      if: matrix.scan-type == 'dependencies'
      uses: snyk/actions/maven@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      with:
        args: --severity-threshold=medium

    - name: Code Scan
      if: matrix.scan-type == 'code'
      uses: snyk/actions/maven@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      with:
        command: code test

    - name: Container Scan
      if: matrix.scan-type == 'container'
      uses: snyk/actions/docker@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      with:
        image: "your-app:latest"
```

### Step 7.3: Conditional Scanning

```yaml
# Only run Snyk on specific conditions
- name: Run Snyk Security Scan
  uses: snyk/actions/maven@master
  if: github.event_name == 'pull_request' || github.ref == 'refs/heads/master'
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

## 8. Interpreting Snyk Results {#interpreting-results}

### Step 8.1: Understanding Vulnerability Reports

Snyk reports include:

1. **Vulnerability Details**:

   - CVE identifier
   - Severity level (Low, Medium, High, Critical)
   - CVSS score
   - Description of the vulnerability

2. **Path Information**:

   - Direct or transitive dependency
   - Dependency tree path
   - Affected versions

3. **Remediation Advice**:
   - Upgrade recommendations
   - Patch availability
   - Workaround suggestions

### Step 8.2: Sample Vulnerability Report

```
✗ High severity vulnerability found in org.springframework:spring-core
  Description: Improper Input Validation
  Info: https://snyk.io/vuln/SNYK-JAVA-ORGSPRINGFRAMEWORK-1234567
  Introduced through: org.springframework.boot:spring-boot-starter-web@3.1.2
  From: org.springframework.boot:spring-boot-starter-web@3.1.2 >
        org.springframework:spring-web@6.0.11 >
        org.springframework:spring-core@6.0.11

  Remediation:
  ✓ Upgrade org.springframework.boot:spring-boot-starter-web to 3.1.3 or higher
```

### Step 8.3: Analyzing GitHub Security Tab

After running Snyk with SARIF upload:

1. **Navigate to Security Tab**: In your repository
2. **View Code Scanning**: See detected vulnerabilities
3. **Review Details**: Click on specific alerts for detailed information
4. **Track Progress**: Monitor remediation efforts

## 9. Best Practices {#best-practices}

### Security Best Practices

1. **Regular Scanning**:

   ```yaml
   # Schedule regular scans
   on:
     schedule:
       - cron: "0 2 * * 1" # Run every Monday at 2 AM
   ```

2. **Fail Fast Strategy**:

   ```yaml
   # Fail build on high severity vulnerabilities
   with:
     args: --severity-threshold=high --fail-on=all
   ```

3. **Monitor Production Dependencies**:
   ```yaml
   # Monitor deployed applications
   - name: Monitor production dependencies
     uses: snyk/actions/maven@master
     env:
       SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
     with:
       command: monitor
       args: --project-name=cicd-demo-prod
   ```

### Workflow Optimization

1. **Parallel Execution**:

   ```yaml
   jobs:
     test:
       # Test job
     security:
       # Run in parallel with tests for faster feedback
       runs-on: ubuntu-latest
   ```

2. **Caching Dependencies**:

   ```yaml
   - name: Cache Maven dependencies
     uses: actions/cache@v3
     with:
       path: ~/.m2
       key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
   ```

3. **Conditional Scans**:

   ```yaml
   # Skip scans on documentation-only changes
   - name: Check for code changes
     uses: dorny/paths-filter@v2
     id: changes
     with:
       filters: |
         code:
           - 'src/**'
           - 'pom.xml'

   - name: Run Snyk scan
     if: steps.changes.outputs.code == 'true'
     # ... scan configuration
   ```

## 10. Troubleshooting {#troubleshooting}

### Common Issues and Solutions

#### Issue 1: "SNYK_TOKEN is not set"

**Problem**: Missing or incorrectly configured Snyk token
**Solution**:

1. Verify token exists in GitHub Secrets
2. Check token name matches exactly: `SNYK_TOKEN`
3. Ensure token is valid and not expired

#### Issue 2: "Unable to authenticate with Snyk"

**Problem**: Invalid or expired Snyk token
**Solution**:

1. Generate new token from Snyk dashboard
2. Update GitHub Secret with new token
3. Re-run the workflow

#### Issue 3: "No supported manifests found"

**Problem**: Snyk cannot find supported package manager files
**Solution**:

1. Ensure `pom.xml` is in repository root
2. Verify Maven dependencies are properly defined
3. Check file permissions and accessibility

#### Issue 4: "Build fails due to vulnerabilities"

**Problem**: Snyk fails the build due to detected vulnerabilities
**Solution**:

1. Review vulnerability details
2. Update dependencies to secure versions
3. Adjust severity threshold if appropriate:
   ```yaml
   with:
     args: --severity-threshold=critical
   ```

#### Issue 5: "Scan takes too long"

**Problem**: Snyk scan timeout or slow performance
**Solution**:

1. Use dependency caching
2. Scan only changed files when possible
3. Split scans across multiple jobs

### Debug Mode

Enable debug logging for troubleshooting:

```yaml
- name: Debug Snyk scan
  uses: snyk/actions/maven@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
    DEBUG: "snyk"
  with:
    args: --debug
```

## 11. Hands-on Exercises {#exercises}

### Exercise 1: Basic Setup (15 minutes)

**Objective**: Set up basic Snyk scanning for the project

**Tasks**:

1. Create a Snyk account
2. Generate API token
3. Add token to GitHub Secrets
4. Verify the existing workflow runs successfully

**Expected Outcome**: Security job completes successfully in GitHub Actions

**Verification Steps**:

1. Go to Actions tab in your repository
2. Trigger a new workflow run
3. Verify "SA scan using snyk" job passes
4. Check for any vulnerabilities reported

### Exercise 2: Enhanced Configuration (20 minutes)

**Objective**: Improve the Snyk configuration with additional features

**Tasks**:

1. Modify the workflow to include severity thresholds
2. Add SARIF upload for GitHub Security integration
3. Configure monitoring for deployed dependencies
4. Test the enhanced workflow

**Code to Implement**:

```yaml
security:
  needs: test
  name: Enhanced Security Analysis
  runs-on: ubuntu-latest

  steps:
    - uses: actions/checkout@v4

    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        java-version: "17"
        distribution: "temurin"
        cache: maven

    - name: Run comprehensive Snyk scan
      uses: snyk/actions/maven@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      with:
        args: --severity-threshold=medium --sarif-file-output=snyk.sarif

    - name: Upload results to GitHub Security
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: snyk.sarif
```

**Expected Outcome**:

- Enhanced security scanning with results in GitHub Security tab
- Configurable severity thresholds

### Exercise 3: Vulnerability Management (25 minutes)

**Objective**: Handle and manage detected vulnerabilities

**Tasks**:

1. Intentionally introduce a vulnerable dependency
2. Run Snyk scan to detect the vulnerability
3. Create a `.snyk` file to ignore specific vulnerabilities
4. Update dependencies to fix vulnerabilities

**Steps**:

1. **Add vulnerable dependency** to `pom.xml`:

   ```xml
   <dependency>
       <groupId>com.fasterxml.jackson.core</groupId>
       <artifactId>jackson-databind</artifactId>
       <version>2.9.8</version> <!-- Intentionally old version -->
   </dependency>
   ```

2. **Run Snyk scan** and observe vulnerabilities

3. **Create `.snyk` file** to ignore non-critical issues:

   ```yaml
   version: v1.0.0
   ignore:
     "SNYK-JAVA-COMFASTERXMLJACKSONCORE-1234567":
       - "*":
           reason: "Acceptable risk - not exploitable in our context"
           expires: "2024-12-31T23:59:59.999Z"
   ```

4. **Update dependency** to latest secure version:
   ```xml
   <dependency>
       <groupId>com.fasterxml.jackson.core</groupId>
       <artifactId>jackson-databind</artifactId>
       <version>2.15.2</version>
   </dependency>
   ```

**Expected Outcome**:

- Understanding of vulnerability detection and management
- Experience with Snyk ignore policies
- Successful vulnerability remediation

### Exercise 4: Advanced Scanning (30 minutes)

**Objective**: Implement comprehensive security scanning strategy

**Tasks**:

1. Set up matrix strategy for different scan types
2. Configure scheduled scans
3. Implement conditional scanning based on file changes
4. Add notification mechanisms for security issues

**Advanced Workflow Configuration**:

```yaml
name: Comprehensive Security Pipeline

on:
  push:
    branches: ["master"]
  pull_request:
    branches: ["master"]
  schedule:
    - cron: "0 2 * * 1" # Weekly scan on Monday 2 AM

jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      code: ${{ steps.changes.outputs.code }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v2
        id: changes
        with:
          filters: |
            code:
              - 'src/**'
              - 'pom.xml'
              - 'dockerfile'

  security-scan:
    needs: changes
    if: needs.changes.outputs.code == 'true' || github.event_name == 'schedule'
    runs-on: ubuntu-latest

    strategy:
      matrix:
        scan-type: [dependencies, code]

    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: "17"
          distribution: "temurin"
          cache: maven

      - name: Dependency Vulnerability Scan
        if: matrix.scan-type == 'dependencies'
        uses: snyk/actions/maven@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=medium --sarif-file-output=snyk-deps.sarif

      - name: Code Security Scan
        if: matrix.scan-type == 'code'
        uses: snyk/actions/maven@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          command: code test
          args: --sarif-file-output=snyk-code.sarif

      - name: Upload SARIF results
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: snyk-${{ matrix.scan-type }}.sarif
          category: snyk-${{ matrix.scan-type }}
```

**Expected Outcome**:

- Automated security scanning on code changes
- Regular scheduled security reviews
- Multiple scan types running in parallel
- Integrated security results in GitHub

### Exercise 5: Security Dashboard and Reporting (20 minutes)

**Objective**: Create comprehensive security reporting and monitoring

**Tasks**:

1. Set up Snyk monitoring for the project
2. Configure GitHub Security advisories
3. Create security metrics dashboard
4. Set up notifications for critical vulnerabilities

**Implementation**:

1. **Add monitoring step**:

   ```yaml
   - name: Monitor project in Snyk
     uses: snyk/actions/maven@master
     env:
       SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
     with:
       command: monitor
       args: --project-name=${{ github.repository }}
   ```

2. **Create security badge** for README:

   ```markdown
   ![Snyk Vulnerabilities](https://img.shields.io/snyk/vulnerabilities/github/yourusername/cicd-demo)
   ```

3. **Configure notification workflow**:
   ```yaml
   - name: Notify on critical vulnerabilities
     if: failure()
     uses: 8398a7/action-slack@v3
     with:
       status: failure
       text: "Critical security vulnerabilities detected in ${{ github.repository }}"
     env:
       SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
   ```

**Expected Outcome**:

- Continuous monitoring of security posture
- Automated notifications for security issues
- Security metrics integration

## Conclusion

In this practical, you've learned how to:

1. ✅ Set up Snyk account and integrate with GitHub
2. ✅ Configure GitHub Actions for automated security scanning
3. ✅ Understand and interpret vulnerability reports
4. ✅ Implement advanced scanning strategies
5. ✅ Handle vulnerability management and remediation
6. ✅ Set up monitoring and alerting for security issues

### Key Takeaways

- **Security First**: Integrate security scanning early in development cycle
- **Automation**: Automate security checks to ensure consistency
- **Continuous Monitoring**: Regularly monitor for new vulnerabilities
- **Risk Management**: Use ignore policies judiciously for acceptable risks
- **Team Collaboration**: Make security everyone's responsibility

### Next Steps

1. **Explore Snyk CLI**: Learn to use Snyk locally for development
2. **Container Security**: Extend scanning to Docker images
3. **Infrastructure as Code**: Scan Terraform/CloudFormation templates
4. **Security Policies**: Implement organization-wide security policies
5. **Training**: Regular security awareness training for development team

### Additional Resources

- [Snyk Documentation](https://docs.snyk.io/)
- [GitHub Actions Security Guide](https://docs.github.com/en/actions/security-guides)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Snyk Blog](https://snyk.io/blog/)
- [GitHub Security Lab](https://securitylab.github.com/)

---

**Happy Secure Coding! 🔒**

_This practical is part of the NUS-ISS EPAT CI/CD Workshop series._
