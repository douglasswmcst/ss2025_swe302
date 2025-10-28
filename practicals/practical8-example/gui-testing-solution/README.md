# Dog Image Browser - GUI Testing Solution (Reference Implementation)

This is the **complete reference solution** for **Practical 8: GUI Testing with Cypress**. Students should use the `gui-testing` folder for their walkthrough and refer to this solution only when stuck or for verification.

## About This Solution

This folder contains the completed version of the practical with:
- ✅ Full Cypress configuration
- ✅ Comprehensive test suite with 8 test files (31 tests total)
- ✅ Custom commands for reusable test code
- ✅ Page Object pattern implementation
- ✅ Test fixtures for consistent data
- ✅ Complete user journey tests

The Dog Image Browser application:
- Fetches random dog images from the Dog CEO API
- Allows users to filter by breed
- Displays dog images in a responsive UI
- Includes comprehensive test coverage using Cypress

## Getting Started

### Prerequisites

- Node.js (v18 or later)
- pnpm (recommended) or npm

### Installation

1. Install dependencies:

```bash
pnpm install
```

2. Install Cypress (if not already included):

```bash
pnpm add -D cypress start-server-and-test
```

### Running the Application

Start the development server:

```bash
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the application.

## Testing with Cypress

This project includes comprehensive Cypress tests for GUI testing.

### Running Tests

**Interactive Mode (Recommended for Development):**

```bash
# Start dev server and open Cypress Test Runner
pnpm test:e2e:open
```

**Headless Mode (For CI/CD):**

```bash
# Start dev server and run all tests
pnpm test:e2e
```

**Manual Cypress Commands:**

```bash
# Open Cypress Test Runner (server must be running separately)
pnpm cypress:open

# Run tests headlessly (server must be running separately)
pnpm cypress:run
```

### Test Structure

```
cypress/
├── e2e/                          # Test files (31 tests total)
│   ├── homepage.cy.ts            # Homepage display tests (5 tests)
│   ├── fetch-dog.cy.ts           # Fetch & breed selection tests (7 tests)
│   ├── api-mocking.cy.ts         # API mocking tests (6 tests)
│   ├── api-validation.cy.ts      # API validation tests (3 tests)
│   ├── custom-commands.cy.ts     # Custom commands demo (3 tests)
│   ├── fixtures.cy.ts            # Fixtures demo (2 tests)
│   ├── page-objects.cy.ts        # Page Objects demo (4 tests)
│   └── user-journey.cy.ts        # End-to-end journey (1 comprehensive test)
├── fixtures/                     # Test data files
│   └── dog-responses.json        # Mock API responses
└── support/                      # Custom commands and configuration
    ├── commands.ts               # 4 Custom Cypress commands
    ├── e2e.ts                   # Global configuration
    └── page-objects/            # Page Object Models
        └── DogBrowserPage.ts    # Complete Page Object implementation
```

### Available npm Scripts

```json
{
  "dev": "next dev",                    // Start dev server
  "build": "next build",                // Build for production
  "start": "next start",                // Start production server
  "lint": "eslint",                     // Run linting
  "cypress:open": "cypress open",       // Open Cypress Test Runner
  "cypress:run": "cypress run",         // Run tests headlessly
  "test:e2e": "start-server-and-test dev http://localhost:3000 cypress:run",
  "test:e2e:open": "start-server-and-test dev http://localhost:3000 cypress:open"
}
```

## Features Tested

- ✅ Homepage display and layout
- ✅ Breed selector population
- ✅ Random dog image fetching
- ✅ Breed-specific image fetching
- ✅ Loading states
- ✅ Error handling
- ✅ API mocking and network interception
- ✅ User journeys and workflows
- ✅ Accessibility (optional)

## Test Data Attributes

The application uses `data-testid` attributes for reliable element selection in tests:

- `data-testid="page-title"` - Main page title
- `data-testid="page-subtitle"` - Page subtitle
- `data-testid="breed-selector"` - Breed dropdown
- `data-testid="fetch-dog-button"` - Fetch dog button
- `data-testid="dog-image"` - Dog image element
- `data-testid="dog-image-container"` - Image container
- `data-testid="error-message"` - Error message display
- `data-testid="placeholder-message"` - Initial placeholder

## API Endpoints

- `GET /api/dogs` - Fetch random dog image
- `GET /api/dogs?breed={breed}` - Fetch random image of specific breed
- `GET /api/dogs/breeds` - Get list of all breeds

## Technologies Used

- **Next.js 16** - React framework
- **TypeScript** - Type safety
- **Tailwind CSS** - Styling
- **Cypress 13** - E2E testing
- **Dog CEO API** - Dog images data source

## Learn More

### Next.js Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [Learn Next.js](https://nextjs.org/learn)

### Cypress Resources

- [Cypress Documentation](https://docs.cypress.io)
- [Cypress Best Practices](https://docs.cypress.io/guides/references/best-practices)
- [Cypress Examples](https://github.com/cypress-io/cypress-example-recipes)

### Related Practicals

- **Practical 7** - Performance Testing with k6
- **Practical 8** - GUI Testing with Cypress (this practical)

## Troubleshooting

### Tests Timing Out

If tests are timing out, try:
- Increasing the timeout in test commands: `cy.get('[data-testid="element"]', { timeout: 10000 })`
- Checking if the dev server is running
- Verifying network connectivity to external APIs

### Cypress Not Opening

If Cypress won't open:
```bash
# Clear Cypress cache and reinstall
rm -rf node_modules/.cache/cypress
pnpm exec cypress install
```

### Port Already in Use

If port 3000 is already in use:
```bash
# Kill process on port 3000
lsof -ti:3000 | xargs kill -9

# Or use a different port
PORT=3001 pnpm dev
```

## Differences from Starter Code

The `gui-testing-solution` folder has these additional items compared to `gui-testing`:

### Added Files:
- `cypress.config.ts` - Cypress configuration
- `cypress/tsconfig.json` - TypeScript support
- `cypress/support/e2e.ts` - Global test setup
- `cypress/support/commands.ts` - Custom commands
- `cypress/support/page-objects/DogBrowserPage.ts` - Page Object
- `cypress/fixtures/dog-responses.json` - Test fixtures
- All 8 test files in `cypress/e2e/`

### Modified Files:
- `package.json` - Added Cypress scripts and dependencies

### Dependencies Added:
- `cypress` (v15.5.0)
- `start-server-and-test` (v2.1.2)

## For Students

If you're working through Practical 8:

1. **Start with the walkthrough**: Use `practicals/practical8-example/gui-testing/` folder
2. **Follow practical8.md**: Complete guide is in `practicals/practical8.md`
3. **Reference this solution**: Use this folder when you get stuck
4. **Don't copy blindly**: Understand each test and why it works
5. **Experiment**: Modify tests to learn how Cypress works

## License

This project is for educational purposes as part of the SWE302 course.
