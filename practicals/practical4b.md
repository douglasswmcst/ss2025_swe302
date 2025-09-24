# Practical 4b: Setting up DAST with OWASP ZAP in GitHub Actions

## Table of Contents

1. [Introduction to DAST and OWASP ZAP](#introduction)
2. [Prerequisites](#prerequisites)
3. [Understanding SAST vs DAST](#comparison)
4. [Setting up the Application for Testing](#setup-application)
5. [Understanding OWASP ZAP](#understanding-zap)
6. [Integrating OWASP ZAP with GitHub Actions](#integrating-zap)
7. [Understanding ZAP Scan Types](#scan-types)
8. [Interpreting DAST Results](#interpreting-results)
9. [Advanced ZAP Configuration](#advanced-configuration)
10. [Best Practices](#best-practices)
11. [Troubleshooting](#troubleshooting)
12. [Hands-on Exercises](#exercises)

## 1. Introduction to DAST and OWASP ZAP {#introduction}

### What is DAST?

Dynamic Application Security Testing (DAST) is a security testing methodology that analyzes running applications to find vulnerabilities. Unlike SAST (which examines source code), DAST tests the application from the outside, simulating real-world attacks.

**Key Characteristics:**
- Tests running applications (black-box testing)
- Identifies runtime vulnerabilities
- Detects configuration issues
- Simulates attacker behavior
- No access to source code required

### What is OWASP ZAP?

OWASP Zed Attack Proxy (ZAP) is the world's most popular free, open-source web application security scanner. It's maintained by OWASP (Open Web Application Security Project).

**ZAP Features:**
- **Automated Scanning**: Quick baseline and full scans
- **Manual Testing**: Intercepting proxy for manual security testing
- **API Testing**: Support for REST, SOAP, GraphQL APIs
- **Authentication**: Handles various authentication mechanisms
- **Reporting**: Comprehensive HTML, JSON, XML reports
- **Extensibility**: Plugin architecture for custom functionality

### Why Use ZAP for DAST?

- **Free & Open Source**: No licensing costs
- **Easy Integration**: Works with CI/CD pipelines
- **Active Community**: Regular updates and support
- **OWASP Standard**: Covers OWASP Top 10 vulnerabilities
- **Cross-Platform**: Runs on Linux, Windows, macOS
- **Docker Support**: Easy containerized deployment

## 2. Prerequisites {#prerequisites}

Before starting this practical, ensure you have:

- [ ] A GitHub account with repository access
- [ ] Basic understanding of web application security
- [ ] Familiarity with Docker (basic concepts)
- [ ] Understanding of CI/CD concepts
- [ ] Access to the `cicd-demo` repository (from Practical 4)
- [ ] Basic knowledge of HTTP requests and responses

### Getting Started: Repository Setup

If you haven't already cloned the repository. Youa re encourged to use the same repo you used for practical 4 and 4a.

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

# Build the application
mvn clean package

# Run the application locally
mvn spring-boot:run
# Application should start on http://localhost:5000
```

## 3. Understanding SAST vs DAST {#comparison}

### Fundamental Differences

| Aspect | SAST (Static) | DAST (Dynamic) |
|--------|---------------|----------------|
| **Testing Method** | Source code analysis | Running application testing |
| **Access Required** | Source code | Running application URL |
| **Testing Phase** | Development/Build | Testing/Staging/Production |
| **Detection Type** | Code vulnerabilities | Runtime vulnerabilities |
| **False Positives** | Higher | Lower |
| **Coverage** | Complete code | Exposed functionality |
| **Speed** | Faster | Slower |
| **Configuration Issues** | No | Yes |

### What Each Tool Finds

**SAST (SonarCloud/Snyk) Finds:**
- SQL injection in code
- Hard-coded credentials
- Insecure cryptography usage
- Buffer overflows
- Code injection vulnerabilities

**DAST (OWASP ZAP) Finds:**
- Missing security headers
- SSL/TLS configuration issues
- Authentication/session management flaws
- Server misconfigurations
- Actual exploitable vulnerabilities
- OWASP Top 10 issues in runtime

### Complementary Security Approach

```
Complete Security Pipeline:
┌─────────────────────────────────────────────────────┐
│  Development Phase                                  │
│  ├─ SAST (SonarCloud) → Code vulnerabilities       │
│  └─ Dependency Scan (Snyk) → Library issues        │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  Testing Phase                                      │
│  └─ DAST (OWASP ZAP) → Runtime vulnerabilities     │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  Production                                         │
│  └─ Continuous Monitoring                           │
└─────────────────────────────────────────────────────┘
```

## 4. Setting up the Application for Testing {#setup-application}

### Step 4.1: Understanding the Target Application

The `cicd-demo` application is a Spring Boot REST API with the RESTful endpoints.

### Step 4.2: Running the Application Locally

Before DAST testing, verify the application runs:

```bash
# Build the application
mvn clean package

# Run the Spring Boot application
mvn spring-boot:run
```

Test endpoints:
Verify your port. as per dockerfile it should be 5000, but if you run with maven it might be 5000.
```bash
# Test endpoints
curl http://localhost:5000/nations 
curl http://localhost:5000/currencies

```

### Step 4.3: Dockerizing the Application (For CI/CD)

The repository should already have a `dockerfile`. Verify it exists.

### Step 4.4: Preparing for DAST in CI/CD

For DAST in GitHub Actions, we need:
1. ✅ Application that can be built and run
2. ✅ Docker container (for easy deployment in CI/CD)
3. ✅ Known endpoints to test
4. ✅ Network accessibility during scan

## 5. Understanding OWASP ZAP {#understanding-zap}

### ZAP Architecture

```
OWASP ZAP Components:
┌────────────────────────────────────────┐
│  ZAP Spider                            │
│  └─ Crawls application to discover    │
│     URLs and parameters                │
└────────────────────────────────────────┘
              ↓
┌────────────────────────────────────────┐
│  Active Scanner                        │
│  └─ Sends attack payloads              │
│     └─ SQL injection                   │
│     └─ XSS                             │
│     └─ Path traversal                  │
│     └─ Command injection               │
└────────────────────────────────────────┘
              ↓
┌────────────────────────────────────────┐
│  Passive Scanner                       │
│  └─ Analyzes responses                 │
│     └─ Missing headers                 │
│     └─ Cookie security                 │
│     └─ Information disclosure          │
└────────────────────────────────────────┘
              ↓
┌────────────────────────────────────────┐
│  Report Generator                      │
│  └─ HTML, JSON, XML, Markdown          │
└────────────────────────────────────────┘
```

### ZAP Scan Types

#### 1. Baseline Scan
- **Speed**: Fast (1-2 minutes)
- **Depth**: Shallow
- **Use Case**: Quick security check, PR validation
- **Detection**: Passive vulnerabilities only

#### 2. Full Scan
- **Speed**: Slow (10-30 minutes)
- **Depth**: Deep
- **Use Case**: Comprehensive security testing
- **Detection**: Passive + Active vulnerabilities

#### 3. API Scan
- **Speed**: Medium (5-10 minutes)
- **Depth**: API-specific
- **Use Case**: REST/GraphQL API testing
- **Detection**: API-specific vulnerabilities

### ZAP Docker Images

OWASP provides official Docker images:

```bash
# Stable release
ghcr.io/zaproxy/zaproxy:stable

# Weekly updates
ghcr.io/zaproxy/zaproxy:weekly

# Bare minimum (smallest)
ghcr.io/zaproxy/zaproxy:bare
```

## 6. Integrating OWASP ZAP with GitHub Actions {#integrating-zap}

### Step 6.1: Basic ZAP Baseline Scan Workflow

Create `.github/workflows/zap-scan.yml`:

```yaml
name: OWASP ZAP Security Scan

on:
  push:
    branches: [master, main]
  pull_request:
    branches: [master, main]
  workflow_dispatch:

jobs:
  zap-baseline-scan:
    name: ZAP Baseline Scan
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: maven

      - name: Build application
        run: mvn clean package -DskipTests

      - name: Build Docker image
        run: docker build -t cicd-demo:test .

      - name: Run application container
        run: |
          docker run -d -p 5000:5000 --name cicd-demo-app cicd-demo:test
          # Wait for application to be ready
          timeout 60 bash -c 'until curl -f http://localhost:5000/; do sleep 2; done'

      - name: Run ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.12.0
        with:
          target: 'http://localhost:5000'
          rules_file_name: '.zap/rules.tsv'
          cmd_options: '-a'

      - name: Stop application container
        if: always()
        run: docker stop cicd-demo-app && docker rm cicd-demo-app
```

### Step 6.2: ZAP Full Scan Workflow

For comprehensive testing, use full scan:

```yaml
name: OWASP ZAP Full Scan

on:
  schedule:
    - cron: '0 2 * * 0'  # Weekly on Sunday
  workflow_dispatch:

jobs:
  zap-full-scan:
    name: ZAP Full Security Scan
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Build and package
        run: mvn clean package -DskipTests

      - name: Build Docker image
        run: docker build -t cicd-demo:test .

      - name: Run application
        run: |
          docker run -d -p 5000:5000 --name cicd-demo-app cicd-demo:test
          timeout 60 bash -c 'until curl -f http://localhost:5000/; do sleep 2; done'

      - name: Run ZAP Full Scan
        uses: zaproxy/action-full-scan@v0.10.0
        with:
          target: 'http://localhost:5000'
          rules_file_name: '.zap/rules.tsv'
          cmd_options: '-a -j'

      - name: Upload ZAP Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: zap-report
          path: report_html.html

      - name: Cleanup
        if: always()
        run: docker stop cicd-demo-app && docker rm cicd-demo-app
```

### Step 6.3: Creating ZAP Rules Configuration

Create `.zap/rules.tsv` to configure scan rules:

```tsv
# ZAP Scanning Rules
# Format: id	threshold	action
# threshold: OFF, LOW, MEDIUM, HIGH
# action: IGNORE, WARN, FAIL

10020	MEDIUM	FAIL	# Anti-CSRF Tokens Check
10021	MEDIUM	FAIL	# X-Content-Type-Options Header Missing
10023	MEDIUM	WARN	# Information Disclosure - Debug Error Messages
10025	MEDIUM	FAIL	# X-Frame-Options Header Not Set
10026	MEDIUM	FAIL	# HTTP Parameter Override
10027	MEDIUM	WARN	# Information Disclosure - Suspicious Comments
10032	MEDIUM	WARN	# Viewstate Scanner
10035	MEDIUM	FAIL	# Strict-Transport-Security Header Not Set
10036	MEDIUM	WARN	# HTTP Server Response Header
10037	MEDIUM	FAIL	# Server Leaks Information via "X-Powered-By" HTTP Response Header Field(s)
10038	MEDIUM	FAIL	# Content Security Policy (CSP) Header Not Set
10040	MEDIUM	FAIL	# Secure Pages Include Mixed Content
10041	MEDIUM	WARN	# HTTP to HTTPS Insecure Transition in Form Post
10042	MEDIUM	WARN	# HTTPS to HTTP Insecure Transition in Form Post
10043	MEDIUM	FAIL	# User Controllable JavaScript Event (XSS)
10044	MEDIUM	WARN	# Big Redirect Detected (Potential Sensitive Information Leak)
10045	MEDIUM	FAIL	# Source Code Disclosure - /WEB-INF folder
10047	MEDIUM	WARN	# HTTPS Content Available via HTTP
10048	MEDIUM	WARN	# Remote Code Execution - Shell Shock
10049	MEDIUM	FAIL	# Content Cacheability
10050	MEDIUM	WARN	# Retrieved from Cache
10051	MEDIUM	FAIL	# Relative Path Confusion
10052	MEDIUM	WARN	# X-ChromeLogger-Data (XCOLD) Header Information Leak
10054	MEDIUM	FAIL	# Cookie Without SameSite Attribute
10055	MEDIUM	FAIL	# CSP Scanner
10056	MEDIUM	FAIL	# X-Debug-Token Information Leak
10057	MEDIUM	FAIL	# Username Hash Found
10061	MEDIUM	FAIL	# X-AspNet-Version Response Header
10062	MEDIUM	FAIL	# PII Disclosure
10063	MEDIUM	FAIL	# Permissions Policy Header Not Set
10096	MEDIUM	FAIL	# Timestamp Disclosure
10097	MEDIUM	WARN	# Hash Disclosure
10098	MEDIUM	FAIL	# Cross-Domain Misconfiguration
10099	MEDIUM	FAIL	# Source Code Disclosure
10103	MEDIUM	WARN	# Charity Redirect
10104	MEDIUM	FAIL	# User Agent Fuzzer
10105	MEDIUM	FAIL	# Weak Authentication Method
10106	MEDIUM	FAIL	# HTTP Only Site
10107	MEDIUM	FAIL	# Httpoxy - Proxy Header Misuse
10108	MEDIUM	FAIL	# Reverse Tabnabbing
10109	MEDIUM	FAIL	# Modern Web Application
10110	MEDIUM	WARN	# Dangerous JS Functions
10202	MEDIUM	FAIL	# Absence of Anti-CSRF Tokens
```

### Step 6.4: Advanced Workflow with Multiple Scan Types

```yaml
name: Comprehensive ZAP Security Scan

on:
  push:
    branches: [master]
  pull_request:
    branches: [master]
  schedule:
    - cron: '0 3 * * 1'  # Monday 3 AM

jobs:
  setup:
    name: Build and Deploy App
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Build application
        run: mvn clean package -DskipTests

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-jar
          path: target/*.jar

  baseline-scan:
    name: ZAP Baseline Scan
    needs: setup
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'

    steps:
      - uses: actions/checkout@v4

      - name: Download artifact
        uses: actions/download-artifact@v4
        with:
          name: app-jar
          path: target/

      - name: Build Docker image
        run: docker build -t cicd-demo:test .

      - name: Run application
        run: |
          docker run -d -p 5000:5000 --name app cicd-demo:test
          timeout 60 bash -c 'until curl -f http://localhost:5000/; do sleep 2; done'

      - name: ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.12.0
        with:
          target: 'http://localhost:5000'
          rules_file_name: '.zap/rules.tsv'
          cmd_options: '-a'

      - name: Cleanup
        if: always()
        run: docker stop app && docker rm app

  full-scan:
    name: ZAP Full Scan
    needs: setup
    runs-on: ubuntu-latest
    if: github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'

    steps:
      - uses: actions/checkout@v4

      - name: Download artifact
        uses: actions/download-artifact@v4
        with:
          name: app-jar
          path: target/

      - name: Build Docker image
        run: docker build -t cicd-demo:test .

      - name: Run application
        run: |
          docker run -d -p 5000:5000 --name app cicd-demo:test
          timeout 60 bash -c 'until curl -f http://localhost:5000/; do sleep 2; done'

      - name: ZAP Full Scan
        uses: zaproxy/action-full-scan@v0.10.0
        with:
          target: 'http://localhost:5000'
          rules_file_name: '.zap/rules.tsv'
          cmd_options: '-a -j'

      - name: Upload ZAP Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: zap-full-report
          path: |
            report_html.html
            report_json.json
            report_md.md

      - name: Cleanup
        if: always()
        run: docker stop app && docker rm app
```

## 7. Understanding ZAP Scan Types {#scan-types}

### Baseline Scan Deep Dive

**Purpose**: Quick passive security check

**What it does**:
1. Spiders the target to discover URLs
2. Passively scans HTTP traffic
3. Identifies low-hanging fruit vulnerabilities
4. Generates report

**What it finds**:
- Missing security headers
- Cookie issues (HttpOnly, Secure, SameSite)
- Information disclosure
- Deprecated features
- Insecure client-side code

**Command Example**:
```bash
docker run -t ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py \
  -t http://localhost:5000 \
  -r baseline_report.html \
  -a
```

### Full Scan Deep Dive

**Purpose**: Comprehensive active security testing

**What it does**:
1. Spiders the application
2. Passive scanning
3. Active scanning (sends attack payloads)
4. Authentication testing
5. Session management analysis

**What it finds**:
- SQL injection
- Cross-site scripting (XSS)
- Path traversal
- Command injection
- Remote code execution
- Insecure deserialization
- XML external entity (XXE)
- Server-side request forgery (SSRF)

**Command Example**:
```bash
docker run -t ghcr.io/zaproxy/zaproxy:stable \
  zap-full-scan.py \
  -t http://localhost:5000 \
  -r full_report.html \
  -J full_report.json \
  -a
```

### API Scan Deep Dive

**Purpose**: API-specific security testing

**What it does**:
1. Imports API definition (OpenAPI/Swagger)
2. Tests each endpoint
3. Validates input/output
4. Tests authentication

**What it finds**:
- Broken object level authorization
- Broken authentication
- Excessive data exposure
- Lack of rate limiting
- Mass assignment
- Security misconfiguration

**Command Example**:
```bash
docker run -t ghcr.io/zaproxy/zaproxy:stable \
  zap-api-scan.py \
  -t http://localhost:5000/nations \
  -f openapi \
  -r api_report.html
```

## 8. Interpreting DAST Results {#interpreting-results}

### Understanding ZAP Risk Levels

ZAP categorizes findings by risk:

| Risk Level | Description | Action Required |
|------------|-------------|-----------------|
| **High** | Critical security vulnerability | Fix immediately |
| **Medium** | Significant security issue | Fix soon |
| **Low** | Minor security concern | Fix when possible |
| **Informational** | Security note/best practice | Review and consider |

### Sample ZAP Report Analysis

```
OWASP ZAP Security Scan Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Summary:
  High:           2
  Medium:         5
  Low:            8
  Informational:  3

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

HIGH RISK ALERTS:

1. SQL Injection [40018]
   URL: http://localhost:5000/api/user?id=1
   Method: GET
   Parameter: id
   Evidence: You have an error in your SQL syntax

   Description:
   SQL injection may be possible. An attacker could manipulate
   queries to access unauthorized data.

   Solution:
   Use parameterized queries/prepared statements. Never concatenate
   user input directly into SQL queries.

   Example Fix:
   // Vulnerable
   String query = "SELECT * FROM users WHERE id=" + userId;

   // Secure
   String query = "SELECT * FROM users WHERE id=?";
   PreparedStatement stmt = conn.prepareStatement(query);
   stmt.setInt(1, userId);

2. Cross Site Scripting (Reflected) [40012]
   URL: http://localhost:5000/search?q=<script>alert(1)</script>
   Method: GET
   Parameter: q
   Evidence: <script>alert(1)</script>

   Description:
   User input is reflected in the response without proper encoding.

   Solution:
   Encode all user input before rendering. Use context-appropriate
   encoding (HTML, JavaScript, URL).

   Example Fix:
   // Vulnerable
   return "<div>" + userInput + "</div>";

   // Secure
   return "<div>" + StringEscapeUtils.escapeHtml4(userInput) + "</div>";

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

MEDIUM RISK ALERTS:

3. X-Frame-Options Header Not Set [10020]
   URL: http://localhost:5000/

   Description:
   X-Frame-Options header is not included in the HTTP response.
   Page can be rendered in a frame, potentially enabling clickjacking.

   Solution:
   Add X-Frame-Options header:

   Spring Boot Configuration:
   @Configuration
   public class SecurityConfig {
       @Bean
       public SecurityFilterChain filterChain(HttpSecurity http) {
           http.headers()
               .frameOptions().deny();
           return http.build();
       }
   }

4. Content Security Policy (CSP) Header Not Set [10038]
   URL: http://localhost:5000/

   Description:
   CSP header is missing, leaving application vulnerable to XSS
   and data injection attacks.

   Solution:
   Add CSP header:
   Content-Security-Policy: default-src 'self'; script-src 'self'
```

### ZAP Alert Reference

Common ZAP alerts and meanings:

```
High Risk:
├─ SQL Injection (40018)
├─ Remote Code Execution (90019)
├─ Path Traversal (6)
├─ Remote File Inclusion (7)
├─ Cross Site Scripting (40012-40017)
└─ External Redirect (20019)

Medium Risk:
├─ Missing Anti-CSRF Tokens (10202)
├─ X-Frame-Options Missing (10020)
├─ CSP Missing (10038)
├─ Cookie Without Secure Flag (10011)
└─ Session Fixation (40013)

Low Risk:
├─ X-Content-Type-Options Missing (10021)
├─ Server Leaks Version (10037)
├─ Timestamp Disclosure (10096)
└─ Cookie Without HttpOnly (10010)
```

## 9. Advanced ZAP Configuration {#advanced-configuration}

### Step 9.1: Custom ZAP Configuration File

Create `.zap/config.conf` for advanced settings:

```properties
# ZAP Configuration File

# Spider Settings
spider.maxDuration=5
spider.maxDepth=5
spider.maxChildren=10
spider.postForm=true

# Active Scanner Settings
scanner.strength=MEDIUM
scanner.attackStrength=MEDIUM
scanner.alertThreshold=MEDIUM

# Scanner Rules (enable/disable specific checks)
scanner.rule.0=true     # Directory Browsing
scanner.rule.6=true     # Path Traversal
scanner.rule.7=true     # Remote File Inclusion
scanner.rule.40012=true # XSS (Reflected)
scanner.rule.40014=true # XSS (Persistent)
scanner.rule.40018=true # SQL Injection
scanner.rule.90019=true # Code Injection

# Performance
scanner.threadPerHost=2
scanner.maxResultsToList=1000

# HTTP Settings
connection.timeoutInSecs=60
```

### Step 9.2: Authentication Configuration

For applications requiring authentication, create `.zap/auth.conf`:

```yaml
# Authentication Configuration
auth:
  type: form
  loginUrl: http://localhost:5000/login
  loginRequestData: username={%username%}&password={%password%}
  usernameParameter: username
  passwordParameter: password
  loggedInIndicator: '\QWelcome\E'
  loggedOutIndicator: '\QLogin\E'

users:
  - name: testuser
    username: admin
    password: admin123
```

Use in workflow:
```yaml
- name: ZAP Scan with Authentication
  run: |
    docker run -v $(pwd)/.zap:/zap/wrk/:rw \
      -t ghcr.io/zaproxy/zaproxy:stable \
      zap-full-scan.py \
      -t http://localhost:5000 \
      -z "-config auth.type=form \
          -config auth.loginurl=http://localhost:5000/login \
          -config auth.username=admin \
          -config auth.password=admin123"
```

### Step 9.3: API Scanning with OpenAPI/Swagger

For API testing with specification:

```yaml
- name: Download OpenAPI spec
  run: curl http://localhost:5000/v3/api-docs > openapi.json

- name: ZAP API Scan
  run: |
    docker run -v $(pwd):/zap/wrk/:rw \
      -t ghcr.io/zaproxy/zaproxy:stable \
      zap-api-scan.py \
      -t http://localhost:5000 \
      -f openapi \
      -d openapi.json \
      -r api_report.html \
      -J api_report.json
```

### Step 9.4: Custom Scan Policies

Create `.zap/scan-policy.xml` for fine-grained control:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <policy>Security Scan Policy</policy>
  <scanner>
    <level>MEDIUM</level>
    <strength>MEDIUM</strength>
  </scanner>

  <plugins>
    <!-- SQL Injection -->
    <plugin id="40018">
      <enabled>true</enabled>
      <level>MEDIUM</level>
      <strength>HIGH</strength>
    </plugin>

    <!-- XSS (Reflected) -->
    <plugin id="40012">
      <enabled>true</enabled>
      <level>MEDIUM</level>
      <strength>HIGH</strength>
    </plugin>

    <!-- Path Traversal -->
    <plugin id="6">
      <enabled>true</enabled>
      <level>MEDIUM</level>
      <strength>MEDIUM</strength>
    </plugin>

    <!-- Command Injection -->
    <plugin id="90020">
      <enabled>true</enabled>
      <level>HIGH</level>
      <strength>HIGH</strength>
    </plugin>
  </plugins>
</configuration>
```

### Step 9.5: GitHub Security Integration

Upload ZAP results to GitHub Security tab:

```yaml
- name: Run ZAP Scan
  run: |
    docker run -v $(pwd):/zap/wrk/:rw \
      -t ghcr.io/zaproxy/zaproxy:stable \
      zap-full-scan.py \
      -t http://localhost:5000 \
      -r zap_report.html \
      -J zap_report.json

- name: Convert ZAP JSON to SARIF
  uses: ZAPProxy/ZAP-to-SARIF@main
  with:
    zap-json-file: zap_report.json
    sarif-file: zap_report.sarif

- name: Upload SARIF to GitHub
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: zap_report.sarif
```

## 10. Best Practices {#best-practices}

### Security Best Practices

1. **Regular Scanning Schedule**:
   ```yaml
   on:
     push:
       branches: [master]
     pull_request:
       branches: [master]
     schedule:
       - cron: '0 2 * * *'  # Daily at 2 AM
   ```

2. **Scan Different Environments**:
   ```yaml
   strategy:
     matrix:
       environment: [staging, production-mirror]
   ```

3. **Progressive Scanning**:
   ```yaml
   # Quick scan on PR
   - Baseline scan (2 min)

   # Medium scan on merge
   - API scan (10 min)

   # Full scan scheduled
   - Full scan weekly (30 min)
   ```

4. **False Positive Management**:
   ```tsv
   # In .zap/rules.tsv
   10037	OFF	IGNORE	# Server version - known safe
   10096	LOW	WARN	# Timestamp - acceptable
   ```

### Performance Optimization

1. **Use Appropriate Scan Type**:
   - PR: Baseline scan only
   - Merge: API scan
   - Scheduled: Full scan

2. **Limit Scan Scope**:
   ```bash
   # Exclude static resources
   -config spider.excludeUrl=".*\.(jpg|jpeg|png|gif|css|js)$"
   ```

3. **Parallel Scanning**:
   ```yaml
   strategy:
     matrix:
       endpoint: ['/api/users', '/api/data', '/api/auth']
   ```

4. **Cache Docker Images**:
   ```yaml
   - name: Pull ZAP image
     run: docker pull ghcr.io/zaproxy/zaproxy:stable
   ```

### CI/CD Integration Best Practices

1. **Fail Build on High Risks**:
   ```yaml
   - name: Check ZAP Report
     run: |
       HIGH_ALERTS=$(jq '.site[0].alerts[] | select(.riskcode=="3") | length' zap_report.json)
       if [ "$HIGH_ALERTS" -gt 0 ]; then
         echo "High risk vulnerabilities found!"
         exit 1
       fi
   ```

2. **Generate Multiple Report Formats**:
   ```bash
   -r report.html    # HTML for humans
   -J report.json    # JSON for processing
   -w report.md      # Markdown for documentation
   ```

3. **Archive Reports**:
   ```yaml
   - name: Upload reports
     uses: actions/upload-artifact@v4
     with:
       name: zap-reports-${{ github.run_number }}
       path: |
         report.html
         report.json
       retention-days: 90
   ```

### Security Configuration

1. **Network Isolation**:
   ```yaml
   # Use Docker network for isolation
   - name: Create network
     run: docker network create test-network

   - name: Run app in network
     run: docker run --network test-network --name app cicd-demo:test

   - name: Run ZAP in same network
     run: docker run --network test-network zaproxy:stable
   ```

2. **Secrets Management**:
   ```yaml
   # Never hardcode credentials
   env:
     APP_USER: ${{ secrets.TEST_USER }}
     APP_PASS: ${{ secrets.TEST_PASS }}
   ```

3. **Time-bounded Scans**:
   ```bash
   # Prevent infinite scans
   timeout 30m docker run ... zap-full-scan.py
   ```

## 11. Troubleshooting {#troubleshooting}

### Common Issues and Solutions

#### Issue 1: "Connection refused" Error

**Problem**: ZAP cannot connect to application

**Solution**:
```yaml
# Add wait logic
- name: Wait for app to be ready
  run: |
    timeout 120 bash -c 'until curl -f http://localhost:5000/health; do
      echo "Waiting for application..."
      sleep 5
    done'

# Or use wait-for-it script
- name: Wait for application
  run: |
    wget https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh
    chmod +x wait-for-it.sh
    ./wait-for-it.sh localhost:5000 -t 60
```

#### Issue 2: "Scan Timeout" Error

**Problem**: Scan takes too long and times out

**Solution**:
```yaml
# Increase timeout
- name: ZAP Scan with timeout
  timeout-minutes: 30

# Or limit scan scope
  cmd_options: '-a -j -d -m 10'  # max 10 minutes
```

#### Issue 3: Too Many False Positives

**Problem**: Report filled with false positives

**Solution**:
```tsv
# Update .zap/rules.tsv
10037	OFF	IGNORE	# Server version disclosure - acceptable
10096	LOW	WARN	# Timestamp disclosure - not a risk
10027	OFF	IGNORE	# Suspicious comments - false positive
```

#### Issue 4: Authentication Failures

**Problem**: ZAP cannot authenticate to application

**Solution**:
```yaml
# Debug authentication
- name: Test auth manually
  run: |
    curl -X POST http://localhost:5000/login \
      -d "username=admin&password=admin123" \
      -v

# Use ZAP auth script
- name: Create auth script
  run: |
    cat > auth.js << 'EOF'
    function authenticate(helper, paramsValues, credentials) {
      var loginUrl = paramsValues.get("loginUrl");
      var postData = "username=" + credentials.getParam("username") +
                     "&password=" + credentials.getParam("password");

      var msg = helper.prepareMessage();
      msg.setRequestHeader("POST " + loginUrl + " HTTP/1.1");
      msg.setRequestBody(postData);

      helper.sendAndReceive(msg);
      return msg;
    }
    EOF
```

#### Issue 5: Container Network Issues

**Problem**: ZAP and app cannot communicate

**Solution**:
```yaml
# Use host network mode
- name: Run app with host network
  run: docker run --network host cicd-demo:test

- name: Run ZAP with host network
  run: docker run --network host zaproxy:stable \
    zap-baseline.py -t http://localhost:5000

# Or use docker-compose
- name: Use docker-compose
  run: |
    cat > docker-compose.yml << 'EOF'
    version: '3'
    services:
      app:
        image: cicd-demo:test
        ports:
          - "5000:5000"
      zap:
        image: ghcr.io/zaproxy/zaproxy:stable
        depends_on:
          - app
        command: zap-baseline.py -t http://app:5000
    EOF
    docker-compose up --abort-on-container-exit
```

### Debug Mode

Enable verbose logging:

```yaml
- name: ZAP Debug Scan
  run: |
    docker run -v $(pwd):/zap/wrk/:rw \
      -t ghcr.io/zaproxy/zaproxy:stable \
      zap-baseline.py \
      -t http://localhost:5000 \
      -d \  # Debug mode
      -I    # Include response bodies in report
```

## 12. Hands-on Exercises {#exercises}

### Exercise 1: Basic ZAP Baseline Scan (20 minutes)

**Objective**: Set up and run a basic ZAP baseline scan

**Tasks**:
1. Create `.github/workflows/zap-baseline.yml`
2. Configure application deployment
3. Run ZAP baseline scan
4. Review security findings

**Implementation**:

```yaml
name: ZAP Baseline Scan

on:
  pull_request:
    branches: [master]

jobs:
  zap-baseline:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Build application
        run: mvn clean package -DskipTests

      - name: Build Docker image
        run: docker build -t cicd-demo:test .

      - name: Run application
        run: |
          docker run -d -p 5000:5000 --name app cicd-demo:test
          timeout 60 bash -c 'until curl -f http://localhost:5000/; do sleep 2; done'

      - name: ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.12.0
        with:
          target: 'http://localhost:5000'

      - name: Cleanup
        if: always()
        run: docker stop app && docker rm app
```

**Expected Outcome**:
- Workflow executes successfully
- ZAP report generated
- Security issues identified

**Verification**:
1. Check Actions tab for workflow run
2. Review ZAP report in artifacts
3. Identify at least 3 security findings

### Exercise 2: Full Security Scan (30 minutes)

**Objective**: Implement comprehensive DAST with full scan

**Tasks**:
1. Create ZAP rules configuration
2. Implement full scan workflow
3. Generate multiple report formats
4. Archive results

**Rules Configuration** (`.zap/rules.tsv`):
```tsv
10020	MEDIUM	FAIL	# X-Frame-Options Missing
10021	MEDIUM	WARN	# X-Content-Type-Options Missing
10038	MEDIUM	FAIL	# CSP Missing
10054	MEDIUM	FAIL	# Cookie Without SameSite
40018	HIGH	FAIL	# SQL Injection
40012	HIGH	FAIL	# XSS (Reflected)
40014	HIGH	FAIL	# XSS (Persistent)
```

**Workflow** (`.github/workflows/zap-full.yml`):
```yaml
name: ZAP Full Scan

on:
  schedule:
    - cron: '0 2 * * 0'
  workflow_dispatch:

jobs:
  zap-full-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Build and run app
        run: |
          mvn clean package -DskipTests
          docker build -t cicd-demo:test .
          docker run -d -p 5000:5000 --name app cicd-demo:test
          timeout 60 bash -c 'until curl -f http://localhost:5000/; do sleep 2; done'

      - name: ZAP Full Scan
        uses: zaproxy/action-full-scan@v0.10.0
        with:
          target: 'http://localhost:5000'
          rules_file_name: '.zap/rules.tsv'
          cmd_options: '-a -j -m 15'

      - name: Upload Reports
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: zap-full-reports
          path: |
            report_html.html
            report_json.json
            report_md.md

      - name: Cleanup
        if: always()
        run: docker stop app && docker rm app
```

**Expected Outcome**:
- Comprehensive security scan completed
- Multiple report formats generated
- High/medium risks identified

### Exercise 3: Security Findings Analysis (25 minutes)

**Objective**: Analyze and categorize ZAP security findings

**Tasks**:
1. Run ZAP scan on cicd-demo
2. Review generated report
3. Categorize findings by OWASP Top 10
4. Create remediation plan

**Analysis Template**:

```markdown
# ZAP Security Analysis Report

## Executive Summary
- Total Alerts: [X]
- High Risk: [X]
- Medium Risk: [X]
- Low Risk: [X]

## Critical Findings

### 1. [Vulnerability Name]
- **Risk Level**: High
- **OWASP Category**: A03:2021 – Injection
- **Location**: [URL/Endpoint]
- **Evidence**: [Details]
- **Impact**: [What attacker can do]
- **Remediation**: [How to fix]
- **Priority**: Critical - Fix immediately

### 2. [Vulnerability Name]
- **Risk Level**: Medium
- **OWASP Category**: A05:2021 – Security Misconfiguration
- **Location**: [URL/Endpoint]
- **Evidence**: [Details]
- **Impact**: [What attacker can do]
- **Remediation**: [How to fix]
- **Priority**: High - Fix within 1 week

## OWASP Top 10 Mapping

| OWASP Category | Findings | Risk Level |
|----------------|----------|------------|
| A01:2021 – Broken Access Control | 0 | - |
| A02:2021 – Cryptographic Failures | 2 | Medium |
| A03:2021 – Injection | 1 | High |
| A04:2021 – Insecure Design | 0 | - |
| A05:2021 – Security Misconfiguration | 5 | Medium |
| A06:2021 – Vulnerable Components | 0 | - |
| A07:2021 – ID & Auth Failures | 1 | Medium |
| A08:2021 – Software & Data Integrity | 0 | - |
| A09:2021 – Security Logging Failures | 0 | - |
| A10:2021 – SSRF | 0 | - |

## Remediation Roadmap

### Phase 1: Critical (Week 1)
- [ ] Fix SQL Injection in /api/user endpoint
- [ ] Fix Reflected XSS in /search endpoint

### Phase 2: High Priority (Week 2)
- [ ] Add X-Frame-Options header
- [ ] Implement Content Security Policy
- [ ] Add Anti-CSRF tokens

### Phase 3: Medium Priority (Week 3-4)
- [ ] Add SameSite cookie attribute
- [ ] Remove server version disclosure
- [ ] Implement secure session management
```

**Expected Outcome**:
- Comprehensive security analysis
- OWASP Top 10 mapping
- Prioritized remediation plan

### Exercise 4: GitHub Security Integration (30 minutes)

**Objective**: Integrate ZAP results with GitHub Security

**Tasks**:
1. Convert ZAP JSON to SARIF format
2. Upload to GitHub Code Scanning
3. Configure security alerts
4. Review in Security tab

**Workflow**:
```yaml
name: ZAP SARIF Upload

on:
  push:
    branches: [master]
  pull_request:
    branches: [master]

jobs:
  zap-sarif:
    runs-on: ubuntu-latest

    permissions:
      security-events: write
      contents: read

    steps:
      - uses: actions/checkout@v4

      - name: Set up environment
        run: |
          mvn clean package -DskipTests
          docker build -t cicd-demo:test .
          docker run -d -p 5000:5000 --name app cicd-demo:test
          timeout 60 bash -c 'until curl -f http://localhost:5000/; do sleep 2; done'

      - name: Run ZAP Scan
        run: |
          docker run -v $(pwd):/zap/wrk/:rw \
            -t ghcr.io/zaproxy/zaproxy:stable \
            zap-baseline.py \
            -t http://localhost:5000 \
            -J zap_report.json \
            -r zap_report.html

      - name: Convert to SARIF
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: zap_report.sarif
          category: zap-scan

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: zap-reports
          path: |
            zap_report.json
            zap_report.html

      - name: Cleanup
        if: always()
        run: docker stop app && docker rm app
```

**SARIF Conversion Script**:
```python
# convert-zap-to-sarif.py
import json
import sys

def convert_zap_to_sarif(zap_json_file, sarif_output_file):
    with open(zap_json_file, 'r') as f:
        zap_data = json.load(f)

    sarif = {
        "version": "2.1.0",
        "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
        "runs": [{
            "tool": {
                "driver": {
                    "name": "OWASP ZAP",
                    "version": "2.14.0",
                    "informationUri": "https://www.zaproxy.org/"
                }
            },
            "results": []
        }]
    }

    for site in zap_data.get('site', []):
        for alert in site.get('alerts', []):
            sarif['runs'][0]['results'].append({
                "ruleId": str(alert['pluginid']),
                "level": map_risk_level(alert['riskcode']),
                "message": {
                    "text": alert['alert']
                },
                "locations": [{
                    "physicalLocation": {
                        "artifactLocation": {
                            "uri": alert['url']
                        }
                    }
                }]
            })

    with open(sarif_output_file, 'w') as f:
        json.dump(sarif, f, indent=2)

def map_risk_level(risk_code):
    mapping = {
        '3': 'error',    # High
        '2': 'warning',  # Medium
        '1': 'note',     # Low
        '0': 'none'      # Informational
    }
    return mapping.get(str(risk_code), 'warning')

if __name__ == '__main__':
    convert_zap_to_sarif('zap_report.json', 'zap_report.sarif')
```

**Expected Outcome**:
- ZAP results in GitHub Security tab
- Automated security alerts
- Integration with code review process

### Exercise 5: Comprehensive Security Pipeline (35 minutes)

**Objective**: Build complete security pipeline with SAST + DAST

**Tasks**:
1. Combine SonarCloud (SAST) + ZAP (DAST)
2. Create unified security workflow
3. Implement quality gates
4. Generate combined report

**Unified Workflow**:
```yaml
name: Complete Security Pipeline

on:
  push:
    branches: [master]
  pull_request:
    branches: [master]

jobs:
  sast:
    name: Static Security Analysis
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

      - name: SonarCloud Scan
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        run: |
          mvn clean verify sonar:sonar \
            -Dsonar.projectKey=${{ secrets.SONAR_ORGANIZATION }}_cicd-demo \
            -Dsonar.organization=${{ secrets.SONAR_ORGANIZATION }}

  dast:
    name: Dynamic Security Analysis
    needs: sast
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Build and deploy
        run: |
          mvn clean package -DskipTests
          docker build -t cicd-demo:test .
          docker run -d -p 5000:5000 --name app cicd-demo:test
          timeout 60 bash -c 'until curl -f http://localhost:5000/; do sleep 2; done'

      - name: ZAP Scan
        uses: zaproxy/action-baseline@v0.12.0
        with:
          target: 'http://localhost:5000'
          rules_file_name: '.zap/rules.tsv'

      - name: Cleanup
        if: always()
        run: docker stop app && docker rm app

  security-report:
    name: Generate Security Report
    needs: [sast, dast]
    runs-on: ubuntu-latest
    steps:
      - name: Create Combined Report
        run: |
          cat > security-report.md << 'EOF'
          # Security Analysis Report

          ## SAST Results (SonarCloud)
          - Code vulnerabilities: Check SonarCloud dashboard
          - Security hotspots: Review required

          ## DAST Results (OWASP ZAP)
          - Runtime vulnerabilities: Check ZAP report
          - Configuration issues: Review required

          ## Recommendations
          1. Address all HIGH severity SAST issues
          2. Fix all HIGH risk DAST findings
          3. Review and resolve security hotspots
          4. Implement missing security headers
          EOF

      - name: Upload Report
        uses: actions/upload-artifact@v4
        with:
          name: security-report
          path: security-report.md
```

**Expected Outcome**:
- Complete security coverage (SAST + DAST)
- Automated security pipeline
- Unified security report

## Conclusion

In this practical, you've learned how to:

1. ✅ Understand DAST and OWASP ZAP fundamentals
2. ✅ Set up OWASP ZAP in GitHub Actions
3. ✅ Configure different scan types (baseline, full, API)
4. ✅ Interpret ZAP security findings
5. ✅ Integrate DAST with CI/CD pipeline

### Key Takeaways

- **DAST Complements SAST**: Use both for comprehensive security
- **Runtime Testing**: DAST finds issues only visible when application runs
- **Progressive Scanning**: Start with baseline, progress to full scans
- **Automation**: Integrate DAST into every deployment pipeline
- **Continuous Improvement**: Regular scanning catches new vulnerabilities

### DAST vs SAST Summary

**When to Use DAST (OWASP ZAP)**:
- Test runtime configuration
- Validate security headers
- Test authentication/authorization
- Find server misconfigurations
- Simulate real attacks

**When to Use SAST (SonarCloud)**:
- Review source code security
- Check coding standards
- Find logic vulnerabilities
- Early development testing

**Best Practice**: Use both in security pipeline for maximum coverage

### Additional Resources

- [OWASP ZAP Documentation](https://www.zaproxy.org/docs/)
- [ZAP Automation Framework](https://www.zaproxy.org/docs/automate/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [ZAP GitHub Actions](https://github.com/zaproxy/action-baseline)
- [Web Security Academy](https://portswigger.net/web-security)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)

---

## Submission Instructions

### Details of Submission:

1. **Screenshots Required**:
   - ZAP scan report (HTML view)
   - GitHub Actions workflow execution (successful)
   - Security findings summary
   - At least 2 identified vulnerabilities

2. **Configuration Files**:
   - `.github/workflows/zap-scan.yml`
   - `.zap/rules.tsv`
   - `dockerfile` (if modified)

3. **Evidence**:
   - Screenshot of GitHub Actions workflow run
   - ZAP report artifacts
   - Screenshots of at least 2 security issues

### Submission Checklist:

- [ ] OWASP ZAP scan configured and running
- [ ] GitHub Actions workflow executing successfully
- [ ] At least 2 security findings identified and documented
- [ ] ZAP rules configuration created
- [ ] Security analysis report completed
- [ ] All screenshots and documentation submitted

---
