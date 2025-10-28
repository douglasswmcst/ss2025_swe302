# Practical 8: GUI Testing with Cypress

## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Installing Cypress](#installing-cypress)
- [Understanding Cypress Basics](#understanding-cypress-basics)
- [Setting Up Cypress for Next.js](#setting-up-cypress-for-nextjs)
- [Writing Your First Test](#writing-your-first-test)
- [Testing User Interactions](#testing-user-interactions)
- [Testing API Integration](#testing-api-integration)
- [Advanced Cypress Features](#advanced-cypress-features)
- [Best Practices](#best-practices)
- [Hands-on Exercises](#hands-on-exercises)
- [Troubleshooting](#troubleshooting)
- [Submission Requirements](#submission-requirements)

---

## Introduction

### What is GUI Testing?

GUI (Graphical User Interface) testing is the practice of testing an application's user interface to ensure it works as expected from a user's perspective. GUI testing helps you verify:

- **User interactions**: Do buttons, forms, and inputs work correctly?
- **Visual rendering**: Does the UI display correctly?
- **User flows**: Can users complete common tasks?
- **Cross-browser compatibility**: Does the app work across different browsers?

### Why Cypress?

Cypress is a modern, end-to-end testing framework designed for web applications. Key benefits:

- **Developer-friendly**: Tests written in JavaScript
- **Real-time reloading**: See tests run as you write them
- **Time travel**: Debug by seeing what happened at each step
- **Automatic waiting**: No need for manual sleep/wait commands
- **Screenshots & videos**: Automatically capture test failures
- **Network stubbing**: Mock API responses easily

### Learning Objectives

By the end of this practical, you will be able to:

1. Install and configure Cypress for a Next.js application
2. Write comprehensive GUI tests for different UI components
3. Test user interactions and workflows
4. Mock API responses and test error states
5. Run tests in both interactive and headless modes
6. Apply GUI testing best practices

---

## Prerequisites

Before starting, ensure you have:

- **Node.js and pnpm** installed on your system
- **Next.js application** running (practical7-example Dog CEO API integration)
- **Familiarity** with Next.js, TypeScript, and basic JavaScript
- **Terminal/command line** access
- **Completed Practical 7** (Performance Testing with k6)

---

## Installing Cypress

### Installation Steps

Navigate to your practical8-example application directory:

```bash
cd practicals/practical8-example/gui-testing
```

### Install Cypress as a dev dependency

```bash
pnpm add -D cypress
```

### Verify Installation

```bash
pnpm exec cypress --version
```

You should see output similar to:

```
Cypress package version: 15.5.0
Cypress binary version: 15.5.0
```

### Open Cypress for the First Time

```bash
pnpm exec cypress open
```

This will:
1. Launch the Cypress Test Runner
2. Create a `cypress` folder with example tests
3. Create a `cypress.config.ts` file

When the Cypress window opens:
1. Select **"E2E Testing"**
2. Choose your preferred browser (Chrome recommended)
3. Click **"Create new spec"** to see how it works
4. Close Cypress for now - we'll configure it properly

### Understanding the Generated Structure

After running Cypress, you'll see a new folder structure:

```
gui-testing/
├── cypress/
│   ├── e2e/              # Your test files go here
│   ├── fixtures/         # Test data files
│   ├── support/          # Custom commands and global config
│   │   ├── commands.ts   # Custom Cypress commands
│   │   └── e2e.ts        # Runs before every test file
├── cypress.config.ts     # Cypress configuration
```

---

## Understanding Cypress Basics

### Test Structure

A typical Cypress test follows this structure:

```javascript
describe('Test Suite Name', () => {
  // Runs once before all tests in this block
  before(() => {
    // Setup code
  });

  // Runs before each test
  beforeEach(() => {
    // Common setup for each test
    cy.visit('http://localhost:3000');
  });

  // Individual test case
  it('should do something specific', () => {
    // Test code
    cy.get('button').click();
    cy.contains('Success!').should('be.visible');
  });

  // Runs after each test
  afterEach(() => {
    // Cleanup code
  });

  // Runs once after all tests
  after(() => {
    // Final cleanup
  });
});
```

### Key Concepts

#### 1. Commands

Cypress commands are chainable actions that interact with your application:

```javascript
cy.visit('/');              // Navigate to a page
cy.get('.button');          // Select an element
cy.contains('Click me');    // Find element by text
cy.click();                 // Perform action
cy.type('Hello');           // Type into input
```

#### 2. Assertions

Assertions verify that your application is in the expected state:

```javascript
// Should assertions (most common)
cy.get('.title').should('be.visible');
cy.get('.title').should('have.text', 'Welcome');
cy.get('.title').should('have.class', 'active');

// Expect assertions (BDD style)
cy.get('.title').then($el => {
  expect($el).to.be.visible;
  expect($el.text()).to.equal('Welcome');
});
```

#### 3. Automatic Waiting

Cypress automatically waits for elements and actions:

```javascript
// ❌ NOT needed in Cypress (unlike other tools)
cy.wait(1000);

// ✅ Cypress waits automatically
cy.get('.loading').should('not.exist');  // Waits up to 4s
cy.get('.content').should('be.visible'); // Waits until visible
```

#### 4. Querying Elements

Different ways to select elements:

```javascript
// By CSS selector
cy.get('.class-name');
cy.get('#id');
cy.get('[data-testid="submit-btn"]');  // Best practice!

// By text content
cy.contains('Click me');
cy.contains('button', 'Submit');

// By position
cy.get('li').first();
cy.get('li').last();
cy.get('li').eq(2);  // Third item (0-indexed)

// Filtering
cy.get('li').filter('.active');
cy.get('button').not('.disabled');
```

#### 5. Command Chaining

Commands can be chained together:

```javascript
cy.get('.dropdown')
  .click()
  .find('.option')
  .first()
  .click();

cy.get('input')
  .type('test@example.com')
  .should('have.value', 'test@example.com');
```

### Cypress vs Selenium

| Feature | Cypress | Selenium |
|---------|---------|----------|
| **Architecture** | Runs inside browser | External driver |
| **Setup** | Simple, npm install | Complex, multiple dependencies |
| **Waiting** | Automatic | Manual waits needed |
| **Debugging** | Time-travel, real-time reload | Traditional debugging |
| **Speed** | Faster | Slower |
| **Language** | JavaScript/TypeScript only | Multiple languages |
| **Browser Support** | Chrome, Firefox, Edge, Electron | All browsers including Safari |

---

## Setting Up Cypress for Next.js

### 1. Configure Cypress

Update `cypress.config.ts`:

```typescript
import { defineConfig } from "cypress";

export default defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    setupNodeEvents() {
      // implement node event listeners here
    },
    specPattern: 'cypress/e2e/**/*.cy.{js,jsx,ts,tsx}',
    supportFile: 'cypress/support/e2e.ts',
    viewportWidth: 1280,
    viewportHeight: 720,
    video: true,
    screenshotOnRunFailure: true,
    defaultCommandTimeout: 10000,
  },
});
```

**Note:** We removed the unused `on` and `config` parameters from `setupNodeEvents()` to avoid linting warnings.

**Configuration Explained:**

- `baseUrl`: Your app's URL - all `cy.visit()` calls are relative to this
- `specPattern`: Where Cypress looks for test files
- `viewportWidth/Height`: Browser window size for tests
- `video`: Record videos of test runs
- `screenshotOnRunFailure`: Capture screenshots when tests fail
- `defaultCommandTimeout`: How long to wait for commands (10 seconds)

### 2. Add TypeScript Support

Create `cypress/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM"],
    "types": ["cypress", "node"],
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "esModuleInterop": true,
    "strict": true,
    "skipLibCheck": true
  },
  "include": [
    "**/*.ts",
    "**/*.tsx"
  ]
}
```

### 3. Add npm Scripts

Update `package.json` to add Cypress commands:

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint",
    "test:k6:smoke": "k6 run tests/k6/smoke-test.js",
    "test:k6:api": "k6 run tests/k6/api-endpoint-test.js",
    "test:k6:page": "k6 run tests/k6/page-load-test.js",
    "test:k6:concurrent": "k6 run tests/k6/concurrent-users-test.js",
    "cypress:open": "cypress open",
    "cypress:run": "cypress run",
    "test:e2e": "start-server-and-test dev http://localhost:3000 cypress:run",
    "test:e2e:open": "start-server-and-test dev http://localhost:3000 cypress:open"
  }
}
```

### 4. Install Additional Dependencies

Install the helper package to start the dev server before tests:

```bash
pnpm add -D start-server-and-test
```

**Script Explanation:**

- `cypress:open`: Opens Cypress Test Runner (interactive mode)
- `cypress:run`: Runs tests headlessly (CI mode)
- `test:e2e`: Starts dev server, waits for it, then runs tests
- `test:e2e:open`: Same but opens interactive mode

### 5. Clean Up Example Files

Cypress creates example tests. Remove them:

```bash
rm -rf cypress/e2e/1-getting-started cypress/e2e/2-advanced-examples
```

Or keep them for reference - they contain useful examples!

### 6. Add Test Data Attributes

**Best Practice**: Use `data-testid` attributes for reliable element selection.

This is important because:
- Class names might change with styling updates
- IDs might be dynamic
- Text content might change or be translated

We'll add these attributes to our Next.js components in the next section.

---

## Writing Your First Test

### Step 1: Update Components with Test IDs

First, let's add test IDs to our main page component for reliable testing.

Update `src/app/page.tsx`:

```tsx
'use client';

import { useState, useEffect } from 'react';
import Image from 'next/image';

interface DogApiResponse {
  message: string | string[];
  status: string;
}

interface BreedsResponse {
  message: Record<string, string[]>;
  status: string;
}

export default function Home() {
  const [dogImage, setDogImage] = useState<string>('');
  const [breeds, setBreeds] = useState<string[]>([]);
  const [selectedBreed, setSelectedBreed] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string>('');

  useEffect(() => {
    fetchBreeds();
  }, []);

  const fetchBreeds = async () => {
    try {
      const response = await fetch('/api/dogs/breeds');
      const data: BreedsResponse = await response.json();
      if (data.status === 'success') {
        const breedList = Object.keys(data.message);
        setBreeds(breedList);
      }
    } catch {
      setError('Failed to load breeds');
    }
  };

  const fetchRandomDog = async () => {
    setLoading(true);
    setError('');
    try {
      const url = selectedBreed
        ? `/api/dogs?breed=${selectedBreed}`
        : '/api/dogs';
      const response = await fetch(url);

      if (!response.ok) {
        throw new Error('Failed to fetch');
      }

      const data: DogApiResponse = await response.json();

      if (data.status === 'success') {
        const imageUrl = Array.isArray(data.message)
          ? data.message[0]
          : data.message;
        setDogImage(imageUrl);
      } else {
        setError('Failed to load dog image');
      }
    } catch {
      setError('Failed to load dog image');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800 py-12 px-4">
      <main className="max-w-4xl mx-auto">
        <div className="text-center mb-8">
          <h1
            data-testid="page-title"
            className="text-4xl font-bold text-gray-900 dark:text-white mb-2"
          >
            Dog Image Browser
          </h1>
          <p
            data-testid="page-subtitle"
            className="text-gray-600 dark:text-gray-300"
          >
            Powered by Dog CEO API
          </p>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-xl p-6 mb-6">
          <div className="flex flex-col sm:flex-row gap-4 mb-6">
            <select
              data-testid="breed-selector"
              value={selectedBreed}
              onChange={(e) => setSelectedBreed(e.target.value)}
              className="flex-1 px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
            >
              <option value="">All Breeds (Random)</option>
              {breeds.map((breed) => (
                <option key={breed} value={breed}>
                  {breed.charAt(0).toUpperCase() + breed.slice(1)}
                </option>
              ))}
            </select>
            <button
              data-testid="fetch-dog-button"
              onClick={fetchRandomDog}
              disabled={loading}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors font-medium"
            >
              {loading ? 'Loading...' : 'Get Random Dog'}
            </button>
          </div>

          {error && (
            <div
              data-testid="error-message"
              className="mb-4 p-4 bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-200 rounded-lg"
            >
              {error}
            </div>
          )}

          {dogImage && (
            <div
              data-testid="dog-image-container"
              className="relative w-full aspect-square max-w-2xl mx-auto rounded-lg overflow-hidden bg-gray-100 dark:bg-gray-700"
            >
              <Image
                data-testid="dog-image"
                src={dogImage}
                alt="Random dog"
                fill
                className="object-cover"
                sizes="(max-width: 768px) 100vw, 672px"
                priority
              />
            </div>
          )}

          {!dogImage && !loading && (
            <div
              data-testid="placeholder-message"
              className="text-center py-20 text-gray-500 dark:text-gray-400"
            >
              Click &quot;Get Random Dog&quot; to see a cute dog!
            </div>
          )}
        </div>

        <div className="text-center text-sm text-gray-600 dark:text-gray-400">
          <p>Practice GUI testing with Cypress</p>
        </div>
      </main>
    </div>
  );
}
```

**What Changed:**

- Added `data-testid` attributes to key elements:
  - `page-title`: Main heading
  - `page-subtitle`: Subtitle
  - `breed-selector`: Dropdown for breed selection
  - `fetch-dog-button`: Button to fetch dog images
  - `error-message`: Error display
  - `dog-image-container`: Image wrapper
  - `dog-image`: The actual image
  - `placeholder-message`: Initial message before loading

### Step 2: Create Your First Test

Create `cypress/e2e/homepage.cy.ts`:

```typescript
describe('Dog Image Browser - Homepage', () => {
  beforeEach(() => {
    // Visit homepage before each test
    cy.visit('/');
  });

  it('should display the page title and subtitle', () => {
    // Check that title exists and has correct text
    cy.get('[data-testid="page-title"]')
      .should('be.visible')
      .and('contain.text', 'Dog Image Browser');

    // Check that subtitle exists
    cy.get('[data-testid="page-subtitle"]')
      .should('be.visible')
      .and('contain.text', 'Powered by Dog CEO API');
  });

  it('should display the breed selector and fetch button', () => {
    // Check breed selector exists
    cy.get('[data-testid="breed-selector"]')
      .should('be.visible')
      .and('not.be.disabled');

    // Check button exists
    cy.get('[data-testid="fetch-dog-button"]')
      .should('be.visible')
      .and('contain.text', 'Get Random Dog')
      .and('not.be.disabled');
  });

  it('should display placeholder message initially', () => {
    cy.get('[data-testid="placeholder-message"]')
      .should('be.visible')
      .and('contain.text', 'Click "Get Random Dog" to see a cute dog!');
  });

  it('should not display dog image initially', () => {
    cy.get('[data-testid="dog-image-container"]')
      .should('not.exist');
  });

  it('should not display error message initially', () => {
    cy.get('[data-testid="error-message"]')
      .should('not.exist');
  });
});
```

### Step 3: Run Your First Test

**Option 1: Interactive Mode (Recommended for development)**

```bash
# Start your Next.js app
pnpm dev

# In another terminal, open Cypress
pnpm cypress:open
```

1. Click on `homepage.cy.ts` in the Test Runner
2. Watch tests run in real-time
3. Use time-travel to debug
4. See automatic retries

**Option 2: Headless Mode (For CI/CD)**

```bash
# This starts the dev server and runs tests automatically
pnpm test:e2e
```

### Understanding Test Output

**Interactive Mode:**

- ✅ Green checkmarks = Passing tests
- ❌ Red X = Failing tests
- Click on any command to see DOM snapshot at that moment
- Hover over commands to see element highlights
- Use the selector playground to find selectors

**Headless Mode Output:**

```
  Dog Image Browser - Homepage
    ✓ should display the page title and subtitle (234ms)
    ✓ should display the breed selector and fetch button (123ms)
    ✓ should display placeholder message initially (89ms)
    ✓ should not display dog image initially (45ms)
    ✓ should not display error message initially (38ms)

  5 passing (1s)
```

---

## Testing User Interactions

Now let's test actual user interactions like clicking buttons and selecting breeds.

### Test: Fetching a Random Dog

Create `cypress/e2e/fetch-dog.cy.ts`:

```typescript
describe('Dog Image Browser - Fetch Dog Functionality', () => {
  beforeEach(() => {
    cy.visit('/');
  });

  it('should fetch and display a random dog image when button is clicked', () => {
    // Click the fetch button
    cy.get('[data-testid="fetch-dog-button"]').click();

    // Button should show loading state
    cy.get('[data-testid="fetch-dog-button"]')
      .should('contain.text', 'Loading...')
      .and('be.disabled');

    // Wait for image to load and be visible
    cy.get('[data-testid="dog-image-container"]', { timeout: 10000 })
      .should('be.visible');

    cy.get('[data-testid="dog-image"]')
      .should('be.visible')
      .and('have.attr', 'src')
      .and('include', 'images.dog.ceo');

    // Placeholder should be gone
    cy.get('[data-testid="placeholder-message"]')
      .should('not.exist');

    // Button should return to normal state
    cy.get('[data-testid="fetch-dog-button"]')
      .should('contain.text', 'Get Random Dog')
      .and('not.be.disabled');
  });

  it('should fetch different dog images on multiple clicks', () => {
    // Array to store image URLs
    const imageUrls: string[] = [];

    // Fetch first dog
    cy.get('[data-testid="fetch-dog-button"]').click();
    cy.get('[data-testid="dog-image"]', { timeout: 10000 })
      .should('be.visible')
      .invoke('attr', 'src')
      .then((src) => {
        imageUrls.push(src as string);
      });

    // Fetch second dog
    cy.get('[data-testid="fetch-dog-button"]').click();
    cy.get('[data-testid="dog-image"]', { timeout: 10000 })
      .should('be.visible')
      .invoke('attr', 'src')
      .then((src) => {
        imageUrls.push(src as string);
        // Images should be different (though there's a small chance they're the same)
        // For a more robust test, you'd mock the API
      });
  });

  it('should handle rapid successive clicks gracefully', () => {
    // Click button multiple times quickly
    cy.get('[data-testid="fetch-dog-button"]').click();
    cy.get('[data-testid="fetch-dog-button"]').click();
    cy.get('[data-testid="fetch-dog-button"]').click();

    // Should still display an image eventually
    cy.get('[data-testid="dog-image"]', { timeout: 10000 })
      .should('be.visible');

    // No error should be shown
    cy.get('[data-testid="error-message"]')
      .should('not.exist');
  });
});
```

### Test: Breed Selection

Continue in `cypress/e2e/fetch-dog.cy.ts`:

```typescript
describe('Dog Image Browser - Breed Selection', () => {
  beforeEach(() => {
    cy.visit('/');
    // Wait for breeds to load
    cy.get('[data-testid="breed-selector"] option', { timeout: 10000 })
      .should('have.length.greaterThan', 1);
  });

  it('should load breed options in the dropdown', () => {
    // Check that dropdown has breeds
    cy.get('[data-testid="breed-selector"]')
      .find('option')
      .should('have.length.greaterThan', 1);

    // First option should be "All Breeds (Random)"
    cy.get('[data-testid="breed-selector"] option')
      .first()
      .should('have.text', 'All Breeds (Random)');
  });

  it('should fetch a specific breed when selected', () => {
    // Select a specific breed (e.g., 'husky')
    cy.get('[data-testid="breed-selector"]').select('husky');

    // Verify selection
    cy.get('[data-testid="breed-selector"]')
      .should('have.value', 'husky');

    // Click fetch button
    cy.get('[data-testid="fetch-dog-button"]').click();

    // Wait for image to load
    cy.get('[data-testid="dog-image"]', { timeout: 10000 })
      .should('be.visible')
      .invoke('attr', 'src')
      .should('include', 'husky');
  });

  it('should allow switching between breeds', () => {
    // Select first breed
    cy.get('[data-testid="breed-selector"]').select('corgi');
    cy.get('[data-testid="fetch-dog-button"]').click();
    cy.get('[data-testid="dog-image"]', { timeout: 10000 })
      .should('be.visible')
      .invoke('attr', 'src')
      .should('include', 'corgi');

    // Switch to another breed
    cy.get('[data-testid="breed-selector"]').select('poodle');
    cy.get('[data-testid="fetch-dog-button"]').click();
    cy.get('[data-testid="dog-image"]', { timeout: 10000 })
      .should('be.visible')
      .invoke('attr', 'src')
      .should('include', 'poodle');

    // Switch back to random
    cy.get('[data-testid="breed-selector"]').select('');
    cy.get('[data-testid="fetch-dog-button"]').click();
    cy.get('[data-testid="dog-image"]', { timeout: 10000 })
      .should('be.visible');
  });

  it('should capitalize breed names in the dropdown', () => {
    // Get a few breed options and check capitalization
    cy.get('[data-testid="breed-selector"] option')
      .eq(1) // Skip "All Breeds" option
      .invoke('text')
      .should('match', /^[A-Z]/); // First letter should be uppercase
  });
});
```

---

## Testing API Integration

### Intercepting Network Requests

Cypress allows you to intercept and control network requests. This is crucial for:

- Testing loading states
- Testing error conditions
- Making tests faster and more reliable
- Avoiding rate limits on external APIs

### Test: Mocking API Responses

Create `cypress/e2e/api-mocking.cy.ts`:

```typescript
describe('Dog Image Browser - API Mocking', () => {
  beforeEach(() => {
    cy.visit('/');
  });

  it('should handle successful API response', () => {
    // Intercept the API call and mock response
    cy.intercept('GET', '/api/dogs', {
      statusCode: 200,
      body: {
        message: 'https://images.dog.ceo/breeds/husky/n02110185_1469.jpg',
        status: 'success',
      },
    }).as('getDog');

    // Click button
    cy.get('[data-testid="fetch-dog-button"]').click();

    // Wait for intercepted request
    cy.wait('@getDog');

    // Check that mocked image is displayed
    cy.get('[data-testid="dog-image"]')
      .should('be.visible')
      .and('have.attr', 'src')
      .and('include', 'n02110185_1469.jpg');
  });

  it('should handle API errors gracefully', () => {
    // Mock API failure
    cy.intercept('GET', '/api/dogs', {
      statusCode: 500,
      body: {
        error: 'Internal Server Error',
      },
    }).as('getDogError');

    // Click button
    cy.get('[data-testid="fetch-dog-button"]').click();

    // Wait for failed request
    cy.wait('@getDogError');

    // Error message should be displayed
    cy.get('[data-testid="error-message"]', { timeout: 10000 })
      .should('be.visible')
      .and('contain.text', 'Failed to load dog image');

    // Image should not be displayed
    cy.get('[data-testid="dog-image-container"]')
      .should('not.exist');
  });

  it('should handle network timeout', () => {
    // Mock slow API response (delay)
    cy.intercept('GET', '/api/dogs', {
      delay: 15000, // 15 seconds
      statusCode: 200,
      body: {
        message: 'https://images.dog.ceo/breeds/husky/n02110185_1469.jpg',
        status: 'success',
      },
    }).as('getSlowDog');

    // Click button
    cy.get('[data-testid="fetch-dog-button"]').click();

    // Button should show loading for extended period
    cy.get('[data-testid="fetch-dog-button"]')
      .should('contain.text', 'Loading...')
      .and('be.disabled');
  });

  it('should handle breeds API failure', () => {
    // Intercept breeds API and make it fail
    cy.intercept('GET', '/api/dogs/breeds', {
      statusCode: 500,
      body: {
        error: 'Failed to fetch breeds',
      },
    }).as('getBreedsError');

    // Reload page to trigger breeds fetch
    cy.reload();

    // Wait for failed request
    cy.wait('@getBreedsError');

    // Breed selector should still be visible but might be empty or show error
    cy.get('[data-testid="breed-selector"]')
      .should('be.visible');
  });

  it('should verify request headers', () => {
    cy.intercept('GET', '/api/dogs', (req) => {
      // Verify request has expected properties
      expect(req.url).to.include('/api/dogs');

      req.reply({
        statusCode: 200,
        body: {
          message: 'https://images.dog.ceo/breeds/husky/n02110185_1469.jpg',
          status: 'success',
        },
      });
    }).as('getDog');

    cy.get('[data-testid="fetch-dog-button"]').click();
    cy.wait('@getDog');
  });

  it('should verify breed query parameter is sent correctly', () => {
    // Wait for breeds to load first
    cy.get('[data-testid="breed-selector"] option', { timeout: 10000 })
      .should('have.length.greaterThan', 1);

    // Intercept with query parameter check
    cy.intercept('GET', '/api/dogs?breed=husky', (req) => {
      expect(req.url).to.include('breed=husky');

      req.reply({
        statusCode: 200,
        body: {
          message: ['https://images.dog.ceo/breeds/husky/n02110185_1469.jpg'],
          status: 'success',
        },
      });
    }).as('getHusky');

    // Select husky breed
    cy.get('[data-testid="breed-selector"]').select('husky');
    cy.get('[data-testid="fetch-dog-button"]').click();

    // Verify request was made
    cy.wait('@getHusky');
  });
});
```

### Test: API Response Validation

Create `cypress/e2e/api-validation.cy.ts`:

```typescript
describe('Dog Image Browser - API Response Validation', () => {
  it('should validate breeds API response structure', () => {
    cy.request('/api/dogs/breeds').then((response) => {
      // Check status code
      expect(response.status).to.eq(200);

      // Check response body structure
      expect(response.body).to.have.property('message');
      expect(response.body).to.have.property('status');
      expect(response.body.status).to.eq('success');

      // Check that message is an object with breed names
      expect(response.body.message).to.be.an('object');
      const breeds = Object.keys(response.body.message);
      expect(breeds.length).to.be.greaterThan(0);
    });
  });

  it('should validate random dog API response structure', () => {
    cy.request('/api/dogs').then((response) => {
      expect(response.status).to.eq(200);
      expect(response.body).to.have.property('message');
      expect(response.body).to.have.property('status');
      expect(response.body.status).to.eq('success');

      // Message should be a URL string
      expect(response.body.message).to.be.a('string');
      expect(response.body.message).to.include('https://images.dog.ceo');
    });
  });

  it('should validate specific breed API response', () => {
    cy.request('/api/dogs?breed=husky').then((response) => {
      expect(response.status).to.eq(200);
      expect(response.body.message).to.be.an('array');
      expect(response.body.message[0]).to.include('husky');
    });
  });
});
```

---

## Advanced Cypress Features

### Custom Commands

Custom commands help you write reusable test code. Define them in `cypress/support/commands.ts`:

```typescript
declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Cypress {
    interface Chainable {
      /**
       * Custom command to fetch a dog image
       * @example cy.fetchDog()
       */
      fetchDog(): Chainable<void>;

      /**
       * Custom command to select a breed and fetch dog
       * @param breed - The breed name to select
       * @example cy.selectBreedAndFetch('husky')
       */
      selectBreedAndFetch(breed: string): Chainable<void>;

      /**
       * Custom command to wait for dog image to load
       * @example cy.waitForDogImage()
       */
      waitForDogImage(): Chainable<JQuery<HTMLElement>>;

      /**
       * Custom command to check if error is displayed
       * @example cy.checkError('Failed to load')
       */
      checkError(message: string): Chainable<void>;
    }
  }
}

// Fetch dog image command
Cypress.Commands.add('fetchDog', () => {
  cy.get('[data-testid="fetch-dog-button"]').click();
});

// Select breed and fetch command
Cypress.Commands.add('selectBreedAndFetch', (breed: string) => {
  cy.get('[data-testid="breed-selector"]').select(breed);
  cy.get('[data-testid="fetch-dog-button"]').click();
});

// Wait for dog image to load
Cypress.Commands.add('waitForDogImage', () => {
  return cy.get('[data-testid="dog-image"]', { timeout: 10000 })
    .should('be.visible');
});

// Check error message
Cypress.Commands.add('checkError', (message: string) => {
  cy.get('[data-testid="error-message"]')
    .should('be.visible')
    .and('contain.text', message);
});

export {};
```

### Using Custom Commands

Create `cypress/e2e/custom-commands.cy.ts`:

```typescript
describe('Dog Image Browser - Using Custom Commands', () => {
  beforeEach(() => {
    cy.visit('/');
  });

  it('should fetch dog using custom command', () => {
    cy.fetchDog();
    cy.waitForDogImage();
  });

  it('should select breed and fetch using custom command', () => {
    // Wait for breeds to load
    cy.get('[data-testid="breed-selector"] option', { timeout: 10000 })
      .should('have.length.greaterThan', 1);

    cy.selectBreedAndFetch('husky');
    cy.waitForDogImage()
      .invoke('attr', 'src')
      .should('include', 'husky');
  });

  it('should check error using custom command', () => {
    // Mock API failure
    cy.intercept('GET', '/api/dogs', {
      statusCode: 500,
      body: { error: 'Server Error' },
    }).as('getDogError');

    cy.fetchDog();
    cy.wait('@getDogError');
    cy.checkError('Failed to load dog image');
  });
});
```

### Fixtures for Test Data

Fixtures store test data in JSON files. Create `cypress/fixtures/dog-responses.json`:

```json
{
  "randomDog": {
    "message": "https://images.dog.ceo/breeds/husky/n02110185_1469.jpg",
    "status": "success"
  },
  "breedList": {
    "message": {
      "husky": [],
      "corgi": ["cardigan"],
      "retriever": ["golden", "flatcoated", "curly"],
      "poodle": ["toy", "miniature", "standard"],
      "bulldog": ["boston", "english", "french"]
    },
    "status": "success"
  },
  "specificBreed": {
    "message": [
      "https://images.dog.ceo/breeds/husky/n02110185_1469.jpg",
      "https://images.dog.ceo/breeds/husky/n02110185_1511.jpg"
    ],
    "status": "success"
  },
  "apiError": {
    "error": "Internal Server Error"
  }
}
```

### Using Fixtures in Tests

Create `cypress/e2e/fixtures.cy.ts`:

```typescript
describe('Dog Image Browser - Using Fixtures', () => {
  beforeEach(() => {
    cy.visit('/');
  });

  it('should use fixture data for mocking', () => {
    // Load fixture and use it
    cy.fixture('dog-responses.json').then((data) => {
      cy.intercept('GET', '/api/dogs', {
        statusCode: 200,
        body: data.randomDog,
      }).as('getDog');

      cy.fetchDog();
      cy.wait('@getDog');

      cy.get('[data-testid="dog-image"]')
        .should('have.attr', 'src')
        .and('include', 'n02110185_1469.jpg');
    });
  });

  it('should mock breeds list with fixture', () => {
    cy.fixture('dog-responses.json').then((data) => {
      cy.intercept('GET', '/api/dogs/breeds', {
        statusCode: 200,
        body: data.breedList,
      }).as('getBreeds');

      cy.reload();
      cy.wait('@getBreeds');

      // Check that mocked breeds appear
      cy.get('[data-testid="breed-selector"]')
        .find('option')
        .should('have.length', 6); // 5 breeds + "All Breeds" option
    });
  });
});
```

### Page Objects Pattern

Page Objects encapsulate page elements and actions for better maintainability.

Create `cypress/support/page-objects/DogBrowserPage.ts`:

```typescript
export class DogBrowserPage {
  // Element selectors
  elements = {
    pageTitle: () => cy.get('[data-testid="page-title"]'),
    pageSubtitle: () => cy.get('[data-testid="page-subtitle"]'),
    breedSelector: () => cy.get('[data-testid="breed-selector"]'),
    fetchButton: () => cy.get('[data-testid="fetch-dog-button"]'),
    dogImage: () => cy.get('[data-testid="dog-image"]'),
    dogImageContainer: () => cy.get('[data-testid="dog-image-container"]'),
    errorMessage: () => cy.get('[data-testid="error-message"]'),
    placeholderMessage: () => cy.get('[data-testid="placeholder-message"]'),
  };

  // Actions
  visit() {
    cy.visit('/');
  }

  selectBreed(breed: string) {
    this.elements.breedSelector().select(breed);
  }

  clickFetchButton() {
    this.elements.fetchButton().click();
  }

  waitForDogImage() {
    this.elements.dogImage().should('be.visible', { timeout: 10000 });
  }

  // Assertions
  verifyPageLoaded() {
    this.elements.pageTitle().should('be.visible');
    this.elements.breedSelector().should('be.visible');
    this.elements.fetchButton().should('be.visible');
  }

  verifyDogImageDisplayed() {
    this.elements.dogImageContainer().should('be.visible');
    this.elements.dogImage().should('be.visible');
  }

  verifyErrorDisplayed(message: string) {
    this.elements.errorMessage()
      .should('be.visible')
      .and('contain.text', message);
  }

  verifyLoadingState() {
    this.elements.fetchButton()
      .should('contain.text', 'Loading...')
      .and('be.disabled');
  }

  getDogImageSrc() {
    return this.elements.dogImage().invoke('attr', 'src');
  }
}
```

### Using Page Objects

Create `cypress/e2e/page-objects.cy.ts`:

```typescript
import { DogBrowserPage } from '../support/page-objects/DogBrowserPage';

describe('Dog Image Browser - Using Page Objects', () => {
  const page = new DogBrowserPage();

  beforeEach(() => {
    page.visit();
  });

  it('should verify page loads correctly', () => {
    page.verifyPageLoaded();
  });

  it('should fetch and display dog image', () => {
    page.clickFetchButton();
    page.waitForDogImage();
    page.verifyDogImageDisplayed();
  });

  it('should select breed and fetch', () => {
    // Wait for breeds to load
    page.elements.breedSelector().find('option').should('have.length.greaterThan', 1);

    page.selectBreed('husky');
    page.clickFetchButton();
    page.waitForDogImage();

    page.getDogImageSrc().should('include', 'husky');
  });

  it('should display error message on API failure', () => {
    cy.intercept('GET', '/api/dogs', {
      statusCode: 500,
      body: { error: 'Server Error' },
    }).as('getDogError');

    page.clickFetchButton();
    cy.wait('@getDogError');
    page.verifyErrorDisplayed('Failed to load dog image');
  });
});
```

---

## Best Practices

### 1. Use data-testid Attributes

Always use `data-testid` for element selection:

**❌ Bad:**
```typescript
cy.get('.btn-primary').click();  // Fragile, breaks when CSS changes
cy.get('button').eq(2).click();  // Position-based, breaks when layout changes
cy.contains('Submit').click();   // Text-based, breaks with i18n
```

**✅ Good:**
```typescript
cy.get('[data-testid="submit-button"]').click();  // Reliable
```

### 2. Don't Use Arbitrary Waits

**❌ Bad:**
```typescript
cy.wait(3000);  // Slow and unreliable
cy.get('[data-testid="result"]');
```

**✅ Good:**
```typescript
cy.get('[data-testid="result"]', { timeout: 10000 })
  .should('be.visible');  // Waits automatically
```

### 3. Keep Tests Independent

Each test should be able to run independently:

**❌ Bad:**
```typescript
describe('Tests', () => {
  let userId: string;

  it('should create user', () => {
    // Creates user, stores ID
    userId = 'user123';
  });

  it('should update user', () => {
    // Depends on previous test
    cy.updateUser(userId);
  });
});
```

**✅ Good:**
```typescript
describe('Tests', () => {
  beforeEach(() => {
    // Each test creates its own user
    cy.createUser().as('userId');
  });

  it('should update user', () => {
    cy.get('@userId').then((id) => {
      cy.updateUser(id);
    });
  });
});
```

### 4. Use Aliases for Repeated Selectors

**❌ Bad:**
```typescript
cy.get('[data-testid="complex-selector"]').click();
cy.get('[data-testid="complex-selector"]').should('have.class', 'active');
cy.get('[data-testid="complex-selector"]').invoke('text');
```

**✅ Good:**
```typescript
cy.get('[data-testid="complex-selector"]').as('myElement');
cy.get('@myElement').click();
cy.get('@myElement').should('have.class', 'active');
cy.get('@myElement').invoke('text');
```

### 5. Test User Journeys, Not Implementation

Focus on what users do, not how the code works:

**❌ Bad:**
```typescript
it('should call fetchDog function', () => {
  // Testing implementation details
});
```

**✅ Good:**
```typescript
it('should display dog image when user clicks fetch button', () => {
  // Testing user behavior
});
```

### 6. Use beforeEach for Common Setup

**❌ Bad:**
```typescript
it('test 1', () => {
  cy.visit('/');
  cy.login();
  // test code
});

it('test 2', () => {
  cy.visit('/');
  cy.login();
  // test code
});
```

**✅ Good:**
```typescript
beforeEach(() => {
  cy.visit('/');
  cy.login();
});

it('test 1', () => {
  // test code
});

it('test 2', () => {
  // test code
});
```

### 7. Name Tests Clearly

**❌ Bad:**
```typescript
it('works', () => {});
it('test 1', () => {});
```

**✅ Good:**
```typescript
it('should display error message when API fails', () => {});
it('should allow user to select breed from dropdown', () => {});
```

### 8. Don't Test External APIs Directly

Always test through your application:

**❌ Bad:**
```typescript
cy.request('https://dog.ceo/api/breeds/list/all');  // Testing external API
```

**✅ Good:**
```typescript
cy.request('/api/dogs/breeds');  // Testing your API wrapper
```

### 9. Clean Up Test Data

**✅ Good:**
```typescript
afterEach(() => {
  // Clean up any test data created
  cy.task('cleanupTestData');
});
```

### 10. Use TypeScript

TypeScript provides type safety and better IDE support:

```typescript
// cypress/e2e/example.cy.ts
describe('My Test', () => {
  it('should work', () => {
    cy.get('[data-testid="button"]')
      .should('be.visible')  // Autocomplete works!
      .and('not.be.disabled');
  });
});
```

---

## Hands-on Exercises

### Exercise 1: Test Image Loading

**Goal:** Verify that images load correctly.

**Steps:**

1. Create `cypress/e2e/exercise1-image-loading.cy.ts`
2. Write tests to:
   - Verify image has correct `src` attribute
   - Verify image loads successfully (not broken)
   - Verify image is visible in viewport

**Hints:**
```typescript
// Check if image loaded successfully
cy.get('[data-testid="dog-image"]')
  .should('be.visible')
  .and(($img) => {
    expect($img[0].naturalWidth).to.be.greaterThan(0);
  });
```

---

### Exercise 2: Test Keyboard Navigation

**Goal:** Ensure keyboard users can use the application.

**Steps:**

1. Create `cypress/e2e/exercise2-keyboard-nav.cy.ts`
2. Write tests to:
   - Tab through elements in correct order
   - Use Enter key to click button
   - Use arrow keys in dropdown

**Hints:**
```typescript
cy.get('[data-testid="breed-selector"]')
  .focus()
  .type('{downarrow}{enter}');
```

---

### Exercise 3: Test Responsive Design

**Goal:** Verify the app works on different screen sizes.

**Steps:**

1. Create `cypress/e2e/exercise3-responsive.cy.ts`
2. Write tests for:
   - Mobile viewport (375x667)
   - Tablet viewport (768x1024)
   - Desktop viewport (1920x1080)

**Hints:**
```typescript
cy.viewport(375, 667);  // Mobile
cy.get('[data-testid="breed-selector"]').should('be.visible');
```

---

### Exercise 4: Test Error Recovery

**Goal:** Verify users can recover from errors.

**Steps:**

1. Create `cypress/e2e/exercise4-error-recovery.cy.ts`
2. Test scenarios:
   - API fails, user clicks button again → Success
   - Error appears, user selects different breed → Error clears

---

### Exercise 5: Accessibility Testing

**Goal:** Ensure the app is accessible.

**Steps:**

1. Install cypress-axe:
   ```bash
   pnpm add -D cypress-axe axe-core
   ```

2. Configure in `cypress/support/e2e.ts`:
   ```typescript
   import 'cypress-axe';
   ```

3. Create `cypress/e2e/exercise5-accessibility.cy.ts`:
   ```typescript
   describe('Accessibility Tests', () => {
     beforeEach(() => {
       cy.visit('/');
       cy.injectAxe();
     });

     it('should have no detectable accessibility violations', () => {
       cy.checkA11y();
     });

     it('should have proper focus indicators', () => {
       cy.get('[data-testid="fetch-dog-button"]')
         .focus()
         .should('have.focus');
     });
   });
   ```

---

## Troubleshooting

### Issue 1: Tests Timing Out

**Symptom:**
```
CypressError: Timed out retrying after 4000ms
```

**Solutions:**

1. **Increase timeout:**
   ```typescript
   cy.get('[data-testid="element"]', { timeout: 10000 });
   ```

2. **Check if element actually appears:**
   - Use Cypress Test Runner to inspect DOM
   - Check console for JavaScript errors

3. **Wait for API response:**
   ```typescript
   cy.intercept('GET', '/api/dogs').as('getDog');
   cy.get('[data-testid="fetch-dog-button"]').click();
   cy.wait('@getDog');
   ```

---

### Issue 2: Element Not Visible

**Symptom:**
```
CypressError: element is not visible
```

**Solutions:**

1. **Use force option (use sparingly):**
   ```typescript
   cy.get('[data-testid="button"]').click({ force: true });
   ```

2. **Scroll element into view:**
   ```typescript
   cy.get('[data-testid="element"]').scrollIntoView().should('be.visible');
   ```

3. **Wait for animations to complete:**
   ```typescript
   cy.get('[data-testid="element"]').should('be.visible');
   cy.wait(300);  // Wait for animation
   ```

---

### Issue 3: "Cannot read property 'click' of undefined"

**Symptom:**
```
TypeError: Cannot read property 'click' of undefined
```

**Solutions:**

1. **Verify selector is correct:**
   ```typescript
   cy.get('[data-testid="button"]')  // Check spelling!
     .should('exist')  // Debug: element exists?
     .click();
   ```

2. **Use Cypress Selector Playground:**
   - Open Cypress Test Runner
   - Click crosshair icon
   - Click on element
   - Copy suggested selector

---

### Issue 4: Flaky Tests

**Symptom:**
Tests pass sometimes, fail other times.

**Solutions:**

1. **Don't rely on specific content from external APIs:**
   ```typescript
   // ❌ Flaky
   cy.get('[data-testid="dog-image"]')
     .should('have.attr', 'src', 'specific-url');

   // ✅ Stable
   cy.get('[data-testid="dog-image"]')
     .should('have.attr', 'src')
     .and('include', 'images.dog.ceo');
   ```

2. **Use cy.intercept for consistent data:**
   ```typescript
   cy.intercept('GET', '/api/dogs', {
     fixture: 'dog-responses.json'
   });
   ```

3. **Disable animations in tests:**
   ```typescript
   // cypress/support/e2e.ts
   Cypress.on('window:before:load', (win) => {
     win.document.body.style.transition = 'none';
     win.document.body.style.animation = 'none';
   });
   ```

---

### Issue 5: "Failed to Fetch"

**Symptom:**
```
Failed to fetch
```

**Causes & Solutions:**

1. **Dev server not running:**
   ```bash
   # Make sure this is running
   pnpm dev
   ```

2. **Wrong baseUrl:**
   ```typescript
   // cypress.config.ts
   baseUrl: 'http://localhost:3000',  // Check port!
   ```

3. **CORS issues:**
   - Cypress runs tests from a different origin
   - Make sure your API allows localhost

---

## Submission Requirements

### Part 1: Implementation

Complete the Dog Image Browser application with comprehensive Cypress tests.

**Required Test Files:**

1. `cypress/e2e/homepage.cy.ts` - Homepage display tests
2. `cypress/e2e/fetch-dog.cy.ts` - Dog fetching functionality
3. `cypress/e2e/api-mocking.cy.ts` - API mocking tests
4. `cypress/e2e/accessibility.cy.ts` - Accessibility tests
5. `cypress/e2e/user-journey.cy.ts` - Complete user journey tests

**Additional Requirements:**

- All tests must use `data-testid` attributes
- Include at least 3 custom commands
- Create 1 Page Object
- Use fixtures for test data
- Tests must pass in both interactive and headless mode

**Verification:**

```bash
# All tests should pass
pnpm test:e2e

# Linting should pass
pnpm lint

# Build should succeed
pnpm build
```

---

### Part 2: Test Coverage Report

Submit a comprehensive testing report.

**Required Sections:**

#### 1. Test Results Screenshots

Include screenshots showing:

1. **Cypress Test Runner** - All tests passing (interactive mode)
2. **Terminal Output** - Headless test run results
3. **Failure Screenshot** - Intentionally fail a test to show failure capture

---

#### 2. Test Coverage Summary

Document your test coverage:

**Test Categories:**

| Category | Test Count | Status |
|----------|-----------|--------|
| UI Display | X tests | ✅ Pass |
| User Interactions | X tests | ✅ Pass |
| API Integration | X tests | ✅ Pass |
| Error Handling | X tests | ✅ Pass |
| Accessibility | X tests | ✅ Pass |
| **Total** | **X tests** | **✅ Pass** |

**Test Execution Time:**
- Interactive mode: X seconds
- Headless mode: X seconds

---

#### 3. Test Scenarios Covered

List all test scenarios with descriptions:

**Example:**

1. **Homepage Display**
   - ✅ Page title and subtitle display correctly
   - ✅ Breed selector is visible and populated
   - ✅ Fetch button is enabled and clickable
   - ✅ Placeholder message appears initially

2. **Dog Fetching**
   - ✅ Random dog image loads on button click
   - ✅ Loading state displays during fetch
   - ✅ Multiple fetches load different images
   - ✅ Rapid clicks handled gracefully

3. **Breed Selection**
   - ✅ Breeds populate from API
   - ✅ Selecting breed filters results
   - ✅ Switching breeds works correctly
   - ✅ Breed names are capitalized

... (continue for all scenarios)

---

#### 4. Custom Commands Documentation

Document your custom commands:

```typescript
/**
 * Custom Commands Created:
 *
 * 1. cy.fetchDog()
 *    - Clicks the fetch dog button
 *    - Usage: cy.fetchDog()
 *
 * 2. cy.selectBreedAndFetch(breed)
 *    - Selects a breed and fetches dog image
 *    - Parameters: breed (string)
 *    - Usage: cy.selectBreedAndFetch('husky')
 *
 * 3. cy.waitForDogImage()
 *    - Waits for dog image to load
 *    - Usage: cy.waitForDogImage()
 */
```

---

### Part 3: User Journey Test

Create a comprehensive user journey test in `cypress/e2e/user-journey.cy.ts`:

**Required User Journey:**

```typescript
describe('Complete User Journey', () => {
  it('should complete a full user workflow', () => {
    // 1. User visits homepage
    // 2. User sees welcome message
    // 3. User browses available breeds
    // 4. User selects a specific breed
    // 5. User fetches dog image
    // 6. User views the image
    // 7. User selects different breed
    // 8. User fetches another image
    // 9. User selects "All Breeds"
    // 10. User fetches random dog
  });
});
```

---

### Submission Format

**Structure:**
```
practical8_[StudentID]/
├── gui-testing/              # Full Next.js app
│   ├── src/
│   ├── cypress/
│   │   ├── e2e/             # All test files
│   │   ├── fixtures/        # Test data
│   │   ├── support/         # Custom commands & page objects
│   │   └── videos/          # Test videos
│   ├── package.json
│   └── cypress.config.ts
├── REPORT.md                 # Testing report
└── screenshots/
    ├── test-runner-passing.png
    ├── headless-results.png
    ├── test-failure.png
    └── test-video.mp4(if applicable)
```

---

## Conclusion

Congratulations! You've learned comprehensive GUI testing with Cypress:

✅ Installed and configured Cypress for Next.js
✅ Written tests for UI, interactions, and APIs
✅ Mocked API responses for reliable testing
✅ Created custom commands and page objects
✅ Learned Cypress best practices
✅ Debugged common issues

### Next Steps

To further your GUI testing knowledge:

1. **Explore Cypress Cloud** - Run tests in parallel, review results
2. **Learn Component Testing** - Test React components in isolation
3. **CI/CD Integration** - Automate tests in GitHub Actions
4. **Advanced Patterns** - Study complex test scenarios
5. **Continuous Practice** - Test every feature you build

### Resources

- **Cypress Documentation**: https://docs.cypress.io
- **Cypress Examples**: https://github.com/cypress-io/cypress-example-recipes
- **Cypress Best Practices**: https://docs.cypress.io/guides/references/best-practices
- **Cypress Discord**: https://discord.gg/cypress
- **Testing Library**: https://testing-library.com/docs/cypress-testing-library/intro

### Key Takeaways

1. **GUI testing ensures user experience** - Test what users see and do
2. **Cypress makes testing enjoyable** - Fast, reliable, and developer-friendly
3. **Test user journeys, not implementation** - Focus on behavior
4. **Mock external dependencies** - Make tests fast and reliable
5. **Maintain tests like production code** - Use best practices

Happy testing! 🧪🚀
