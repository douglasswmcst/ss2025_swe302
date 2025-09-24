# Practical 4a: Setting up SAST with SonarCloud in GitHub Actions

## Table of Contents

1. [Introduction to SAST and SonarCloud](#introduction)
2. [Prerequisites](#prerequisites)
3. [Understanding SonarCloud vs Snyk](#comparison)
4. [Setting up SonarCloud Account](#setting-up-sonarcloud)
5. [Configuring GitHub Integration](#configuring-github)
6. [Integrating SonarCloud with GitHub Actions](#integrating-sonarcloud)
7. [Understanding SonarCloud Security Reports](#security-reports)
8. [Continuous Monitoring and Quality Gates](#monitoring)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)
11. [Hands-on Exercises](#exercises)

## 1. Introduction to SAST and SonarCloud {#introduction}

### What is SAST?

Static Application Security Testing (SAST) analyzes source code to identify security vulnerabilities before deployment. SAST tools examine code structure, data flow, and potential security weaknesses without executing the program.

### What is SonarCloud?

SonarCloud is a cloud-based code quality and security analysis platform that provides:

- **Security Vulnerability Detection**: Identifies security hotspots and vulnerabilities
- **Code Quality Analysis**: Detects bugs, code smells, and maintainability issues
- **Technical Debt Measurement**: Quantifies the effort needed to fix issues
- **Quality Gates**: Automated pass/fail criteria for code quality
- **Continuous Monitoring**: Tracks code quality trends over time

### SonarCloud vs Snyk

While both are SAST tools, they have different focuses:

| Feature | SonarCloud | Snyk |
|---------|------------|------|
| **Primary Focus** | Code quality + Security | Security vulnerabilities |
| **Dependency Scanning** | Limited | Extensive |
| **Code Analysis** | Comprehensive | Security-focused |
| **Quality Metrics** | Extensive | Minimal |
| **Language Support** | 25+ languages | Package managers |
| **Security Hotspots** | Yes | No |
| **Quality Gates** | Yes | Limited |

## 2. Prerequisites {#prerequisites}

Before starting this practical, ensure you have:

- [ ] A GitHub account with repository access
- [ ] Basic understanding of Git and GitHub
- [ ] Familiarity with Java and Maven
- [ ] Understanding of CI/CD concepts
- [ ] Access to the `cicd-demo` repository (from Practical 4)

### Getting Started: Repository Setup

If you haven't already cloned the repository from Practical 4. You may build on the same repo you have previosuly used for practical 4.

```bash
# Clone the repository
git clone https://github.com/douglasswmcst/cicd-demo.git

# Navigate to the project directory
cd cicd-demo

# Verify the project structure
ls -la
```

### Verify Your Environment

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

## 3. Understanding SonarCloud vs Snyk {#comparison}

### Complementary Approaches

SonarCloud and Snyk serve complementary purposes in a security pipeline:

**SonarCloud strengths:**
- Deep source code analysis
- Security hotspots identification
- Code quality metrics
- Technical debt tracking
- Multi-language support

**Snyk strengths:**
- Dependency vulnerability scanning
- Container security
- Real-time vulnerability database
- Automated fix suggestions
- License compliance

### When to Use Each

- **Use SonarCloud** for: Source code security analysis, quality gates, code review automation
- **Use Snyk** for: Dependency scanning, container security, infrastructure as code
- **Use Both** for: Comprehensive security coverage (recommended)

## 4. Setting up SonarCloud Account {#setting-up-sonarcloud}

### Step 4.1: Create a SonarCloud Account

1. **Visit SonarCloud Website**: Go to [https://sonarcloud.io](https://sonarcloud.io)
2. **Sign Up**: Click "Start now" or "Sign up for free"
3. **Choose Authentication**:
   - **Recommended**: Sign up with your GitHub account
   - This automatically links your repositories

### Step 4.2: Create an Organization

After logging in with GitHub:

1. **Import Organization**: SonarCloud will prompt you to import a GitHub organization
2. **Select Organization**: Choose your GitHub username or organization
3. **Install SonarCloud App**:
   - Click "Install SonarCloud"
   - Select repositories to analyze (choose `cicd-demo`)
   - Approve the installation

### Step 4.3: Create a Project

1. **Analyze New Project**: Click "Analyze new project"
2. **Select Repository**: Choose `cicd-demo` from the list
3. **Set Up Project**: Click "Set Up"
4. **Choose Analysis Method**: Select "With GitHub Actions"

### Step 4.4: Generate SonarCloud Token

1. **Access Account Settings**: Click on your profile → "My Account"
2. **Navigate to Security**: Go to "Security" tab
3. **Generate Token**:
   - Click "Generate Tokens"
   - Name: `cicd-demo-github-actions`
   - Type: Select "User Token"
   - Expiration: Choose appropriate duration (e.g., 90 days)
   - Click "Generate"
4. **Copy Token**: Copy the token immediately (you won't see it again)

⚠️ **Security Note**: Keep your token secure and never commit it to version control!

## 5. Configuring GitHub Integration {#configuring-github}

### Step 5.1: Add SonarCloud Token to GitHub Secrets

1. **Open Your Repository**: Go to `cicd-demo` repository on GitHub
2. **Access Settings**: Click on "Settings" tab
3. **Navigate to Secrets**: Go to "Secrets and variables" → "Actions"
4. **Create New Secret**: Click "New repository secret"
5. **Add Secret Details**:
   - **Name**: `SONAR_TOKEN`
   - **Value**: Paste your SonarCloud token
6. **Save Secret**: Click "Add secret"

### Step 5.2: Add SonarCloud Organization Key

You'll also need your SonarCloud organization key:

1. **Find Organization Key**: In SonarCloud, go to your organization → "Administration" → "Organization Key"
2. **Add Another Secret**:
   - **Name**: `SONAR_ORGANIZATION`
   - **Value**: Your organization key (usually your GitHub username)

### Step 5.3: Get Project Key

1. **Navigate to Project**: Go to your project in SonarCloud
2. **Find Project Key**: In project settings, locate the "Project Key"
3. **Note the Key**: You'll need this for the workflow configuration

## 6. Integrating SonarCloud with GitHub Actions {#integrating-sonarcloud}

### Step 6.1: Create SonarCloud Properties File

Create a `sonar-project.properties` file in your repository root:

```properties
# sonar-project.properties
sonar.projectKey=your-github-username_cicd-demo
sonar.organization=your-organization-key

# Metadata
sonar.projectName=CICD Demo
sonar.projectVersion=1.0

# Path to source code
sonar.sources=src/main/java
sonar.tests=src/test/java

# Java version
sonar.java.source=17
sonar.java.binaries=target/classes

# Encoding
sonar.sourceEncoding=UTF-8

# Coverage report path (if using JaCoCo)
sonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml

# Exclude test files from analysis
sonar.exclusions=**/*Test.java,**/test/**
```

**Important**: Replace `your-github-username` and `your-organization-key` with your actual values.

### Step 6.2: Update pom.xml for SonarCloud

Add the SonarCloud Maven plugin to your `pom.xml`:

```xml
<build>
    <plugins>
        <!-- Existing plugins... -->

        <!-- SonarCloud Scanner -->
        <plugin>
            <groupId>org.sonarsource.scanner.maven</groupId>
            <artifactId>sonar-maven-plugin</artifactId>
            <version>3.10.0.2594</version>
        </plugin>

        <!-- JaCoCo for Code Coverage -->
        <plugin>
            <groupId>org.jacoco</groupId>
            <artifactId>jacoco-maven-plugin</artifactId>
            <version>0.8.11</version>
            <executions>
                <execution>
                    <goals>
                        <goal>prepare-agent</goal>
                    </goals>
                </execution>
                <execution>
                    <id>report</id>
                    <phase>test</phase>
                    <goals>
                        <goal>report</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

### Step 6.3: Create SonarCloud GitHub Actions Workflow

Create or update `.github/workflows/sonarcloud.yml`:

```yaml
name: SonarCloud Security Analysis

on:
  push:
    branches:
      - master
      - main
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  sonarcloud:
    name: SonarCloud SAST Scan
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Shallow clones should be disabled for better analysis

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: maven

      - name: Build and run tests with coverage
        run: mvn clean verify

      - name: SonarCloud Scan
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}  # Needed for PR decoration
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        run: |
          mvn sonar:sonar \
            -Dsonar.projectKey=${{ secrets.SONAR_ORGANIZATION }}_cicd-demo \
            -Dsonar.organization=${{ secrets.SONAR_ORGANIZATION }} \
            -Dsonar.host.url=https://sonarcloud.io
```

### Step 6.4: Alternative: Integrate with Existing Workflow

If you want to add SonarCloud to your existing `maven.yml`:

```yaml
name: Java CI with Maven

on:
  push:
    branches: ["master"]
  pull_request:
    branches: ["master"]

jobs:
  test:
    name: Build and Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: "17"
          distribution: "temurin"
          cache: maven
      - name: Build and Test
        run: mvn clean verify

  sonarcloud:
    name: SonarCloud Security Scan
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: "17"
          distribution: "temurin"
          cache: maven

      - name: Cache SonarCloud packages
        uses: actions/cache@v3
        with:
          path: ~/.sonar/cache
          key: ${{ runner.os }}-sonar
          restore-keys: ${{ runner.os }}-sonar

      - name: Run SonarCloud analysis
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        run: |
          mvn sonar:sonar \
            -Dsonar.projectKey=${{ secrets.SONAR_ORGANIZATION }}_cicd-demo \
            -Dsonar.organization=${{ secrets.SONAR_ORGANIZATION }}
```

## 7. Understanding SonarCloud Security Reports {#security-reports}

### Step 7.1: Navigating the SonarCloud Dashboard

After your first scan completes:

1. **Access Dashboard**: Go to SonarCloud → Your Project
2. **Overview Tab**: Shows overall quality and security metrics
3. **Security Tab**: Focus on security-specific findings

### Step 7.2: Understanding Security Metrics

SonarCloud reports three types of security issues:

#### 1. Vulnerabilities
**Definition**: Known security flaws that attackers can exploit

**Severity Levels**:
- **Blocker**: Critical security issue, must fix immediately
- **Critical**: High-risk vulnerability
- **Major**: Medium-risk issue
- **Minor**: Low-risk issue

**Example**:
```
Vulnerability: SQL Injection
Severity: Critical
File: UserController.java:45
Issue: User input is concatenated directly into SQL query
Fix: Use prepared statements or parameterized queries
```

#### 2. Security Hotspots
**Definition**: Security-sensitive code that requires manual review

**Categories**:
- Authentication & Authorization
- Encryption & Cryptography
- Input Validation
- HTTP Security
- File Access
- SQL Queries

**Example**:
```
Security Hotspot: Weak Cryptography Algorithm
File: PasswordUtil.java:23
Review: Using MD5 for password hashing
Recommendation: Use bcrypt, scrypt, or Argon2 instead
```

#### 3. Code Smells (Security-Related)
**Definition**: Code patterns that may lead to security issues

**Example**:
```
Code Smell: Hard-coded credentials
File: DatabaseConfig.java:12
Issue: Database password is hard-coded
Fix: Use environment variables or secret management
```

### Step 7.3: Sample Security Report

```
Security Analysis Summary:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Vulnerabilities:     2 Critical, 3 Major
Security Hotspots:   5 (Review required)
Security Rating:     C

Critical Issues:
1. SQL Injection Risk (UserRepository.java:89)
   └─> Use parameterized queries instead of string concatenation

2. Path Traversal (FileController.java:45)
   └─> Validate and sanitize file paths before access

Security Hotspots to Review:
1. Weak Hash Algorithm (PasswordService.java:34)
   └─> Review: MD5 used for password hashing

2. Hard-coded Secret (ApiConfig.java:12)
   └─> Review: API key hard-coded in source
```

### Step 7.4: Security Rating

SonarCloud assigns a security rating (A-E):

- **A**: 0 vulnerabilities
- **B**: At least 1 minor vulnerability
- **C**: At least 1 major vulnerability
- **D**: At least 1 critical vulnerability
- **E**: At least 1 blocker vulnerability

## 8. Continuous Monitoring and Quality Gates {#monitoring}

### Step 8.1: Understanding Quality Gates

Quality Gates are pass/fail criteria for code quality. Default conditions include:

**Security-Focused Conditions**:
- No new vulnerabilities on new code
- Security rating = A on new code
- Security hotspots reviewed = 100%

### Step 8.2: Configuring a Custom Quality Gate

1. **Create Quality Gate**:
   - In SonarCloud: Organization → Quality Gates
   - Click "Create"
   - Name: "Security-First Gate"

2. **Add Conditions** (Security-focused):
   ```
   Conditions on New Code:
   ├─ Security Rating is worse than A → FAIL
   ├─ Vulnerabilities is greater than 0 → FAIL
   ├─ Security Hotspots Reviewed is less than 100% → FAIL
   └─ Security Review Rating is worse than A → FAIL

   Conditions on Overall Code:
   ├─ Security Rating is worse than C → FAIL
   └─ Vulnerabilities is greater than 5 → FAIL
   ```

3. **Apply to Project**:
   - Project Settings → Quality Gate
   - Select "Security-First Gate"

### Step 8.3: Quality Gate in GitHub Actions

Update your workflow to fail on quality gate failure:

```yaml
- name: Run SonarCloud analysis
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  run: |
    mvn sonar:sonar \
      -Dsonar.projectKey=${{ secrets.SONAR_ORGANIZATION }}_cicd-demo \
      -Dsonar.organization=${{ secrets.SONAR_ORGANIZATION }} \
      -Dsonar.qualitygate.wait=true
```

The `-Dsonar.qualitygate.wait=true` flag makes the build wait for quality gate status and fail if it doesn't pass.

### Step 8.4: Pull Request Decoration

SonarCloud automatically decorates pull requests with:
- Quality gate status
- New issues found
- Coverage changes
- Code analysis summary

**Enable PR Decoration**:
1. Organization Settings → General Settings
2. Enable "Decorate Pull Requests"
3. Grant GitHub App permissions

### Step 8.5: Monitoring Dashboard

Create a monitoring workflow for continuous analysis:

```yaml
name: SonarCloud Monitoring

on:
  schedule:
    - cron: '0 2 * * 1'  # Weekly on Monday at 2 AM
  workflow_dispatch:  # Allow manual trigger

jobs:
  scheduled-scan:
    name: Scheduled Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Build and analyze
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        run: |
          mvn clean verify sonar:sonar \
            -Dsonar.projectKey=${{ secrets.SONAR_ORGANIZATION }}_cicd-demo \
            -Dsonar.organization=${{ secrets.SONAR_ORGANIZATION }}

      - name: Check Quality Gate
        run: |
          # Fetch quality gate status
          STATUS=$(curl -s -u ${{ secrets.SONAR_TOKEN }}: \
            "https://sonarcloud.io/api/qualitygates/project_status?projectKey=${{ secrets.SONAR_ORGANIZATION }}_cicd-demo" \
            | jq -r '.projectStatus.status')

          echo "Quality Gate Status: $STATUS"

          if [ "$STATUS" != "OK" ]; then
            echo "Quality gate failed!"
            exit 1
          fi
```

## 9. Best Practices {#best-practices}

### Security Best Practices

1. **Regular Scanning**:
   ```yaml
   # Run on every push and PR
   on:
     push:
       branches: [master, main]
     pull_request:
       branches: [master, main]
     schedule:
       - cron: '0 0 * * 0'  # Weekly full scan
   ```

2. **Security-First Quality Gate**:
   - Zero tolerance for new vulnerabilities
   - All security hotspots must be reviewed
   - Security rating A for new code

3. **Branch Protection**:
   - Require SonarCloud check to pass
   - Settings → Branches → Add rule
   - Require status checks: "SonarCloud Code Analysis"

### Workflow Optimization

1. **Cache SonarCloud Packages**:
   ```yaml
   - name: Cache SonarCloud packages
     uses: actions/cache@v3
     with:
       path: ~/.sonar/cache
       key: ${{ runner.os }}-sonar
   ```

2. **Incremental Analysis**:
   ```yaml
   - uses: actions/checkout@v4
     with:
       fetch-depth: 0  # Full history for better analysis
   ```

3. **Parallel Execution**:
   ```yaml
   jobs:
     test:
       # Run tests
     sonarcloud:
       needs: test  # Run after tests pass
     snyk:
       needs: test  # Run in parallel with SonarCloud
   ```

### Security Configuration

1. **Exclude Sensitive Files**:
   ```properties
   # In sonar-project.properties
   sonar.exclusions=**/secrets/**,**/*.key,**/*.pem
   ```

2. **Focus on Security**:
   ```properties
   # Prioritize security rules
   sonar.issue.ignore.multicriteria=e1
   sonar.issue.ignore.multicriteria.e1.ruleKey=java:S*
   sonar.issue.ignore.multicriteria.e1.resourceKey=**/test/**
   ```

3. **Token Rotation**:
   - Rotate SonarCloud tokens every 90 days
   - Use GitHub Dependabot for secret scanning
   - Enable SonarCloud security features

## 10. Troubleshooting {#troubleshooting}

### Common Issues and Solutions

#### Issue 1: "Invalid token" or "Unauthorized"

**Problem**: SonarCloud cannot authenticate

**Solution**:
1. Verify token in GitHub Secrets matches SonarCloud
2. Check token hasn't expired
3. Regenerate token if necessary
4. Ensure secret name is exactly `SONAR_TOKEN`

#### Issue 2: "Project not found"

**Problem**: Project key mismatch

**Solution**:
1. Verify project key in `sonar-project.properties`
2. Check organization key is correct
3. Ensure format: `organization_repository-name`
4. Verify project exists in SonarCloud

#### Issue 3: "No coverage information"

**Problem**: Code coverage not appearing

**Solution**:
1. Ensure JaCoCo plugin is in `pom.xml`
2. Run `mvn clean verify` before SonarCloud scan
3. Check coverage report path in properties:
   ```properties
   sonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
   ```

#### Issue 4: "Analysis takes too long"

**Problem**: Scan timeout or slow execution

**Solution**:
1. Use incremental analysis (fetch-depth: 0)
2. Cache Maven and SonarCloud packages
3. Exclude unnecessary files
4. Consider splitting analysis jobs

#### Issue 5: "Quality Gate fails but no issues shown"

**Problem**: Quality gate conditions too strict

**Solution**:
1. Review quality gate conditions
2. Check "New Code" vs "Overall Code" metrics
3. Adjust thresholds if appropriate
4. Review security hotspots (may need manual review)

### Debug Mode

Enable debug logging for troubleshooting:

```yaml
- name: SonarCloud Scan with Debug
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  run: |
    mvn sonar:sonar \
      -Dsonar.projectKey=${{ secrets.SONAR_ORGANIZATION }}_cicd-demo \
      -Dsonar.organization=${{ secrets.SONAR_ORGANIZATION }} \
      -Dsonar.verbose=true \
      -X
```

## 11. Hands-on Exercises {#exercises}

### Exercise 1: Basic SonarCloud Setup (20 minutes)

**Objective**: Set up SonarCloud for the cicd-demo project

**Tasks**:
1. Create SonarCloud account
2. Generate API token
3. Add tokens to GitHub Secrets
4. Create `sonar-project.properties`
5. Update `pom.xml` with SonarCloud plugin
6. Run first analysis

**Expected Outcome**:
- SonarCloud dashboard shows analysis results
- Security issues are identified
- Quality gate status is visible

**Verification Steps**:
1. Visit SonarCloud dashboard
2. Verify project appears
3. Check security tab for vulnerabilities
4. Review security hotspots

### Exercise 2: GitHub Actions Integration (25 minutes)

**Objective**: Automate SonarCloud scanning with GitHub Actions

**Tasks**:
1. Create `.github/workflows/sonarcloud.yml`
2. Configure workflow with proper secrets
3. Push changes to trigger workflow
4. Review workflow execution in GitHub Actions
5. Check SonarCloud updates automatically

**Expected Outcome**:
- Workflow runs successfully on push
- SonarCloud analysis completes
- Results appear in dashboard
- PR decoration works (if testing with PR)

**Workflow Code**:
```yaml
name: SonarCloud Analysis

on:
  push:
    branches: [master]
  pull_request:
    branches: [master]

jobs:
  sonarcloud:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Run SonarCloud
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        run: |
          mvn clean verify sonar:sonar \
            -Dsonar.projectKey=${{ secrets.SONAR_ORGANIZATION }}_cicd-demo \
            -Dsonar.organization=${{ secrets.SONAR_ORGANIZATION }}
```

### Exercise 3: Security Vulnerability Analysis (30 minutes)

**Objective**: Identify and analyze security vulnerabilities

**Tasks**:
1. Review SonarCloud security findings
2. Identify critical vulnerabilities
3. Analyze security hotspots
4. Document findings
5. Prioritize remediation

**Steps**:

1. **Navigate to Security Tab** in SonarCloud
2. **Review Vulnerabilities**:
   - List all critical/high severity issues
   - Understand the security impact
   - Note affected files and lines

3. **Analyze Security Hotspots**:
   - Review code requiring manual inspection
   - Determine if hotspot is a real issue
   - Mark as "Safe" or "To Review"

4. **Create Security Report**:
   ```markdown
   # Security Analysis Report

   ## Critical Vulnerabilities
   1. [Vulnerability Name] - [File:Line]
      - Impact: [Description]
      - Fix: [Recommendation]

   ## Security Hotspots
   1. [Hotspot Category] - [File:Line]
      - Review Status: [Safe/Unsafe]
      - Justification: [Reasoning]
   ```

**Expected Outcome**:
- Comprehensive understanding of security issues
- Documented security findings
- Prioritized remediation plan

### Exercise 4: Quality Gate Configuration (25 minutes)

**Objective**: Configure custom security-focused quality gate

**Tasks**:
1. Create new quality gate named "Security-First"
2. Add security-specific conditions
3. Apply to cicd-demo project
4. Test with code changes
5. Verify gate enforcement in CI/CD

**Quality Gate Configuration**:

1. **Create Quality Gate**:
   - SonarCloud → Organization → Quality Gates
   - Click "Create"
   - Name: "Security-First"

2. **Add Conditions**:
   ```
   New Code:
   ├─ Security Rating = A
   ├─ Vulnerabilities = 0
   ├─ Security Hotspots Reviewed = 100%
   └─ Security Review Rating = A

   Overall Code:
   ├─ Security Rating ≤ C
   └─ Vulnerabilities ≤ 5
   ```

3. **Apply to Project**:
   - Project Settings → Quality Gate
   - Select "Security-First"

4. **Update Workflow**:
   ```yaml
   - name: Check Quality Gate
     run: |
       mvn sonar:sonar \
         -Dsonar.qualitygate.wait=true
   ```

**Expected Outcome**:
- Custom quality gate created and applied
- CI/CD fails on quality gate failure
- Security requirements enforced automatically

### Exercise 5: Continuous Monitoring Setup (30 minutes)

**Objective**: Implement continuous security monitoring

**Tasks**:
1. Create scheduled scanning workflow
2. Configure notifications
3. Set up security dashboard
4. Implement trend tracking
5. Create security metrics report

**Implementation**:

1. **Scheduled Scan Workflow** (`.github/workflows/security-scan.yml`):
   ```yaml
   name: Weekly Security Scan

   on:
     schedule:
       - cron: '0 0 * * 0'  # Sunday midnight
     workflow_dispatch:

   jobs:
     security-scan:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
           with:
             fetch-depth: 0

         - name: Set up JDK 17
           uses: actions/setup-java@v4
           with:
             java-version: '17'
             distribution: 'temurin'

         - name: Run security analysis
           env:
             GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
             SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
           run: |
             mvn clean verify sonar:sonar \
               -Dsonar.projectKey=${{ secrets.SONAR_ORGANIZATION }}_cicd-demo \
               -Dsonar.organization=${{ secrets.SONAR_ORGANIZATION }} \
               -Dsonar.qualitygate.wait=true

         - name: Security Report
           if: failure()
           run: |
             echo "Security scan failed! Check SonarCloud dashboard."
             echo "Project: https://sonarcloud.io/dashboard?id=${{ secrets.SONAR_ORGANIZATION }}_cicd-demo"
   ```

**Expected Outcome**:
- Automated weekly security scans
- Security metrics tracked over time
- Dashboard with real-time status
- Automated alerts on security issues

## Conclusion

In this practical, you've learned how to:

1. ✅ Set up SonarCloud account and integrate with GitHub
2. ✅ Configure GitHub Actions for automated security scanning
3. ✅ Understand and interpret SonarCloud security reports
4. ✅ Implement quality gates for security enforcement
5. ✅ Set up continuous monitoring for security

### Key Takeaways

- **Security-First Development**: Integrate SAST early in the development cycle
- **Automation**: Automate security checks for consistency
- **Quality Gates**: Enforce security standards automatically
- **Continuous Monitoring**: Track security trends over time
- **Complementary Tools**: Use SonarCloud and Snyk together for comprehensive coverage

### Comparison Summary: SonarCloud vs Snyk

**SonarCloud Advantages**:
- Deep source code analysis
- Quality gates and metrics
- Security hotspot identification
- Multi-language support
- Code quality + security combined

**Snyk Advantages**:
- Superior dependency scanning
- Container and IaC security
- Real-time vulnerability database
- Automated fix PRs
- Better remediation guidance

**Recommended Approach**:
Use **both** tools in your security pipeline:
- **SonarCloud** for source code security analysis
- **Snyk** for dependency and container security
- Combined coverage provides comprehensive protection

### Next Steps

1. **Expand Analysis**: Add more security rules and custom configurations
2. **Automate Remediation**: Create workflows to auto-fix security issues
3. **Security Training**: Regular team training on secure coding practices
4. **Policy Enforcement**: Implement organization-wide security policies
5. **Integration**: Connect SonarCloud with other security tools (DAST, IAST)

### Additional Resources

- [SonarCloud Documentation](https://docs.sonarcloud.io/)
- [SonarCloud Security Rules](https://rules.sonarsource.com/)
- [GitHub Actions Security Guide](https://docs.github.com/en/actions/security-guides)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [SonarCloud Blog](https://blog.sonarsource.com/)
- [Java Security Best Practices](https://cheatsheetseries.owasp.org/cheatsheets/Java_Security_Cheat_Sheet.html)

---

## Submission Instructions

### Details of Submission:

1. **Screenshots Required**:
   - SonarCloud dashboard showing analysis results
   - GitHub Actions workflow execution (successful run)
   - Security findings in SonarCloud (vulnerabilities + hotspots)

2. **Configuration Files**:
   - `sonar-project.properties`
   - `.github/workflows/sonarcloud.yml`
   - Updated `pom.xml` with SonarCloud plugin

3. **Evidence**:
   - Screenshot of SonarCloud project dashboard
   - Link to GitHub Actions workflow run
   - Screenshots of at least 2 security issues identified

### Submission Checklist:

- [ ] SonarCloud account created and project configured
- [ ] GitHub Actions workflow running successfully
- [ ] At least 2 security issues identified
- [ ] Quality gate configured and tested
- [ ] Continuous monitoring implemented
- [ ] All screenshots and documentation submitted

---


