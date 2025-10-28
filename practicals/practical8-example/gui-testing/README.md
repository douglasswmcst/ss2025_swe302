# Dog Image Browser - GUI Testing with Cypress

This is a [Next.js](https://nextjs.org) application for **Practical 8: GUI Testing with Cypress**. It demonstrates comprehensive end-to-end testing of a web application using Cypress.

## About This Application

The Dog Image Browser is a simple web application that:
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
├── e2e/                      # Test files
│   ├── homepage.cy.ts        # Homepage display tests
│   ├── fetch-dog.cy.ts       # Dog fetching functionality tests
│   ├── api-mocking.cy.ts     # API mocking and error handling tests
│   └── user-journey.cy.ts    # Complete user workflow tests
├── fixtures/                 # Test data files
│   └── dog-responses.json    # Mock API responses
└── support/                  # Custom commands and configuration
    ├── commands.ts           # Custom Cypress commands
    ├── e2e.ts               # Global configuration
    └── page-objects/        # Page Object Models
        └── DogBrowserPage.ts
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

## License

This project is for educational purposes as part of the SWE302 course.
