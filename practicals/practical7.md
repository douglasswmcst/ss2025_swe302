# Practical 7: Performance Testing with k6

## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Installing k6](#installing-k6)
- [Understanding k6 Basics](#understanding-k6-basics)
- [Running Your First Test (Smoke Test)](#running-your-first-test-smoke-test)
- [API Endpoint Performance Testing](#api-endpoint-performance-testing)
- [Page Load Performance Testing](#page-load-performance-testing)
- [Concurrent User Simulation](#concurrent-user-simulation)
- [Understanding Test Results](#understanding-test-results)
- [Hands-on Exercises](#hands-on-exercises)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Submission Requirements](#submission-requirements)

---

## Introduction

### What is Performance Testing?

Performance testing is the practice of evaluating how a system performs under various conditions. It helps you understand:

- **Response times**: How fast does your application respond?
- **Throughput**: How many requests can it handle?
- **Stability**: Does it remain stable under load?
- **Scalability**: Can it handle increased traffic?

### Why k6?

k6 is a modern, open-source load testing tool designed for developers. Key benefits:

- **Developer-friendly**: Tests written in JavaScript
- **CLI-first**: Easy to integrate into development workflow
- **Accurate metrics**: Provides detailed performance insights
- **Free and open-source**: No licensing costs

### Learning Objectives

By the end of this practical, you will be able to:

1. Install and configure k6 for performance testing
2. Write k6 test scripts for different scenarios
3. Run various types of performance tests (smoke, load, spike)
4. Interpret k6 test results and identify performance issues
5. Apply performance testing best practices

---

## Prerequisites

Before starting, ensure you have:

- **Node.js and pnpm** installed on your system
- **Next.js application** running (completed Dog CEO API integration)
- **Familiarity** with Next.js, TypeScript, and basic JavaScript
- **Terminal/command line** access

---

## Installing k6

### Official Installation Guide

Follow the official k6 installation guide for your platform:
**[https://grafana.com/docs/k6/latest/set-up/install-k6/](https://grafana.com/docs/k6/latest/set-up/install-k6/)**

### Platform-Specific Instructions

#### macOS (using Homebrew)

```bash
brew install k6
```

#### Windows (using Chocolatey)

```bash
choco install k6
```

#### Linux (Debian/Ubuntu)

```bash
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

### Verification

After installation, verify k6 is installed correctly:

```bash
k6 version
```

You should see output similar to:

```
k6 v0.48.0 (2024-01-22T10:42:09+0000/v0.48.0-0-gbc6654b9, go1.21.5, darwin/arm64)
```

### K6 Desktop App

Download Link: https://grafana.com/docs/k6/latest/k6-studio/

## \*Note: Next.js has an issue with K6 Studio now. I will fix this. Use the CLI only for now

## Understanding k6 Basics

### Test Script Structure

A typical k6 test script consists of four main parts:

```javascript
// 1. Imports - Load k6 modules
import http from "k6/http";
import { check, sleep } from "k6";

// 2. Options - Configure test execution
export const options = {
  vus: 10, // Virtual Users
  duration: "30s", // Test duration
};

// 3. Setup (optional) - Runs once before the test
export function setup() {
  // Prepare test data
}

// 4. Default function - Main test logic (runs for each VU)
export default function () {
  // Your test code here
  http.get("https://test.k6.io");
  sleep(1);
}

// 5. Teardown (optional) - Runs once after the test
export function teardown(data) {
  // Cleanup
}
```

### Virtual Users (VUs)

**Virtual Users** simulate real users interacting with your application. Each VU:

- Executes the test script independently
- Runs the default function repeatedly
- Simulates concurrent traffic

Example:

```javascript
export const options = {
  vus: 10, // 10 concurrent users
  duration: "1m", // for 1 minute
};
```

### Stages and Duration

**Stages** allow you to ramp load up and down gradually:

```javascript
export const options = {
  stages: [
    { duration: "30s", target: 10 }, // Ramp up to 10 VUs over 30s
    { duration: "1m", target: 10 }, // Stay at 10 VUs for 1 minute
    { duration: "30s", target: 0 }, // Ramp down to 0 VUs
  ],
};
```

This creates a realistic traffic pattern rather than sudden spikes.

### Checks vs Thresholds

**Checks** are like assertions - they verify responses but don't stop the test:

```javascript
check(response, {
  "status is 200": (r) => r.status === 200,
  "response time < 500ms": (r) => r.timings.duration < 500,
});
```

**Thresholds** define pass/fail criteria for the entire test:

```javascript
export const options = {
  thresholds: {
    http_req_duration: ["p(95)<500"], // 95% of requests must be under 500ms
    http_req_failed: ["rate<0.1"], // Error rate must be below 10%
  },
};
```

### Key Metrics

k6 tracks several important metrics:

| Metric              | Description                                                                |
| ------------------- | -------------------------------------------------------------------------- |
| `http_req_duration` | Total time for HTTP request (includes DNS, connection, waiting, receiving) |
| `http_req_waiting`  | Time spent waiting for response from server                                |
| `http_req_failed`   | Rate of failed requests                                                    |
| `http_reqs`         | Total number of HTTP requests                                              |
| `vus`               | Number of active virtual users                                             |
| `vus_max`           | Maximum number of virtual users                                            |
| `iterations`        | Number of times the VU executes the default function                       |

**Percentiles** (p90, p95, p99) show distribution:

- **p(95)**: 95% of requests were faster than this value
- **p(99)**: 99% of requests were faster than this value

---

## Running Your First Test (Smoke Test)

### What is a Smoke Test?

A **smoke test** verifies basic functionality with minimal load (usually 1 VU). It answers:

- Does the application respond?
- Are all endpoints accessible?
- Are there any obvious errors?

Think of it as a "sanity check" before running heavier tests.

### Examining the Smoke Test Script

Let's look at `tests/k6/smoke-test.js`:

```javascript
import http from "k6/http";
import { check } from "k6";

export const options = {
  vus: 1, // Single virtual user
  duration: "30s", // Run for 30 seconds
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:3000";

export default function () {
  // Quick checks that everything works
  const endpoints = [
    { name: "Homepage", url: BASE_URL },
    { name: "Random Dog API", url: `${BASE_URL}/api/dogs` },
    { name: "Breeds API", url: `${BASE_URL}/api/dogs/breeds` },
  ];

  endpoints.forEach((endpoint) => {
    const response = http.get(endpoint.url);
    check(response, {
      [`${endpoint.name} - status is 200`]: (r) => r.status === 200,
      [`${endpoint.name} - response time < 1s`]: (r) =>
        r.timings.duration < 1000,
    });
  });
}
```

**Key Points:**

- Uses only 1 VU for minimal load
- Tests multiple endpoints in sequence
- Checks both status codes and response times
- Uses `__ENV.BASE_URL` to allow URL configuration

### Running the Smoke Test

1. **Start your Next.js application** (in a separate terminal):

   ```bash
   pnpm dev
   ```

2. **Run the smoke test**:
   ```bash
   pnpm test:k6:smoke
   ```

### Reading the Output

You'll see output like:

```
     ✓ Homepage - status is 200
     ✓ Homepage - response time < 1s
     ✓ Random Dog API - status is 200
     ✓ Random Dog API - response time < 1s
     ✓ Breeds API - status is 200
     ✓ Breeds API - response time < 1s

     checks.........................: 100.00% ✓ 180      ✗ 0
     data_received..................: 1.2 MB  40 kB/s
     data_sent......................: 18 kB   597 B/s
     http_req_blocked...............: avg=142.08µs min=1µs     med=3µs     max=5.46ms   p(90)=5µs      p(95)=7µs
     http_req_connecting............: avg=83.88µs  min=0s      med=0s      max=3.19ms   p(90)=0s       p(95)=0s
     http_req_duration..............: avg=234.07ms min=12.48ms med=198.2ms max=678.81ms p(90)=435.35ms p(95)=495.71ms
     http_req_failed................: 0.00%   ✓ 0        ✗ 90
     http_req_receiving.............: avg=171.76µs min=23µs    med=91µs    max=3.49ms   p(90)=274µs    p(95)=404.09µs
     http_req_sending...............: avg=26.32µs  min=6µs     med=19µs    max=371µs    p(90)=45µs     p(95)=56.04µs
     http_req_tls_handshaking.......: avg=0s       min=0s      med=0s      max=0s       p(90)=0s       p(95)=0s
     http_req_waiting...............: avg=233.87ms min=12.38ms med=198.07ms max=678.76ms p(90)=435.17ms p(95)=495.48ms
     http_reqs......................: 90      2.995238/s
     iteration_duration.............: avg=1.00s    min=1.00s   med=1.00s   max=1.01s    p(90)=1.00s    p(95)=1.00s
     iterations.....................: 30      0.998413/s
     vus............................: 1       min=1      max=1
     vus_max........................: 1       min=1      max=1
```

### Understanding Success Criteria

✅ **Passing Smoke Test Indicators:**

- All checks show 100%
- `http_req_failed` is 0.00%
- Response times are reasonable (<1s)

❌ **Failing Indicators:**

- Some checks fail (<100%)
- `http_req_failed` > 0%
- Extremely slow response times

---

## Running Your First Test (Smoke Test) On Grafana Cloud

### What is Grafana Cloud?

Grafana Cloud is a managed service that provides hosting for Grafana, Loki, and k6 Cloud. It allows you to run your k6 tests in the cloud, providing enhanced scalability, collaboration features, and detailed analytics.

### Setting Up Grafana Cloud for k6

1. **Create a Grafana Cloud Account**: Sign up at [Grafana Cloud](https://grafana.com/products/cloud/).
2. **Create a k6 Cloud API Key**:
   - Log in to your Grafana Cloud account and open a stack.
   - On the main menu, click Testing & synthetics -> Performance -> Settings.
   - Under Access, click Personal token. Here you can view, copy, and regenerate your personal API token.
3. Authenticate k6 on the terminal

```bash
k6 cloud login --token $TOKEN
```

4. Update the package.json to include a script for running the smoke test on Grafana Cloud

```json
"test:k6:cloud:smoke": "k6 cloud run tests/k6/smoke-test.js",

```

5. You need to configure the BASE_URL environment variable to point to your deployed application. You can do this by setting the environment variable in your terminal before running the test:
   We are doing this by port forwarding our local application to a public URL using ngrok. First, start your Next.js application locally:

```bash
pnpm dev
```

Then, in another terminal window, start ngrok to expose your local server:

```bash
ngrok http 3000
```

Retrieve the ngrok url and replace it in your test file.

Finally run 
```bash
  npm run test:k6:cloud:smoke
```

## API Endpoint Performance Testing

### Purpose

API endpoint testing evaluates how your backend APIs perform under sustained load. This test:

- Simulates realistic user traffic patterns
- Measures API response times
- Identifies performance bottlenecks
- Tracks error rates

### Examining the API Test Script

Let's look at `tests/k6/api-endpoint-test.js`:

```javascript
import http from "k6/http";
import { check, sleep } from "k6";
import { Rate } from "k6/metrics";

// Custom metric to track error rate
const errorRate = new Rate("errors");

export const options = {
  stages: [
    { duration: "30s", target: 10 }, // Ramp up to 10 users
    { duration: "1m", target: 10 }, // Stay at 10 users
    { duration: "30s", target: 0 }, // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"], // 95% of requests should be below 500ms
    errors: ["rate<0.1"], // Error rate should be below 10%
  },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:3000";

export default function () {
  // Test 1: Get random dog image
  const randomDogResponse = http.get(`${BASE_URL}/api/dogs`);
  check(randomDogResponse, {
    "random dog status is 200": (r) => r.status === 200,
    "random dog has message": (r) => JSON.parse(r.body).message !== undefined,
  }) || errorRate.add(1);

  sleep(1);

  // Test 2: Get breeds list
  const breedsResponse = http.get(`${BASE_URL}/api/dogs/breeds`);
  check(breedsResponse, {
    "breeds status is 200": (r) => r.status === 200,
    "breeds list is not empty": (r) =>
      Object.keys(JSON.parse(r.body).message).length > 0,
  }) || errorRate.add(1);

  sleep(1);

  // Test 3: Get specific breed
  const breedResponse = http.get(`${BASE_URL}/api/dogs?breed=husky`);
  check(breedResponse, {
    "specific breed status is 200": (r) => r.status === 200,
    "specific breed has message": (r) =>
      JSON.parse(r.body).message !== undefined,
  }) || errorRate.add(1);

  sleep(1);
}
```

### Load Testing Stages

The test uses three stages to simulate realistic traffic:

1. **Ramp-up (30s)**: Gradually increases from 0 to 10 VUs

   - Prevents shocking the system
   - Mimics organic traffic growth

2. **Sustained Load (1m)**: Maintains 10 VUs

   - Tests system stability under consistent load
   - Identifies memory leaks or degradation

3. **Ramp-down (30s)**: Decreases from 10 to 0 VUs
   - Allows graceful shutdown
   - Checks recovery behavior

### Custom Metrics

The script creates a custom metric `errorRate`:

```javascript
const errorRate = new Rate("errors");
```

This tracks failed checks:

```javascript
check(...) || errorRate.add(1);
```

If the check fails, it adds 1 to the error rate.

### Running the API Test

```bash
pnpm test:k6:api
```

### Interpreting Results

Look for these key indicators:

**Good Performance:**

```
✓ http_req_duration..............: p(95)=245.23ms  (threshold < 500ms)
✓ errors.........................: 0.00%           (threshold < 10%)
✓ http_req_failed................: 0.00%
```

**Performance Issues:**

```
✗ http_req_duration..............: p(95)=1245.23ms (threshold < 500ms)
✗ errors.........................: 15.23%          (threshold < 10%)
```

**What to watch:**

- **p(95) response time**: Should be under 500ms
- **Error rate**: Should be under 10%
- **Failed requests**: Should be 0%

---

## Page Load Performance Testing

### Purpose

Page load testing measures how quickly users can access your web pages. This is crucial for:

- User experience
- SEO rankings
- Conversion rates

### Examining the Page Load Test Script

`tests/k6/page-load-test.js`:

```javascript
import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  stages: [
    { duration: "1m", target: 20 }, // Ramp up to 20 users
    { duration: "2m", target: 20 }, // Stay at 20 users
    { duration: "1m", target: 0 }, // Ramp down
  ],
  thresholds: {
    http_req_duration: ["p(99)<2000"], // 99% of requests under 2s
  },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:3000";

export default function () {
  // Load the main page
  const response = http.get(BASE_URL);

  check(response, {
    "homepage status is 200": (r) => r.status === 200,
    "homepage loads quickly": (r) => r.timings.duration < 2000,
    "homepage contains title": (r) => r.body.includes("Dog Image Browser"),
  });

  sleep(2);
}
```

### Percentile Metrics (p99)

The threshold uses `p(99)<2000`:

- **p(99)**: 99% of page loads must be under 2 seconds
- This allows for occasional slower loads
- More lenient than p(95) due to page complexity

### Why 2 seconds?

Research shows:

- **< 1 second**: Excellent, no noticeable delay
- **1-2 seconds**: Good, minimal interruption
- **2-3 seconds**: Average, users start to notice
- **> 3 seconds**: Poor, users may abandon

### Running the Page Load Test

```bash
pnpm test:k6:page
```

### What Good Performance Looks Like

```
✓ http_req_duration..............: avg=456.23ms  p(99)=1845.12ms
✓ homepage status is 200.........: 100.00%
✓ homepage loads quickly.........: 99.80%
✓ homepage contains title........: 100.00%
```

**Indicators:**

- p(99) well under 2000ms
- All checks passing
- Consistent average response time

---

## Concurrent User Simulation

### Purpose

Concurrent user simulation tests how your application handles:

- **Multiple simultaneous users** (realistic traffic)
- **Traffic spikes** (sudden increases in load)
- **Different usage patterns** (varied user behavior)

### Examining the Concurrent Users Test Script

`tests/k6/concurrent-users-test.js`:

```javascript
import http from "k6/http";
import { check, sleep } from "k6";
import { Counter } from "k6/metrics";

const totalRequests = new Counter("total_requests");

export const options = {
  scenarios: {
    light_load: {
      executor: "constant-vus",
      vus: 10,
      duration: "1m",
    },
    spike_test: {
      executor: "ramping-vus",
      startVUs: 0,
      stages: [
        { duration: "10s", target: 50 }, // Spike to 50 users
        { duration: "30s", target: 50 }, // Stay at 50
        { duration: "10s", target: 0 }, // Drop back
      ],
      startTime: "1m",
    },
  },
  thresholds: {
    http_req_duration: ["p(90)<1000"], // 90% under 1s
    http_req_failed: ["rate<0.05"], // Less than 5% errors
  },
};
```

### Scenarios Explained

**Scenario 1: Light Load (0-1 minute)**

- **Executor**: `constant-vus` (constant virtual users)
- **VUs**: 10 users
- **Duration**: 1 minute
- **Purpose**: Baseline performance measurement

**Scenario 2: Spike Test (1-2.8 minutes)**

- **Executor**: `ramping-vus` (ramping virtual users)
- **Peak**: 50 users
- **Purpose**: Test system resilience during traffic spikes

**startTime**: Delays spike test by 1 minute, running after light load.

### Realistic User Behavior Simulation

The test simulates actual user flow:

```javascript
export default function () {
  // 1. Load homepage
  let response = http.get(BASE_URL);
  check(response, { "homepage loaded": (r) => r.status === 200 });
  totalRequests.add(1);
  sleep(2);

  // 2. Fetch breeds
  response = http.get(`${BASE_URL}/api/dogs/breeds`);
  check(response, { "breeds loaded": (r) => r.status === 200 });
  totalRequests.add(1);
  sleep(1);

  // 3. Get random dog (simulating button click)
  response = http.get(`${BASE_URL}/api/dogs`);
  check(response, { "random dog loaded": (r) => r.status === 200 });
  totalRequests.add(1);
  sleep(3);

  // 4. Get specific breed (simulating breed selection)
  const breeds = ["husky", "corgi", "retriever", "bulldog", "poodle"];
  const randomBreed = breeds[Math.floor(Math.random() * breeds.length)];
  response = http.get(`${BASE_URL}/api/dogs?breed=${randomBreed}`);
  check(response, { "specific breed loaded": (r) => r.status === 200 });
  totalRequests.add(1);
  sleep(2);
}
```

**User Journey:**

1. Visit homepage → wait 2s
2. Load breeds list → wait 1s
3. Click "Get Random Dog" → wait 3s (looking at image)
4. Select breed and get dog → wait 2s

This mimics real user behavior with realistic think times.

### Running the Concurrent Users Test

```bash
pnpm test:k6:concurrent
```

### Analyzing User Flow Performance

Watch for:

**During Light Load (10 VUs):**

```
http_req_duration..............: avg=245ms  p(90)=456ms
http_req_failed................: 0.00%
```

**During Spike (50 VUs):**

```
http_req_duration..............: avg=678ms  p(90)=985ms
http_req_failed................: 1.2%
```

**Good Performance:**

- p(90) stays under 1000ms even during spike
- Error rate remains under 5%
- System recovers after spike

**Performance Issues:**

- p(90) exceeds 1000ms
- Error rate > 5%
- System doesn't recover

---

## Understanding Test Results

### Key Metrics Breakdown

When k6 finishes a test, it displays comprehensive metrics. Let's understand each:

#### Request Metrics

**`http_req_duration`**

- **What**: Total time from request start to response received
- **Includes**: DNS lookup + connection + waiting + receiving data
- **Good values**:
  - API calls: < 500ms
  - Page loads: < 2000ms

**`http_req_waiting`**

- **What**: Time spent waiting for server response (Time to First Byte)
- **Indicates**: Server processing speed
- **Good values**: < 200ms for APIs

**`http_req_blocked`**

- **What**: Time spent waiting for available TCP connection
- **High values indicate**: Connection pool exhaustion

**`http_req_connecting`**

- **What**: Time spent establishing TCP connection
- **High values indicate**: Network issues or server limits

#### Success Metrics

**`http_req_failed`**

- **What**: Percentage of failed HTTP requests
- **Target**: < 1% for production systems
- **Causes**: Server errors, timeouts, network issues

**`checks`**

- **What**: Percentage of successful checks
- **Target**: 100% for critical checks
- **Example**: `✓ checks: 95.00% ✓ 95 ✗ 5`

#### Load Metrics

**`http_reqs`**

- **What**: Total number of HTTP requests made
- **Used for**: Understanding throughput

**`iterations`**

- **What**: Number of times VUs completed the default function
- **Used for**: Measuring completed user journeys

**`vus`**

- **What**: Number of active virtual users
- **Shows**: Current load level

### Response Time Percentiles

Understanding percentiles is crucial:

| Percentile | Meaning                  | Use Case                      |
| ---------- | ------------------------ | ----------------------------- |
| **avg**    | Average response time    | General performance indicator |
| **min**    | Fastest response         | Best-case scenario            |
| **med**    | Median (50th percentile) | Typical user experience       |
| **max**    | Slowest response         | Worst-case scenario           |
| **p(90)**  | 90% of requests faster   | Good performance benchmark    |
| **p(95)**  | 95% of requests faster   | Performance SLA target        |
| **p(99)**  | 99% of requests faster   | Outlier detection             |

**Example:**

```
http_req_duration: avg=245ms min=120ms med=230ms max=1540ms p(90)=385ms p(95)=445ms p(99)=892ms
```

**Interpretation:**

- **Average user** experiences 245ms response
- **90% of users** wait less than 385ms
- **5% of users** experience 445-892ms
- **1% of users** experience very slow 892-1540ms responses

### Checks vs Thresholds

**Checks** (non-blocking):

```javascript
check(response, {
  "status is 200": (r) => r.status === 200,
});
```

- Verify conditions during test
- Don't stop test if they fail
- Shown as percentages in results

**Thresholds** (blocking):

```javascript
thresholds: {
  http_req_duration: ['p(95)<500'],
}
```

- Define pass/fail criteria
- Can abort test if breached
- Determine overall test success

**Result Display:**

```
✓ http_req_duration..............: p(95)=445ms   (threshold < 500ms) ← PASS
✗ http_req_failed................: 12.5%         (threshold < 10%)   ← FAIL
```

### When to Be Concerned

🚨 **Red Flags:**

1. **High Error Rates**

   ```
   http_req_failed................: 15.23%
   ```

   - **Concern**: More than 1-2% failures
   - **Causes**: Server errors, timeouts, bugs
   - **Action**: Check server logs, investigate errors

2. **Slow Response Times**

   ```
   http_req_duration..............: p(95)=3456ms
   ```

   - **Concern**: p(95) or p(99) exceed thresholds
   - **Causes**: Database queries, external APIs, inefficient code
   - **Action**: Profile application, optimize bottlenecks

3. **Increasing Response Times**

   ```
   Start: avg=245ms → Middle: avg=567ms → End: avg=1234ms
   ```

   - **Concern**: Performance degrades over time
   - **Causes**: Memory leaks, resource exhaustion
   - **Action**: Monitor memory usage, check for leaks

4. **Failed Checks**

   ```
   ✗ checks: 76.23% ✓ 76 ✗ 24
   ```

   - **Concern**: Less than 95% passing
   - **Causes**: Application logic errors, data issues
   - **Action**: Review failed check details

5. **Connection Issues**
   ```
   http_req_blocked...............: avg=1256ms
   http_req_connecting............: avg=897ms
   ```
   - **Concern**: High connection times
   - **Causes**: Connection pool limits, network issues
   - **Action**: Increase connection limits, check network

---

## Hands-on Exercises

Complete these exercises to deepen your understanding of k6.

### Exercise 1: Modify VU Count and Observe Differences

**Goal**: Understand how load affects performance.

**Steps:**

1. Open `tests/k6/api-endpoint-test.js`
2. Modify the stages to increase VUs:
   ```javascript
   stages: [
     { duration: '30s', target: 50 },  // Changed from 10 to 50
     { duration: '1m', target: 50 },
     { duration: '30s', target: 0 },
   ],
   ```
3. Run the test: `pnpm test:k6:api`
4. Compare results with original 10 VU test

**Questions to Ask yourself:**

- How did p(95) response time change?
- Did any requests fail?
- What was the maximum response time?
- Did the system remain stable?

**Expected Outcome:**

- Higher VUs = Higher response times
- Possible increase in error rates
- System may approach limits

---

### Exercise 2: Change Thresholds and Make Test Fail

**Goal**: Understand how thresholds work and how to set realistic targets.

**Steps:**

1. Open `tests/k6/page-load-test.js`
2. Make the threshold very strict:
   ```javascript
   thresholds: {
     http_req_duration: ['p(99)<100'],  // Changed from 2000ms to 100ms
   },
   ```
3. Run the test: `pnpm test:k6:page`
4. Observe the failure

**Expected Output:**

```
✗ http_req_duration..............: p(99)=1245.23ms (threshold < 100ms) FAILED
```

**Questions to ASK YOURSELF:**

- Why did the threshold fail?
- What is a realistic threshold for your application?
- How would you improve performance to meet stricter thresholds?

**Next Steps:**

- Gradually adjust threshold until test passes
- Document your application's realistic performance limits

---

### Exercise 3: Add New Endpoint to Test

**Goal**: Extend test coverage to new endpoints.

**Steps:**

1. Open `tests/k6/smoke-test.js`
2. Add a new endpoint for a specific breed:
   ```javascript
   const endpoints = [
     { name: "Homepage", url: BASE_URL },
     { name: "Random Dog API", url: `${BASE_URL}/api/dogs` },
     { name: "Breeds API", url: `${BASE_URL}/api/dogs/breeds` },
     // Add this:
     { name: "Husky API", url: `${BASE_URL}/api/dogs?breed=husky` },
   ];
   ```
3. Run the test: `pnpm test:k6:smoke`

**Expected Outcome:**

- Test now validates 4 endpoints instead of 3
- All checks should pass
- More comprehensive coverage

**Challenge:**
Add checks to verify:

- Response body contains "husky" in the URL
- Response has correct data structure

---

### Exercise 4: Create Custom Metrics

**Goal**: Track application-specific metrics.

**Steps:**

1. Create a new file `tests/k6/custom-metrics-test.js`
2. Implement custom metrics:

   ```javascript
   import http from "k6/http";
   import { check } from "k6";
   import { Trend, Counter } from "k6/metrics";

   // Custom metrics
   const dogFetchTime = new Trend("dog_fetch_duration");
   const breedsFetchTime = new Trend("breeds_fetch_duration");
   const totalDogsFetched = new Counter("total_dogs_fetched");

   export const options = {
     vus: 5,
     duration: "30s",
   };

   const BASE_URL = __ENV.BASE_URL || "http://localhost:3000";

   export default function () {
     // Fetch and measure breeds endpoint
     let start = new Date().getTime();
     let response = http.get(`${BASE_URL}/api/dogs/breeds`);
     let duration = new Date().getTime() - start;
     breedsFetchTime.add(duration);

     // Fetch and measure dog image endpoint
     start = new Date().getTime();
     response = http.get(`${BASE_URL}/api/dogs`);
     duration = new Date().getTime() - start;
     dogFetchTime.add(duration);

     if (response.status === 200) {
       totalDogsFetched.add(1);
     }
   }
   ```

3. Run: `k6 run tests/k6/custom-metrics-test.js`

**Expected Output:**

```
dog_fetch_duration.............: avg=234.56ms min=123ms max=456ms
breeds_fetch_duration..........: avg=156.78ms min=98ms max=287ms
total_dogs_fetched.............: 150
```

**Questions to ASK YOURSELF:**

- Which endpoint is faster on average?
- How many total dogs were successfully fetched?
- What other metrics would be useful to track?

---

## Best Practices

Follow these best practices for effective performance testing:

### 1. Start with Smoke Tests

Always begin with smoke tests before load testing:

```bash
# First: Verify basic functionality
pnpm test:k6:smoke

# Then: Run load tests
pnpm test:k6:api
```

**Why?**

- Catches configuration errors early
- Verifies endpoints are accessible
- Prevents wasting time on broken tests

---

### 2. Gradually Increase Load

Don't jump straight to high VU counts. Ramp up progressively:

**Good Approach:**

```javascript
stages: [
  { duration: '1m', target: 10 },   // Test with 10 VUs first
  { duration: '2m', target: 10 },
  { duration: '1m', target: 0 },
],
```

Then increase:

```javascript
stages: [
  { duration: '1m', target: 20 },   // Then try 20 VUs
  { duration: '2m', target: 20 },
  { duration: '1m', target: 0 },
],
```

**Why?**

- Identifies breaking points
- Prevents overwhelming systems
- Provides incremental data points

---

### 3. Test Realistic Scenarios

Model actual user behavior:

**Bad:**

```javascript
export default function () {
  http.get(`${BASE_URL}/api/dogs`);
  // No sleep - unrealistic
}
```

**Good:**

```javascript
export default function () {
  http.get(`${BASE_URL}/api/dogs`);
  sleep(3); // User views image for 3 seconds
}
```

**Why?**

- Simulates real user think time
- Prevents artificial traffic patterns
- Provides accurate performance data

---

### 4. Monitor Both Response Time and Error Rate

Don't focus only on speed:

```javascript
thresholds: {
  http_req_duration: ['p(95)<500'],  // Speed
  http_req_failed: ['rate<0.01'],    // Reliability
},
```

**Why?**

- Fast but failing responses are useless
- A slow but stable system may be acceptable
- Both metrics together show true health

---

### 5. Use Appropriate Sleep Times

Balance realism with test efficiency:

**Page Navigation:**

```javascript
http.get(BASE_URL);
sleep(2); // User reads page
```

**API Calls:**

```javascript
http.get(`${BASE_URL}/api/dogs`);
sleep(1); // Brief pause between actions
```

**Image Viewing:**

```javascript
http.get(`${BASE_URL}/api/dogs`);
sleep(5); // User enjoys the dog photo
```

**Why?**

- Too short: Unrealistic hammering
- Too long: Test takes forever
- Just right: Balanced simulation

---

### 6. Document Your Baseline

Record initial performance metrics:

```markdown
## Baseline Performance (No Load)

- Homepage: p(95) = 245ms
- API /dogs: p(95) = 156ms
- API /breeds: p(95) = 134ms

## Performance at 10 VUs

- Homepage: p(95) = 456ms
- API /dogs: p(95) = 298ms
- API /breeds: p(95) = 267ms
```

**Why?**

- Tracks performance over time
- Identifies regressions
- Sets realistic thresholds

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: "k6: command not found"

**Symptom:**

```bash
pnpm test:k6:smoke
> k6 run tests/k6/smoke-test.js
sh: k6: command not found
```

**Solution:**

1. Verify k6 installation:
   ```bash
   k6 version
   ```
2. If not installed, follow [Installing k6](#installing-k6)
3. Restart terminal after installation

---

#### Issue 2: App Must Be Running Before Tests

**Symptom:**

```
✗ Homepage - status is 200
✗ Random Dog API - status is 200
http_req_failed................: 100.00%
```

**Solution:**

1. Start your Next.js dev server in a separate terminal:
   ```bash
   pnpm dev
   ```
2. Wait for "Ready on http://localhost:3000"
3. Then run k6 tests

**Tip:** Keep dev server running in one terminal, run tests in another.

---

#### Issue 3: Port Conflicts

**Symptom:**

```
Error: listen EADDRINUSE: address already in use :::3000
```

**Solution:**

**Option 1:** Kill the process using port 3000:

```bash
# macOS/Linux
lsof -ti:3000 | xargs kill -9

# Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F
```

**Option 2:** Use a different port:

```bash
PORT=3001 pnpm dev
```

Then update k6 tests:

```bash
BASE_URL=http://localhost:3001 k6 run tests/k6/smoke-test.js
```

---

#### Issue 4: Timeout Issues

**Symptom:**

```
http_req_duration..............: avg=30.12s
http_req_failed................: 45.23%
```

**Possible Causes:**

1. **External API slow**: Dog CEO API may be experiencing issues
2. **Network problems**: Internet connection unstable
3. **Server overload**: Too many VUs for local machine

**Solutions:**

**1. Reduce VU count:**

```javascript
stages: [
  { duration: '30s', target: 5 },  // Reduced from 10
],
```

**2. Increase timeout (if needed):**

```javascript
export const options = {
  thresholds: {
    http_req_duration: ["p(95)<5000"], // Increased from 500ms
  },
};
```

**3. Check external API status:**

- Visit https://dog.ceo/ in browser
- Verify API responds

---

#### Issue 5: TypeError: Cannot read property 'message'

**Symptom:**

```
TypeError: Cannot read property 'message' of undefined
```

**Solution:**

Add error handling to checks:

```javascript
check(response, {
  "status is 200": (r) => r.status === 200,
  "has message": (r) => {
    try {
      const data = JSON.parse(r.body);
      return data.message !== undefined;
    } catch (e) {
      console.error("JSON parse error:", e);
      return false;
    }
  },
});
```

---

## Submission Requirements

### Part 1: Implementation

Navigate to this link: https://grafana.com/load-testing/types-of-load-testing/

Smoke Test was already done and demo-ed in class.

Complete the following test scenarios for the sample dog api app. 
1. Average-load
2. Spike-load
3. Stress
4. Soak

**You are to clearly define your test criterias in the options.**

You are complete these 4 scenarios using k6 locally and k6 cloud.
Ensure to submit screenshot of terminal for local; and screenshot of grafana UI for cloud-based.

Submit your complete Next.js application with Dog CEO API integration.

**Required Files:**
- The sample app provided
- `tests/k6/*.js` - All k6 test scripts

**Verification:**

- Application runs: `pnpm dev`
- Application builds: `pnpm build`
- Linting passes: `pnpm lint`
- All features work as expected

---

### Part 2: Test Report

Submit a comprehensive performance testing report.

**Required Sections:**

#### 1. Test Results Screenshots
1. Average-load (any duration)
2. Spike-load (1min) **ensure extremly high VUs** However high your laptop can support.
3. Stress (5mins)
4. Soak (30mins)

You are complete these 4 scenarios using k6 locally and k6 cloud.
Ensure to submit screenshot of terminal for local; and screenshot of grafana UI for cloud-based.

---

#### 2. Test Criterias

Propose test criterias in the README.md:

**Example Metrics:**

- Duration
- Expected Response Times
- Throughput
- Error Rates

---

### Submission Format

**Structure:**
```

practical7\_[StudentID]/
├── performance-testing/ # Full Next.js app
│ ├── src/
│ ├── tests/
│ ├── package.json
│ └── ...
└── REPORT.md # Performance test report
└── screenshots/
├── spike-test.png
├── stress-test.png
├── soak-test.png
└── <others>.png

```

---

## Conclusion

Congratulations! You've learned the fundamentals of performance testing with k6:

✅ Installed and configured k6
✅ Written various types of performance tests
✅ Executed tests and interpreted results
✅ Identified performance bottlenecks
✅ Applied best practices

### Next Steps

To further your performance testing knowledge:

1. **Explore k6 Cloud** - Grafana's cloud platform for distributed testing
2. **Learn Advanced Features** - Custom executors, scenarios, thresholds
3. **Integrate with CI/CD** - Automate performance testing in pipelines
4. **Study Real-World Cases** - Analyze production performance testing strategies
5. **Practice Continuously** - Test every application you build

### Resources

- **k6 Documentation**: https://k6.io/docs/
- **k6 Examples**: https://k6.io/docs/examples/
- **Grafana Community**: https://community.grafana.com/c/grafana-k6/
- **Performance Testing Guide**: https://k6.io/docs/testing-guides/

Happy testing! 🚀
```
